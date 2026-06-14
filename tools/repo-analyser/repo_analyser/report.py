"""
Payload assembly: builds a single JSON-serialisable dict from all section results.
The HTML rendering is handled by html_report.py.
"""
from __future__ import annotations

from typing import Any, Dict, Optional


def _json_default(obj: Any) -> Any:
    """JSON serialiser for types not handled by the stdlib encoder."""
    if isinstance(obj, set):
        return sorted(obj)
    return repr(obj)


def build_payload(
    meta: dict,
    tooling: Optional[dict] = None,
    authors: Optional[dict] = None,
    stable: Optional[dict] = None,
    hot: Optional[dict] = None,
    recent: Optional[dict] = None,
    file_matrix: Optional[list] = None,
) -> Dict[str, Any]:
    """
    Assemble all section results into a single dict ready for JSON serialisation.

    Only keys with non-None values are included, so a filtered run (--section X)
    only carries that section's data in the output.
    """
    payload: Dict[str, Any] = {'meta': meta}
    if tooling is not None:
        payload['tooling'] = tooling
    if authors is not None:
        payload['authors'] = authors
    if stable is not None:
        payload['stable'] = stable
    if hot is not None:
        payload['hot'] = hot
    if recent is not None:
        payload['recent'] = recent
    if file_matrix is not None:
        payload['file_matrix'] = file_matrix
    return payload
