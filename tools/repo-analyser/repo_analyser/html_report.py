"""
HTML report writer: injects the analysis payload into the template and writes
a single self-contained report.html.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .report import _json_default


def render_html(payload: dict, template_path: str) -> str:
    """
    Load the HTML template, embed *payload* as JSON, and return the final HTML.

    The JSON is escaped so that `</script>` and HTML metacharacters inside string
    values can never break the page structure.
    """
    template = Path(template_path).read_text(encoding='utf-8')

    data_json = json.dumps(
        payload,
        ensure_ascii=False,
        separators=(',', ':'),   # compact
        default=_json_default,
    )
    # Escape HTML metacharacters that could end the <script type="application/json"> block
    data_json = (
        data_json
        .replace('&', r'&')
        .replace('<', r'<')
        .replace('>', r'>')
    )

    return template.replace('__ANALYSIS_DATA__', data_json)


def write_html(html: str, output_dir: str) -> str:
    """Write *html* to <output_dir>/report.html and return the absolute path."""
    out = Path(output_dir)
    out.mkdir(parents=True, exist_ok=True)
    p = out / 'report.html'
    p.write_text(html, encoding='utf-8')
    return str(p)
