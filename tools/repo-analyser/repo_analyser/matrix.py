"""
Build the per-file matrix used by the treemap: every currently-tracked file
with churn, LOC, and last-3 commit messages.
"""
from __future__ import annotations

import os
from typing import Dict, List, Set

from .gitdata import FileRecord, _folder_prefix, months_between, ts_to_date


def build_file_matrix(
    files: Dict[str, FileRecord],
    current_files: Set[str],
    per_file_loc: Dict[str, int],
    depth: int = 2,
) -> List[dict]:
    """
    Return a list of dicts — one per currently-tracked file — containing all
    metrics needed for the interactive treemap and tooltip.

    Files with no git history (brand-new untracked edge cases) are included
    with zero churn/commit values so they still appear in the map.
    """
    result: List[dict] = []

    for path in current_files:
        f = files.get(path)
        loc = per_file_loc.get(path, 0)
        folder = _folder_prefix(path, depth)
        name = os.path.basename(path)

        if f is None:
            # File is tracked but not yet in history (initial commit, very new)
            result.append({
                'path': path,
                'name': name,
                'folder': folder,
                'loc': loc,
                'churn': 0,
                'churn_per_month': 0.0,
                'commits': 0,
                'distinct_authors': 0,
                'last_changed': 'N/A',
                'recent_commits': [],
            })
            continue

        churn = f.insertions + f.deletions
        cpm = round(churn / months_between(f.first_ts, f.last_ts), 1)

        recent = [
            {'ts': ts, 'date': ts_to_date(ts), 'subject': subj}
            for ts, subj in f.recent_commits
        ]

        result.append({
            'path': path,
            'name': name,
            'folder': folder,
            'loc': loc,
            'churn': churn,
            'churn_per_month': cpm,
            'commits': f.commits,
            'distinct_authors': len(f.authors),
            'last_changed': ts_to_date(f.last_ts),
            'recent_commits': recent,
        })

    # Sort by churn_per_month desc so high-churn files are squarified first
    result.sort(key=lambda x: (-x['churn_per_month'], -x['loc']))
    return result
