"""
Shared data layer: one-pass git history parse into FileRecord / AuthorRecord caches.
All other sections consume these caches — avoids repeated git log calls.
"""
from __future__ import annotations

import os
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Set

try:
    import git as gitpython
except ImportError:  # pragma: no cover
    sys.exit("GitPython is not installed. Run: pip install GitPython")


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

@dataclass
class FileRecord:
    path: str
    commits: int = 0
    insertions: int = 0
    deletions: int = 0
    authors: Set[str] = field(default_factory=set)   # canonical "Name <email>"
    first_ts: int = 0   # unix timestamp of earliest commit touching this file
    last_ts: int = 0    # unix timestamp of most-recent commit
    # Up to 3 most-recent (ts, subject) pairs, newest-first (git log order)
    recent_commits: list = field(default_factory=list)


@dataclass
class AuthorRecord:
    canonical: str          # "Name <email>"
    name: str
    email: str
    commits: int = 0
    insertions: int = 0
    deletions: int = 0
    files: Set[str] = field(default_factory=set)           # all paths ever touched
    per_file_churn: Counter = field(default_factory=Counter)  # path → ins+del
    first_ts: int = 0
    last_ts: int = 0


# ---------------------------------------------------------------------------
# Repo loader
# ---------------------------------------------------------------------------

def load_repo(path: str) -> gitpython.Repo:
    """Open a git repo at *path*, exit with a clear message on failure."""
    try:
        repo = gitpython.Repo(path, search_parent_directories=True)
    except gitpython.InvalidGitRepositoryError:
        sys.exit(f"Not a git repository: {path}")
    except gitpython.NoSuchPathError:
        sys.exit(f"Path does not exist: {path}")
    try:
        # fail fast if there are no commits
        repo.head.commit
    except Exception:
        sys.exit(f"Repository has no commits: {path}")
    return repo


# ---------------------------------------------------------------------------
# Rename helpers
# ---------------------------------------------------------------------------

# Patterns emitted by --numstat -M for renamed files:
#  "old.txt => new.txt"          (full rename)
#  "some/{old => new}/path.txt"  (partial rename)
_RENAME_FULL = re.compile(r'^(.+) => (.+)$')
_RENAME_PARTIAL = re.compile(r'^(.*)\{(.+) => (.+)\}(.*)$')


def _resolve_rename(path: str) -> str:
    """Return the *new* path from a numstat rename annotation."""
    m = _RENAME_PARTIAL.match(path)
    if m:
        prefix, _old_mid, new_mid, suffix = m.groups()
        return prefix + new_mid + suffix
    m = _RENAME_FULL.match(path)
    if m:
        return m.group(2)
    return path


# ---------------------------------------------------------------------------
# One-pass history scan
# ---------------------------------------------------------------------------

# Separator between commit header and file list.
_COMMIT_SEP = '\x01'

def scan_history(
    repo: gitpython.Repo,
) -> tuple[Dict[str, FileRecord], Dict[str, AuthorRecord]]:
    """
    Walk the entire non-merge commit history in one git log call.

    Returns
    -------
    files   : path → FileRecord   (best-effort rename tracking via -M)
    authors : "Name <email>" → AuthorRecord   (.mailmap honoured via %aN/%aE)
    """
    # Format: \x01<hash>\t<name>\t<email>\t<timestamp>\t<subject>
    # followed by blank line then numstat lines, then next \x01 header.
    # maxsplit=4 on the header so a subject containing tabs stays intact.
    log_output: str = repo.git.log(
        '--no-merges',
        '--numstat',
        '-M',
        '--diff-filter=ACDMRT',   # skip untracked/broken
        '--format=%x01%H\t%aN\t%aE\t%at\t%s',
        '--',
    )

    files: Dict[str, FileRecord] = {}
    authors: Dict[str, AuthorRecord] = {}

    cur_author: str = ''
    cur_ts: int = 0
    cur_subject: str = ''

    for line in log_output.splitlines():
        if line.startswith(_COMMIT_SEP):
            # --- commit header ---
            parts = line[1:].split('\t', 4)   # maxsplit=4 keeps subject intact
            if len(parts) < 4:
                continue
            _hash, name, email, ts_str = parts[0], parts[1], parts[2], parts[3]
            cur_subject = parts[4] if len(parts) > 4 else ''
            cur_ts = int(ts_str)
            cur_author = f'{name} <{email}>'
            if cur_author not in authors:
                authors[cur_author] = AuthorRecord(
                    canonical=cur_author, name=name, email=email
                )
            a = authors[cur_author]
            a.commits += 1
            if a.first_ts == 0 or cur_ts < a.first_ts:
                a.first_ts = cur_ts
            if cur_ts > a.last_ts:
                a.last_ts = cur_ts
            continue

        if not cur_author:
            continue

        parts = line.split('\t')
        if len(parts) < 3:
            continue   # blank line or malformed

        ins_str, del_str, path_raw = parts[0], parts[1], '\t'.join(parts[2:])

        # Skip binary diffs ('-' for ins/del)
        if ins_str == '-' or del_str == '-':
            continue

        try:
            ins = int(ins_str)
            dels = int(del_str)
        except ValueError:
            continue

        path = _resolve_rename(path_raw.strip())

        # --- FileRecord ---
        if path not in files:
            files[path] = FileRecord(path=path)
        f = files[path]
        f.commits += 1
        f.insertions += ins
        f.deletions += dels
        f.authors.add(cur_author)
        if f.first_ts == 0 or cur_ts < f.first_ts:
            f.first_ts = cur_ts
        if cur_ts > f.last_ts:
            f.last_ts = cur_ts
        # git log is newest-first, so the first 3 times we see a file are its
        # most recent commits — append until we have 3
        if len(f.recent_commits) < 3:
            f.recent_commits.append((cur_ts, cur_subject))

        # --- AuthorRecord ---
        a = authors[cur_author]
        a.insertions += ins
        a.deletions += dels
        a.files.add(path)
        a.per_file_churn[path] += ins + dels

    return files, authors


