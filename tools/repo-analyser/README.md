# repo-analyser

Quick structural intelligence on any git repository.
Produces a **single self-contained `report.html`** — open it in any browser,
works fully offline (all CSS, JS, and analysis data are embedded inline).

## What's in the report

| # | Section | What it tells you |
|---|---------|-------------------|
| 1 | **Tooling & Size** | CI, unit tests, static analysis, formatter presence; file count + LOC by language |
| 2 | **Authors** | All contributors: first/last commit, commits, LOC written, % of current files touched, top-3 files by churn |
| 3 | **Stable files** | Lowest-churn files — the stable "business logic". Rolled up by folder. |
| 4 | **Hot files** | Score = `commits × distinct authors`; avg churn/month; last change. Rolled up by folder. |
| 5 | **Recently modified** | Top 10 files and folders by last-change date |

## Churn Map (treemap)

Every currently-tracked file is a tile. **Box area ∝ LOC, colour ∝ churn rate** (white → dark blue, sqrt-scaled so the distribution spreads visually). Tiles are grouped by folder.

- **Hover any tile** for a tooltip showing: file path, LOC, churn/month, total churn, commits, authors, last changed, and the last 3 commit messages.
- **Toggle** between Churn/mo, Total churn, and Commits to recolour the map live.

## Requirements

- Python ≥ 3.10
- [GitPython](https://gitpython.readthedocs.io/)

```bash
pip install -r requirements.txt
```

## Usage

```bash
# Analyse the current directory (all sections → ./repo-analysis/report.html)
python analyse.py .

# Just the authors section
python analyse.py /path/to/repo --section authors

# All sections, folder depth 3, top-20 lists, custom output dir
python analyse.py . --depth 3 --top 20 --output-dir /tmp/myreport
```

### CLI options

| Option | Default | Description |
|--------|---------|-------------|
| `REPO_PATH` | `.` | Path to the git repository |
| `--section` | `all` | `all`, `tooling`, `authors`, `stable`, `hot`, `recent` |
| `--output-dir DIR` | `./repo-analysis` | Where to write `report.html` |
| `--depth N` | `2` | Folder aggregation depth (treemap grouping + folder tables) |
| `--top N` | `10` | Number of top items per table list |

## Output

```
repo-analysis/
  report.html    ← single self-contained interactive report
```

## Notes & Limitations

- **Rename tracking** is best-effort (`git log --numstat -M`). Full per-file `--follow` is
  not used because it requires a separate git call per file, prohibitively slow on large repos.
- **Binary files** are excluded from LOC counts.
- **Merge commits** are excluded from all churn metrics.
- **Tooling detection** is heuristic (config-file presence-based). `.mailmap` is honoured.
- LOC is measured by newline count (`wc -l` equivalent), not SLOC.
- For very large repos the embedded `report.html` grows with file count, but remains
  practical for repos up to several thousand files.
