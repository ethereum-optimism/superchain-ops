"""Adapter auto-discovery.

Importing this package walks every sibling module so that each :class:`Adapter`
subclass registers itself in :data:`ADAPTERS` via :func:`base.register`.
"""

from __future__ import annotations

import importlib
import pkgutil

from .base import ADAPTERS, Adapter, AdapterError, InputSpec, TaskFiles

__all__ = ["ADAPTERS", "Adapter", "AdapterError", "InputSpec", "TaskFiles", "get"]


def _autodiscover() -> None:
    for module_info in pkgutil.iter_modules(__path__):
        if module_info.name in ("base", "__init__") or module_info.name.startswith("_"):
            continue
        importlib.import_module(f"{__name__}.{module_info.name}")


def get(template_name: str) -> Adapter:
    if not ADAPTERS:
        _autodiscover()
    if template_name not in ADAPTERS:
        known = ", ".join(sorted(ADAPTERS)) or "<none>"
        raise AdapterError(
            f"No adapter registered for template '{template_name}'. Known: {known}"
        )
    return ADAPTERS[template_name]


_autodiscover()
