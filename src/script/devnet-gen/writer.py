"""Render a TaskFiles bundle into an on-disk task directory."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from datetime import date
from pathlib import Path

import tomli_w
from jinja2 import Environment, FileSystemLoader, StrictUndefined

from adapters.base import Adapter, TaskFiles
from devnet.descriptor import Devnet

_TEMPLATES_DIR = Path(__file__).resolve().parent / "templates"
_NNN_PREFIX = re.compile(r"^(\d{3})-")
_KEBAB_BOUNDARY_1 = re.compile(r"([a-z0-9])([A-Z])")
_KEBAB_BOUNDARY_2 = re.compile(r"([A-Z]+)([A-Z][a-z])")


class WriterError(Exception):
    pass


@dataclass(frozen=True)
class WrittenFile:
    path: Path
    content: str


@dataclass(frozen=True)
class WriteResult:
    task_dir: Path
    files: tuple[WrittenFile, ...]


def render(
    *,
    adapter: Adapter,
    devnet: Devnet,
    task_files: TaskFiles,
    out_dir: Path,
    repo_root: Path,
    name_override: str | None = None,
    force: bool = False,
) -> WriteResult:
    """Render TaskFiles into ``out_dir`` and return the result.

    Files are returned in memory first; nothing touches disk until every file
    is rendered cleanly.
    """
    # Devnet tasks live directly under <out_dir> (e.g. src/tasks/sep/) — same
    # depth as production-network tasks — because `just sign` / `just approve`
    # / `just simulate` derive the network from the parent directory name and
    # would resolve `<out_dir>/devnets/<name>/` as network=<name>. Tasks are
    # kept out of `simulate-stack sep` via the `Status: DEVNET` filter wired
    # into fetch-tasks.sh.
    task_dir_name = name_override or _auto_name(
        adapter.template_name, devnet.name, out_dir
    )
    task_dir = out_dir / task_dir_name

    if task_dir.exists() and not force:
        raise WriterError(
            f"Task directory already exists: {task_dir}. Use --force to overwrite."
        )

    fallback_path = (task_dir / "addresses.json").relative_to(repo_root)

    config = dict(task_files.config_toml)
    config["fallbackAddressesJsonPath"] = str(fallback_path)
    config_text = tomli_w.dumps(config)

    addresses_text = json.dumps(task_files.addresses_json, indent=2) + "\n"

    env = Environment(
        loader=FileSystemLoader(str(_TEMPLATES_DIR)),
        undefined=StrictUndefined,
        keep_trailing_newline=True,
    )
    readme_ctx = {
        "task_name": task_dir.name,
        "task_rel_path": str(task_dir.relative_to(repo_root)),
        "adapter_description": adapter.description,
        "devnet": devnet,
        "generated_on": date.today().isoformat(),
        "cannon_prestate": None,
        "cannon_prestate_overridden": False,
        "cannon_kona_prestate": None,
        "cannon_kona_prestate_overridden": False,
        "opcm": None,
        "opcm_overridden": False,
        **task_files.readme_context,
    }
    readme_text = env.get_template("README.md.j2").render(**readme_ctx)
    validation_text = env.get_template("VALIDATION.md.j2").render(
        task_name=task_dir.name, devnet=devnet
    )

    env_lines = ["TENDERLY_GAS=10000000"]
    for k, v in task_files.extra_env.items():
        env_lines.append(f"{k}={v}")
    env_text = "\n".join(env_lines) + "\n"

    files = (
        WrittenFile(task_dir / "config.toml", config_text),
        WrittenFile(task_dir / "addresses.json", addresses_text),
        WrittenFile(task_dir / "README.md", readme_text),
        WrittenFile(task_dir / "VALIDATION.md", validation_text),
        WrittenFile(task_dir / ".env", env_text),
    )

    task_dir.mkdir(parents=True, exist_ok=True)
    for f in files:
        f.path.write_text(f.content)

    return WriteResult(task_dir=task_dir, files=files)


def _auto_name(template_name: str, devnet_name: str, out_dir: Path) -> str:
    slug = _slug(template_name)
    next_num = _next_prefix(out_dir)
    return f"{next_num:03d}-{slug}-{devnet_name}"


def _slug(template_name: str) -> str:
    """`OPCMUpgradeV600` -> `opcm-upgrade-v600`."""
    s = _KEBAB_BOUNDARY_1.sub(r"\1-\2", template_name)
    s = _KEBAB_BOUNDARY_2.sub(r"\1-\2", s)
    return s.lower()


def _next_prefix(parent_dir: Path) -> int:
    if not parent_dir.is_dir():
        return 0
    used: list[int] = []
    for child in parent_dir.iterdir():
        if not child.is_dir():
            continue
        m = _NNN_PREFIX.match(child.name)
        if m:
            used.append(int(m.group(1)))
    return (max(used) + 1) if used else 0
