"""
Section 2 — Authors.

For every author in history: first/last commit, commit count, LOC written (gross + net),
% of existing files touched, top-3 files by churn.
"""
from __future__ import annotations

from typing import Dict, List, Set

from .gitdata import AuthorRecord, ts_to_date


def analyse_authors(
    authors: Dict[str, AuthorRecord],
    current_files: Set[str],
    top_files: int = 3,
) -> dict:
    """
    Returns a dict with key 'authors' → sorted list of per-author dicts.
    Sorted by insertions desc (LOC written).
    """
    n_current = max(len(current_files), 1)
    rows: List[dict] = []

    for canonical, a in authors.items():
        files_touched_current = a.files & current_files
        pct_touched = len(files_touched_current) / n_current * 100.0

        # top N files by churn (ins+del) for this author
        top = [
            {'file': p, 'churn': churn}
            for p, churn in a.per_file_churn.most_common(top_files)
        ]

        rows.append({
            'author': canonical,
            'name': a.name,
            'email': a.email,
            'commits': a.commits,
            'first_commit': ts_to_date(a.first_ts),
            'last_commit': ts_to_date(a.last_ts),
            'loc_written': a.insertions,
            'loc_net': a.insertions - a.deletions,
            'files_touched': len(a.files),
            'files_touched_current': len(files_touched_current),
            'pct_current_files_touched': round(pct_touched, 1),
            'top_files_by_churn': top,
        })

    rows.sort(key=lambda r: -r['loc_written'])
    return {'authors': rows}
