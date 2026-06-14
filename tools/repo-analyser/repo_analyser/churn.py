"""
Section 3 — Stable files (rarely touched, old).
Section 4 — Hot files (high commits × distinct authors, rapid churn/month).

Both sections produce a per-file list and a folder rollup.
"""
from __future__ import annotations

import statistics
from typing import Dict, List, Set

from .gitdata import (
    FileRecord,
    aggregate_by_folder,
    months_between,
    ts_to_date,
)


# ---------------------------------------------------------------------------
# Section 3 — Stable
# ---------------------------------------------------------------------------

def analyse_stable(
    files: Dict[str, FileRecord],
    current_files: Set[str],
    per_file_loc: Dict[str, int],
    top: int = 20,
    depth: int = 2,
) -> dict:
    """
    Stable = files that have barely changed over their lifetime.

    Ranking: last_ts ascending (oldest last touch), then commits ascending.
    A file is 'stable' if its lifetime churn (ins+del) is in the bottom 50th
    percentile for files with more than one commit, OR it has only one commit.
    """
    candidates = [f for f in files.values() if f.path in current_files]
    if not candidates:
        return {'stable_files': [], 'stable_folders': []}

    # Compute lifetime churn for all candidates
    churns = [f.insertions + f.deletions for f in candidates]
    threshold = statistics.median(churns) if churns else 0

    stable = [
        f for f in candidates
        if (f.insertions + f.deletions) <= threshold or f.commits == 1
    ]

    # Sort: oldest last-touch first, then fewest commits
    stable.sort(key=lambda f: (f.last_ts, f.commits))

    per_file_rows: List[dict] = []
    folder_input: Dict[str, dict] = {}

    for f in stable[:top]:
        loc = per_file_loc.get(f.path, 0)
        row = {
            'file': f.path,
            'last_changed': ts_to_date(f.last_ts),
            'last_ts': f.last_ts,
            'commits': f.commits,
            'churn': f.insertions + f.deletions,
            'loc': loc,
        }
        per_file_rows.append(row)
        folder_input[f.path] = {
            'commits': f.commits,
            'churn': f.insertions + f.deletions,
            'loc': loc,
            'last_ts': f.last_ts,
        }

    # Folder rollup over ALL stable files (not just top N)
    all_folder_input: Dict[str, dict] = {}
    for f in stable:
        all_folder_input[f.path] = {
            'commits': f.commits,
            'churn': f.insertions + f.deletions,
            'loc': per_file_loc.get(f.path, 0),
            'last_ts': f.last_ts,
        }

    raw_folders = aggregate_by_folder(all_folder_input, depth=depth)
    folder_rows: List[dict] = []
    for folder, agg in raw_folders.items():
        folder_rows.append({
            'folder': folder,
            'stable_files': agg['_files'],
            'total_loc': agg.get('loc', 0),
            'oldest_last_change': ts_to_date(agg.get('last_ts', 0)),
            'total_churn': agg.get('churn', 0),
        })
    folder_rows.sort(key=lambda r: r['stable_files'], reverse=True)

    return {
        'stable_files': per_file_rows,
        'stable_folders': folder_rows,
        'total_stable_files': len(stable),
    }


# ---------------------------------------------------------------------------
# Section 4 — Hot
# ---------------------------------------------------------------------------

def analyse_hot(
    files: Dict[str, FileRecord],
    current_files: Set[str],
    per_file_loc: Dict[str, int],
    top: int = 20,
    depth: int = 2,
) -> dict:
    """
    Hot score = commits × distinct_authors.
    Also reports avg_churn_per_month and last_change.
    """
    candidates = [f for f in files.values() if f.path in current_files]
    if not candidates:
        return {'hot_files': [], 'hot_folders': []}

    def _score(f: FileRecord) -> float:
        return f.commits * len(f.authors)

    def _churn_per_month(f: FileRecord) -> float:
        months = months_between(f.first_ts, f.last_ts)
        return (f.insertions + f.deletions) / months

    # Sort by score desc, then churn/month desc as tiebreaker
    hot_sorted = sorted(candidates, key=lambda f: (_score(f), _churn_per_month(f)), reverse=True)

    per_file_rows: List[dict] = []
    folder_input_all: Dict[str, dict] = {}

    for f in hot_sorted:
        score = _score(f)
        cpm = round(_churn_per_month(f), 1)
        loc = per_file_loc.get(f.path, 0)
        folder_input_all[f.path] = {
            'score': score,
            'churn': f.insertions + f.deletions,
            'commits': f.commits,
            'loc': loc,
            'last_ts': f.last_ts,
            'authors': f.authors,
        }
        if len(per_file_rows) < top:
            per_file_rows.append({
                'file': f.path,
                'score': score,
                'commits': f.commits,
                'distinct_authors': len(f.authors),
                'avg_churn_per_month': cpm,
                'last_changed': ts_to_date(f.last_ts),
                'loc': loc,
            })

    raw_folders = aggregate_by_folder(folder_input_all, depth=depth)
    folder_rows: List[dict] = []
    for folder, agg in raw_folders.items():
        distinct = len(agg.get('authors', set()))
        folder_rows.append({
            'folder': folder,
            'files': agg['_files'],
            'total_score': agg.get('score', 0),
            'total_commits': agg.get('commits', 0),
            'distinct_authors': distinct,
            'total_churn': agg.get('churn', 0),
            'last_changed': ts_to_date(agg.get('last_ts', 0)),
        })
    folder_rows.sort(key=lambda r: r['total_score'], reverse=True)

    return {
        'hot_files': per_file_rows,
        'hot_folders': folder_rows,
    }
