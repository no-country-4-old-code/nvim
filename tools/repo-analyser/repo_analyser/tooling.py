"""
Section 1 — Tooling & size.

Heuristic presence detection for CI, unit tests, static analysis, and formatters.
Also reports file count and LOC by language.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List, Set

from .gitdata import count_loc


# ---------------------------------------------------------------------------
# Detection helpers
# ---------------------------------------------------------------------------

def _any_exists(root: Path, globs: List[str]) -> list[str]:
    """Return the matching paths (relative) for the first glob that hits."""
    matches = []
    for pattern in globs:
        for p in root.glob(pattern):
            matches.append(str(p.relative_to(root)))
        if matches:
            return matches
    return []


def _file_contains(path: Path, snippets: List[str]) -> bool:
    try:
        text = path.read_text(errors='replace')
        return any(s in text for s in snippets)
    except OSError:
        return False


# ---------------------------------------------------------------------------
# Detection rules
# ---------------------------------------------------------------------------

_CI_GLOBS = [
    '.github/workflows/*.yml',
    '.github/workflows/*.yaml',
    '.gitlab-ci.yml',
    '.circleci/config.yml',
    'azure-pipelines.yml',
    'Jenkinsfile',
    '.travis.yml',
    '.drone.yml',
    'bitbucket-pipelines.yml',
]

_TEST_GLOBS = [
    'tests/**/*.py',
    'test/**/*.py',
    'spec/**/*.rb',
    '**/*_test.go',
    '**/*.test.js',
    '**/*.test.ts',
    '**/*.test.jsx',
    '**/*.test.tsx',
    '**/*.spec.js',
    '**/*.spec.ts',
    '**/*.spec.jsx',
    '**/*.spec.tsx',
    'pytest.ini',
    'tox.ini',
]

_TEST_FILES_EXACT = [
    'pytest.ini', 'tox.ini', 'setup.cfg', 'pyproject.toml',
    'package.json', 'Cargo.toml', 'go.mod',
]

_STATIC_ANALYSIS_GLOBS = [
    '.mypy.ini',
    'mypy.ini',
    '.pylintrc',
    'pylintrc',
    '.flake8',
    '.eslintrc',
    '.eslintrc.js',
    '.eslintrc.cjs',
    '.eslintrc.json',
    '.eslintrc.yml',
    '.eslintrc.yaml',
    'sonar-project.properties',
    'tsconfig.json',
    'ruff.toml',
    '.ruff.toml',
    'pyproject.toml',
]

_FORMATTER_GLOBS = [
    '.prettierrc',
    '.prettierrc.js',
    '.prettierrc.cjs',
    '.prettierrc.json',
    '.prettierrc.yml',
    '.prettierrc.yaml',
    '.editorconfig',
    'rustfmt.toml',
    '.rustfmt.toml',
    '.clang-format',
    'pyproject.toml',
    'ruff.toml',
    '.ruff.toml',
]


def _detect_ci(root: Path) -> tuple[bool, list[str]]:
    markers = []
    for pattern in _CI_GLOBS:
        for p in root.glob(pattern):
            markers.append(str(p.relative_to(root)))
    return bool(markers), markers


def _detect_tests(root: Path, tracked: Set[str]) -> tuple[bool, list[str]]:
    markers = []
    # Glob-based
    for pattern in _TEST_GLOBS:
        for p in root.glob(pattern):
            if p.is_file():
                markers.append(str(p.relative_to(root)))
                break   # one representative per pattern is enough

    # File-content based (pytest section, test script, …)
    for fname in _TEST_FILES_EXACT:
        fp = root / fname
        if not fp.is_file():
            continue
        if fname == 'pyproject.toml':
            if _file_contains(fp, ['[tool.pytest', '[pytest']):
                markers.append(fname + ' ([tool.pytest])')
        elif fname == 'setup.cfg':
            if _file_contains(fp, ['[tool:pytest', '[pytest']):
                markers.append(fname + ' ([pytest] section)')
        elif fname == 'package.json':
            try:
                data = json.loads(fp.read_text(errors='replace'))
                if 'test' in data.get('scripts', {}):
                    markers.append(fname + ' (scripts.test)')
            except (json.JSONDecodeError, OSError):
                pass
        elif fname in ('Cargo.toml', 'go.mod'):
            # Rust and Go have idiomatic test support built-in
            if fp.is_file():
                markers.append(fname + ' (native test support)')

    seen = set()
    unique = []
    for m in markers:
        if m not in seen:
            seen.add(m)
            unique.append(m)
    return bool(unique), unique


def _detect_static_analysis(root: Path) -> tuple[bool, list[str]]:
    markers = []
    found_paths: Set[str] = set()

    for pattern in _STATIC_ANALYSIS_GLOBS:
        fp = root / pattern
        if not fp.is_file():
            continue
        rel = str(fp.relative_to(root))
        if rel in found_paths:
            continue
        if pattern == 'pyproject.toml':
            if _file_contains(fp, ['[tool.mypy', '[tool.pylint', '[tool.ruff']):
                markers.append(rel + ' ([tool.mypy/pylint/ruff])')
                found_paths.add(rel)
        else:
            markers.append(rel)
            found_paths.add(rel)

    return bool(markers), markers


def _detect_formatter(root: Path) -> tuple[bool, list[str]]:
    markers = []
    found_paths: Set[str] = set()

    for pattern in _FORMATTER_GLOBS:
        fp = root / pattern
        if not fp.is_file():
            continue
        rel = str(fp.relative_to(root))
        if rel in found_paths:
            continue
        if pattern in ('pyproject.toml', 'ruff.toml', '.ruff.toml'):
            if _file_contains(fp, ['[tool.black', '[tool.ruff.format', '[format]']):
                markers.append(rel + ' ([tool.black/ruff.format])')
                found_paths.add(rel)
        else:
            markers.append(rel)
            found_paths.add(rel)

    return bool(markers), markers


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def analyse_tooling(
    tracked: Set[str],
    repo_root: str,
) -> dict:
    """
    Returns a dict with keys:
        ci, tests, static_analysis, formatter  →  {present, markers}
        file_count, total_loc, loc_by_language
    """
    root = Path(repo_root)
    total_loc, by_lang, _per_file = count_loc(tracked, repo_root)

    ci_ok, ci_markers = _detect_ci(root)
    test_ok, test_markers = _detect_tests(root, tracked)
    sa_ok, sa_markers = _detect_static_analysis(root)
    fmt_ok, fmt_markers = _detect_formatter(root)

    return {
        'ci': {'present': ci_ok, 'markers': ci_markers},
        'tests': {'present': test_ok, 'markers': test_markers},
        'static_analysis': {'present': sa_ok, 'markers': sa_markers},
        'formatter': {'present': fmt_ok, 'markers': fmt_markers},
        'file_count': len(tracked),
        'total_loc': total_loc,
        'loc_by_language': dict(sorted(by_lang.items(), key=lambda x: -x[1])),
    }