# ---------------------------------------------------------------------------
# Current tracked files
# ---------------------------------------------------------------------------

def current_files(repo: gitpython.Repo) -> Set[str]:
    """Return the set of paths currently tracked by git (from `git ls-files`)."""
    raw = repo.git.ls_files()
    return set(raw.splitlines()) if raw else set()


# ---------------------------------------------------------------------------
# LOC counting
# ---------------------------------------------------------------------------

_EXT_LANG: Dict[str, str] = {
    '.py': 'Python', '.pyi': 'Python',
    '.js': 'JavaScript', '.mjs': 'JavaScript', '.cjs': 'JavaScript',
    '.ts': 'TypeScript', '.tsx': 'TypeScript',
    '.jsx': 'JavaScript',
    '.lua': 'Lua',
    '.rs': 'Rust',
    '.go': 'Go',
    '.c': 'C', '.h': 'C',
    '.cpp': 'C++', '.cc': 'C++', '.cxx': 'C++', '.hpp': 'C++',
    '.java': 'Java',
    '.kt': 'Kotlin',
    '.rb': 'Ruby',
    '.php': 'PHP',
    '.sh': 'Shell', '.bash': 'Shell', '.zsh': 'Shell',
    '.html': 'HTML', '.htm': 'HTML',
    '.css': 'CSS', '.scss': 'CSS', '.sass': 'CSS',
    '.json': 'JSON',
    '.yaml': 'YAML', '.yml': 'YAML',
    '.toml': 'TOML',
    '.md': 'Markdown',
    '.vim': 'Vimscript',
    '.tf': 'Terraform',
    '.sql': 'SQL',
    '.ex': 'Elixir', '.exs': 'Elixir',
    '.cs': 'C#',
    '.swift': 'Swift',
}


def _is_binary(path: Path, sample: int = 8192) -> bool:
    try:
        with open(path, 'rb') as fh:
            return b'\x00' in fh.read(sample)
    except OSError:
        return True


def count_loc(
    tracked: Set[str],
    repo_root: str,
) -> tuple[int, Dict[str, int], Dict[str, int]]:
    """
    Count lines of code for all tracked, non-binary files that exist on disk.

    Returns
    -------
    total      : total LOC across all files
    by_lang    : language → LOC
    per_file   : path → LOC
    """
    root = Path(repo_root)
    total = 0
    by_lang: Dict[str, int] = defaultdict(int)
    per_file: Dict[str, int] = {}

    for rel in tracked:
        abs_path = root / rel
        if not abs_path.is_file():
            continue
        if _is_binary(abs_path):
            continue
        try:
            lines = abs_path.read_text(errors='replace').count('\n')
        except OSError:
            continue
        total += lines
        per_file[rel] = lines
        ext = Path(rel).suffix.lower()
        lang = _EXT_LANG.get(ext, 'Other')
        by_lang[lang] += lines

    return total, dict(by_lang), per_file


# ---------------------------------------------------------------------------
# Folder aggregation
# ---------------------------------------------------------------------------

def _folder_prefix(path: str, depth: int) -> str:
    """Return the first *depth* components of *path* joined with '/'."""
    parts = path.replace('\\', '/').split('/')
    if len(parts) <= depth:
        return path
    return '/'.join(parts[:depth])


def aggregate_by_folder(
    file_metric_map: Dict[str, dict],
    depth: int = 2,
) -> Dict[str, dict]:
    """
    Aggregate a per-file metric dict into per-folder totals.

    *file_metric_map* maps path → dict of numeric fields.
    Numeric values are summed; set values are unioned; non-numeric scalars
    (timestamps) use min/max semantics when the key ends with '_first'/'_last'.
    """
    folders: Dict[str, dict] = {}

    for path, metrics in file_metric_map.items():
        folder = _folder_prefix(path, depth)
        if folder not in folders:
            folders[folder] = {'_files': 0}
        agg = folders[folder]
        agg['_files'] += 1

        for k, v in metrics.items():
            if isinstance(v, set):
                agg.setdefault(k, set())
                agg[k] |= v
            elif isinstance(v, (int, float)):
                # "first"-flavoured keys → keep minimum (earliest timestamp)
                if k.endswith('_first') or k.startswith('first_'):
                    if k not in agg or (v != 0 and (agg[k] == 0 or v < agg[k])):
                        agg[k] = v
                # "last"-flavoured keys → keep maximum (most-recent timestamp)
                elif k.endswith('_last') or k.startswith('last_'):
                    if k not in agg or v > agg.get(k, 0):
                        agg[k] = v
                else:
                    agg[k] = agg.get(k, 0) + v

    return folders


# ---------------------------------------------------------------------------
# Convenience helpers
# ---------------------------------------------------------------------------

def ts_to_date(ts: int) -> str:
    """Unix timestamp → ISO-8601 date string (UTC)."""
    if ts == 0:
        return 'N/A'
    return datetime.fromtimestamp(ts, tz=timezone.utc).strftime('%Y-%m-%d')


def months_between(first_ts: int, last_ts: int) -> float:
    """Number of months between two timestamps (minimum 1 to avoid /0)."""
    diff_seconds = max(last_ts - first_ts, 0)
    months = diff_seconds / (30.44 * 24 * 3600)
    return max(months, 1.0)
