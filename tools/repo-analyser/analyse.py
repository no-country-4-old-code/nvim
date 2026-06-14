#!/usr/bin/env python3
"""
repo-analyser — quick structural intelligence on any git repository.

Produces a single self-contained report.html in the output directory.

Usage:
    python analyse.py [REPO_PATH] [options]

Examples:
    python analyse.py .
    python analyse.py ~/projects/myrepo --section authors
    python analyse.py . --output-dir /tmp/report --depth 3 --top 20
"""
from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# Allow running as a script without installing the package
sys.path.insert(0, str(Path(__file__).parent))

from repo_analyser.gitdata import (
    count_loc,
    current_files,
    load_repo,
    scan_history,
)
from repo_analyser.tooling  import analyse_tooling
from repo_analyser.authors  import analyse_authors
from repo_analyser.churn    import analyse_stable, analyse_hot
from repo_analyser.recent   import analyse_recent
from repo_analyser.matrix   import build_file_matrix
from repo_analyser.report   import build_payload
from repo_analyser.html_report import render_html, write_html

SECTIONS = ('all', 'tooling', 'authors', 'stable', 'hot', 'recent')
_TEMPLATE = Path(__file__).parent / 'repo_analyser' / 'template.html'


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Analyse a git repository and produce a self-contained report.html.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        'repo',
        nargs='?',
        default='.',
        help='Path to the git repository (default: current directory)',
    )
    parser.add_argument(
        '--section',
        choices=SECTIONS,
        default='all',
        metavar='{' + ','.join(SECTIONS) + '}',
        help='Which analysis section(s) to run (default: all)',
    )
    parser.add_argument(
        '--output-dir',
        default='repo-analysis',
        metavar='DIR',
        help='Directory to write report.html into (default: ./repo-analysis)',
    )
    parser.add_argument(
        '--depth',
        type=int,
        default=2,
        help='Folder aggregation depth for treemap and folder tables (default: 2)',
    )
    parser.add_argument(
        '--top',
        type=int,
        default=10,
        help='Number of top items to show per list (default: 10)',
    )
    return parser.parse_args()


def _fmt_bool(flag: bool) -> str:
    return 'YES' if flag else 'no'


def _print_summary(
    repo_root: str,
    tooling_data: dict | None,
    authors_data: dict | None,
    stable_data: dict | None,
    hot_data: dict | None,
    recent_data: dict | None,
    html_path: str,
) -> None:
    print(f'\n─── repo-analyser: {repo_root} ───')

    if tooling_data:
        print('\n[1] Tooling & Size')
        print(f"    CI:              {_fmt_bool(tooling_data['ci']['present'])}")
        print(f"    Tests:           {_fmt_bool(tooling_data['tests']['present'])}")
        print(f"    Static analysis: {_fmt_bool(tooling_data['static_analysis']['present'])}")
        print(f"    Formatter:       {_fmt_bool(tooling_data['formatter']['present'])}")
        print(f"    Files:           {tooling_data['file_count']}")
        print(f"    LOC:             {tooling_data['total_loc']:,}")

    if authors_data:
        print('\n[2] Authors')
        authors = authors_data['authors']
        print(f"    Total authors: {len(authors)}")
        for a in authors[:5]:
            print(f"    • {a['name']:<20}  {a['commits']:>4} commits  "
                  f"{a['loc_written']:>7,} LOC written  "
                  f"{a['pct_current_files_touched']:>5}% of current files")
        if len(authors) > 5:
            print(f'    … and {len(authors) - 5} more (see report)')

    if stable_data:
        print('\n[3] Stable files')
        print(f"    {stable_data.get('total_stable_files', 0)} stable files. Top folders:")
        for f in stable_data['stable_folders'][:5]:
            print(f"    • {f['folder']:<30}  {f['stable_files']} files  "
                  f"last changed: {f['oldest_last_change']}")

    if hot_data:
        print('\n[4] Hot files')
        for f in hot_data['hot_files'][:5]:
            print(f"    • {f['file']:<40}  score {f['score']:.0f}  "
                  f"last: {f['last_changed']}")

    if recent_data:
        print('\n[5] Recent (last 5)')
        for f in recent_data['recent_files'][:5]:
            print(f"    • {f['file']:<40}  {f['last_changed']}")

    print(f'\n─── Output ───')
    print(f'    {html_path}')
    print()


def main() -> None:
    args = _parse_args()
    repo_root = os.path.abspath(args.repo)

    print(f'Loading repository: {repo_root}')
    repo = load_repo(repo_root)

    head_sha = repo.head.commit.hexsha
    generated_at = datetime.now(tz=timezone.utc).strftime('%Y-%m-%d %H:%M UTC')

    print('Scanning history (this may take a moment for large repos)…')
    files, authors = scan_history(repo)
    tracked = current_files(repo)

    print(f'  {len(tracked)} tracked files, {len(files)} files in history, '
          f'{len(authors)} authors.')

    _, _, per_file_loc = count_loc(tracked, repo_root)

    # File matrix for the treemap is always built (uses all current files)
    print('Building file matrix…')
    file_matrix = build_file_matrix(files, tracked, per_file_loc, depth=args.depth)

    run_all = args.section == 'all'

    tooling_data = None
    authors_data = None
    stable_data  = None
    hot_data     = None
    recent_data  = None

    if run_all or args.section == 'tooling':
        print('Running section 1: tooling & size…')
        tooling_data = analyse_tooling(tracked, repo_root)

    if run_all or args.section == 'authors':
        print('Running section 2: authors…')
        authors_data = analyse_authors(authors, tracked, top_files=3)

    if run_all or args.section == 'stable':
        print('Running section 3: stable files…')
        stable_data = analyse_stable(
            files, tracked, per_file_loc, top=args.top, depth=args.depth,
        )

    if run_all or args.section == 'hot':
        print('Running section 4: hot files…')
        hot_data = analyse_hot(
            files, tracked, per_file_loc, top=args.top, depth=args.depth,
        )

    if run_all or args.section == 'recent':
        print('Running section 5: recently modified…')
        recent_data = analyse_recent(files, tracked, top=args.top, depth=args.depth)

    meta = {
        'repo_path': repo_root,
        'head_commit': head_sha,
        'generated_at': generated_at,
        'params': {
            'section': args.section,
            'depth': args.depth,
            'top': args.top,
        },
    }

    payload = build_payload(
        meta,
        tooling=tooling_data,
        authors=authors_data,
        stable=stable_data,
        hot=hot_data,
        recent=recent_data,
        file_matrix=file_matrix,
    )

    print('Rendering HTML report…')
    html  = render_html(payload, str(_TEMPLATE))
    hpath = write_html(html, args.output_dir)

    _print_summary(
        repo_root,
        tooling_data, authors_data, stable_data, hot_data, recent_data,
        hpath,
    )


if __name__ == '__main__':
    main()
