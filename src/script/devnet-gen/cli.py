"""CLI entry point for devnet-gen."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Allow `python cli.py ...` from the devnet-gen directory.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from adapters import ADAPTERS, Adapter, AdapterError, get  # noqa: E402
from devnet import LoaderError, load_devnet  # noqa: E402
from networks import l1_rpc_url  # noqa: E402
from writer import WriterError, render  # noqa: E402

L1_TO_OPS_NETWORK = {"sepolia": "sep"}

_SUBCOMMANDS = {"gen", "list", "info"}


def main(argv: list[str] | None = None) -> int:
    if argv is None:
        argv = sys.argv[1:]
    # Allow `devnet-gen <template> <devnet>` as shorthand for `devnet-gen gen ...`.
    if argv and argv[0] not in _SUBCOMMANDS and not argv[0].startswith("-"):
        argv = ["gen", *argv]

    parser = _build_parser()
    args = parser.parse_args(argv)
    handler = getattr(args, "handler", None)
    if handler is None:
        parser.print_help()
        return 1
    try:
        return handler(args)
    except (LoaderError, AdapterError, WriterError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="devnet-gen",
        description="Generate superchain-ops devnet task directories.",
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    g = sub.add_parser("gen", help="Generate a task.")
    g.add_argument("template", help="Template name, e.g. OPCMUpgradeV600.")
    g.add_argument("devnet_path", help="Path to the devnet directory.")
    g.add_argument(
        "--override",
        action="append",
        default=[],
        metavar="NAME=VALUE",
        help="Override a single input. Repeatable.",
    )
    g.add_argument("--name", help="Override the auto-generated task directory name.")
    g.add_argument(
        "--out",
        help=(
            "Override the directory under which the task gets written "
            "(default: <repo>/src/tasks/<network>). The generator appends "
            "/<NNN>-<template-slug>-<devnet-name> to it."
        ),
    )
    g.add_argument("--dry-run", action="store_true", help="Print planned files; write nothing.")
    g.add_argument("--force", action="store_true", help="Overwrite an existing task directory.")
    g.add_argument(
        "--rpc-url",
        help=(
            "L1 RPC URL used by adapter onchain checks (default: hardcoded per L1 "
            "network in networks.py — publicnode for sepolia/mainnet)."
        ),
    )
    g.add_argument(
        "--offline",
        action="store_true",
        help="Skip onchain adapter checks (e.g. OPCM.version() verification).",
    )
    g.set_defaults(handler=_cmd_gen)

    ls = sub.add_parser("list", help="List available adapters.")
    ls.set_defaults(handler=_cmd_list)

    info = sub.add_parser("info", help="Describe one adapter's inputs.")
    info.add_argument("template")
    info.set_defaults(handler=_cmd_info)
    return p


def _cmd_list(_: argparse.Namespace) -> int:
    if not ADAPTERS:
        print("No adapters registered.")
        return 0
    width = max(len(name) for name in ADAPTERS)
    for name in sorted(ADAPTERS):
        adapter = ADAPTERS[name]
        print(f"{name.ljust(width)}  {adapter.description}")
    return 0


def _cmd_info(args: argparse.Namespace) -> int:
    adapter = get(args.template)
    print(f"{adapter.template_name} — {adapter.description}\n")
    print("Inputs:")
    name_w = max((len(s.name) for s in adapter.inputs()), default=0)
    for spec in adapter.inputs():
        print(f"  {spec.name.ljust(name_w)}  {spec.description}")
        print(f"  {' ' * name_w}    source: {spec.source}")
    print(
        "\nOverride any input with --override <name>=<value>. Names are case-sensitive."
    )
    return 0


def _cmd_gen(args: argparse.Namespace) -> int:
    adapter: Adapter = get(args.template)
    devnet = load_devnet(args.devnet_path)
    overrides = _parse_overrides(args.override)

    network = L1_TO_OPS_NETWORK.get(devnet.l1.name)
    if not network:
        raise AdapterError(
            f"Unsupported L1 network: {devnet.l1.name!r}. Add a mapping in cli.L1_TO_OPS_NETWORK."
        )

    if args.out:
        out_dir = Path(args.out).resolve()
        repo_root = _repo_root_from_out_dir(out_dir) or _repo_root()
    else:
        repo_root = _repo_root()
        out_dir = repo_root / "src" / "tasks" / network

    task_files = adapter.build(devnet, overrides)

    if not args.offline:
        rpc_url = args.rpc_url or l1_rpc_url(devnet.l1.name)
        adapter.verify(devnet, task_files, rpc_url)
    else:
        adapter.validate_offline(devnet, task_files)

    if args.dry_run:
        return _dry_run(devnet, task_files, out_dir)

    result = render(
        adapter=adapter,
        devnet=devnet,
        task_files=task_files,
        out_dir=out_dir,
        repo_root=repo_root,
        name_override=args.name,
        force=args.force,
    )
    print(f"Wrote {len(result.files)} files to {result.task_dir}")
    for f in result.files:
        if f.path.is_relative_to(repo_root):
            print(f"  {f.path.relative_to(repo_root)}")
        else:
            print(f"  {f.path}")
    return 0


def _dry_run(devnet, task_files, out_dir: Path) -> int:
    import tomli_w

    config = dict(task_files.config_toml)
    config["fallbackAddressesJsonPath"] = "<set by writer>"
    print("# config.toml")
    print(tomli_w.dumps(config))
    print("# addresses.json")
    print(json.dumps(task_files.addresses_json, indent=2))
    print(f"\n(target: {out_dir})")
    return 0


def _parse_overrides(raw: list[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for entry in raw:
        if "=" not in entry:
            raise AdapterError(f"--override expects NAME=VALUE, got: {entry!r}")
        name, _, value = entry.partition("=")
        name = name.strip()
        value = value.strip()
        if not name or not value:
            raise AdapterError(f"--override has empty name or value: {entry!r}")
        out[name] = value
    return out


def _repo_root() -> Path:
    p = Path(__file__).resolve()
    for parent in p.parents:
        if (parent / ".git").exists() or (parent / "src" / "template").is_dir():
            return parent
    raise RuntimeError("Could not locate repo root from cli.py")


def _repo_root_from_out_dir(out_dir: Path) -> Path | None:
    """Walk up from out_dir looking for a directory whose ``src/tasks`` contains it.

    Lets tests pass ``--out=<tmp>/src/tasks/sep`` and have ``fallbackAddressesJsonPath``
    resolve relative to ``<tmp>``.
    """
    for parent in [out_dir, *out_dir.parents]:
        if (parent / "src" / "tasks").is_dir():
            return parent
    return None


if __name__ == "__main__":
    sys.exit(main())
