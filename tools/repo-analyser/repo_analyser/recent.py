"""
Section 5 — Most recently modified files and folders.
"""
from __future__ import annotations

from typing import Dict, List, Set

from .gitdata import FileRecord, aggregate_by_folder, ts_to_date


def analyse_recent(
    files: Dict[str, FileRecord],
    current_files: Set[str],
    top: int = 10,
    depth: int = 2,
) -> dict:
    """
    Top N files and folders by most-recent last-change timestamp.
    """
    candidates = [f for f in files.values() if f.path in current_files]
    candidates.sort(key=lambda f: f.last_ts, reverse=True)

    per_file_rows: List[dict] = []
    folder_input: Dict[str, dict] = {}

    for f in candidates:
        folder_input[f.path] = {'last_ts': f.last_ts, 'commits': f.commits}
        if len(per_file_rows) < top:
            per_file_rows.append({
                'file': f.path,
                'last_changed': ts_to_date(f.last_ts),
                'commits': f.commits,
                'distinct_authors': len(f.authors),
            })

    # Folder: most-recent last_ts within folder (aggregate_by_folder uses max for _last keys)
    raw_folders = aggregate_by_folder(folder_input, depth=depth)
    folder_rows: List[dict] = []
    for folder, agg in raw_folders.items():
        folder_rows.append({
            'folder': folder,
            'files': agg['_files'],
            'last_changed': ts_to_date(agg.get('last_ts', 0)),
            'total_commits': agg.get('commits', 0),
        })
    folder_rows.sort(
        key=lambda r: next(
            (f['last_ts'] for f in [folder_input.get(k) for k in folder_input
                                     if k.startswith(r['folder'])]
             if f), 0),
        reverse=True,
    )
    # Simpler sort: re-derive max ts per folder
    folder_ts: Dict[str, int] = {}
    for path, metrics in folder_input.items():
        from .gitdata import _folder_prefix
        fld = _folder_prefix(path, depth)
        folder_ts[fld] = max(folder_ts.get(fld, 0), metrics['last_ts'])

    folder_rows.sort(key=lambda r: folder_ts.get(r['folder'], 0), reverse=True)

    return {
        'recent_files': per_file_rows[:top],
        'recent_folders': folder_rows[:top],
    }
