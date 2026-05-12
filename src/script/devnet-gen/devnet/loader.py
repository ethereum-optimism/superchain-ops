from __future__ import annotations

import json
import re
import warnings
from pathlib import Path
from typing import Any

import yaml

from .descriptor import Chain, Devnet, L1Info, Prestates

DEFAULT_OWNER_SAFE_ADDRESS = "0xe934Dc97E347C6aCef74364B50125bb8689c40ff"


class LoaderError(Exception):
    pass


class LoaderWarning(UserWarning):
    pass


class _HexAwareLoader(yaml.SafeLoader):
    """SafeLoader that keeps unquoted ``0x...`` scalars as strings.

    PyYAML follows YAML 1.1, where ``0xabcd`` is an integer literal. Devnet
    manifests don't always quote address fields (e.g. ``owner_safe_address``),
    so an unquoted ``0xe934Dc97...`` would otherwise be parsed as an int and
    we'd lose the original case. This loader replaces the int resolver with a
    decimal-only one, so anything that isn't a plain decimal stays a string.
    """


# Copy parent resolvers so we don't mutate SafeLoader globally.
_HexAwareLoader.yaml_implicit_resolvers = {
    ch: list(resolvers)
    for ch, resolvers in yaml.SafeLoader.yaml_implicit_resolvers.items()
}
# Drop every int resolver (covers hex, octal, binary, sexagesimal — all the
# forms YAML 1.1 supports). Other resolvers (bool, null, float, timestamp)
# stay in place.
for ch, resolvers in _HexAwareLoader.yaml_implicit_resolvers.items():
    _HexAwareLoader.yaml_implicit_resolvers[ch] = [
        r for r in resolvers if r[0] != "tag:yaml.org,2002:int"
    ]
# Re-add a decimal-only int resolver.
_HexAwareLoader.add_implicit_resolver(
    "tag:yaml.org,2002:int",
    re.compile(r"^[-+]?(?:0|[1-9][0-9_]*)$"),
    list("-+0123456789"),
)


def load_devnet(path: str | Path) -> Devnet:
    root = Path(path).expanduser().resolve()
    if not root.is_dir():
        raise LoaderError(f"Devnet path is not a directory: {root}")

    manifest_path = root / "manifest.yaml"
    manifest = _read_yaml(manifest_path)

    l1 = _load_l1(manifest, manifest_path)
    # We deliberately do NOT read l2.deployment.l1-contracts.version. When the
    # locator is "embedded" the manifest doesn't even have a version field, and
    # in any case the source of truth for the deployed OPCM is OPCM.version()
    # onchain (see adapters/_opcm.verify_opcm_version).

    chains = tuple(
        _load_chain(root, chain_entry, idx, manifest_path)
        for idx, chain_entry in enumerate(_dig(manifest, "l2.chains", manifest_path))
    )

    prestates = _load_prestates(root)
    deployer_state = _load_deployer_state(root)

    return Devnet(
        name=_dig(manifest, "name", manifest_path),
        type=_dig(manifest, "type", manifest_path),
        scope_url=manifest.get("scope") or None,
        path=root,
        l1=l1,
        chains=chains,
        prestates=prestates,
        deployer_state=deployer_state,
    )


def _load_l1(manifest: dict[str, Any], src: Path) -> L1Info:
    # eth_rpc deliberately not read — devnet manifests aren't a reliable source
    # for an L1 RPC URL, so the generator hardcodes one per L1 network in
    # networks.py and lets users override via --rpc-url.
    owner_safe_address = _dig_optional(manifest, "l1.owner_safe_address")
    if not owner_safe_address:
        warnings.warn(
            f"{src}: missing field 'l1.owner_safe_address'; "
            f"defaulting to {DEFAULT_OWNER_SAFE_ADDRESS}",
            LoaderWarning,
            stacklevel=2,
        )
        owner_safe_address = DEFAULT_OWNER_SAFE_ADDRESS

    return L1Info(
        name=_dig(manifest, "l1.name", src),
        chain_id=int(_dig(manifest, "l1.chain_id", src)),
        owner_safe_address=owner_safe_address,
    )


def _load_chain(
    root: Path, entry: dict[str, Any], idx: int, src: Path
) -> Chain:
    name = entry.get("name")
    if not name:
        raise LoaderError(f"{src}: l2.chains[{idx}] is missing 'name'")
    raw_chain_id = entry.get("chain_id")
    if raw_chain_id is None:
        raise LoaderError(f"{src}: l2.chains[{idx}] is missing 'chain_id'")
    try:
        chain_id = int(raw_chain_id)
    except (TypeError, ValueError) as exc:
        raise LoaderError(
            f"{src}: l2.chains[{idx}].chain_id is not an int: {raw_chain_id!r}"
        ) from exc

    chain_yaml_path = root / name / "chain.yaml"
    if not chain_yaml_path.is_file():
        raise LoaderError(f"Missing chain descriptor: {chain_yaml_path}")
    chain_yaml = _read_yaml(chain_yaml_path)
    addresses = _dig(chain_yaml, "contracts.opChainDeployment", chain_yaml_path)
    if not isinstance(addresses, dict):
        raise LoaderError(
            f"{chain_yaml_path}: contracts.opChainDeployment must be a mapping"
        )
    # superchainDeployment is optional — older devnets may not have it. Newer
    # OPCM templates (V700+) need SuperchainConfig and ProtocolVersions from here.
    superchain_addresses = chain_yaml.get("contracts", {}).get("superchainDeployment", {})
    if superchain_addresses and not isinstance(superchain_addresses, dict):
        raise LoaderError(
            f"{chain_yaml_path}: contracts.superchainDeployment must be a mapping"
        )
    return Chain(
        name=name,
        chain_id=chain_id,
        addresses=dict(addresses),
        superchain_addresses=dict(superchain_addresses),
    )


def _load_prestates(root: Path) -> Prestates:
    p = root / "op-program" / "prestates.json"
    if not p.is_file():
        return Prestates(cannon64=None, cannon_interop=None, cannon_kona=None)
    data = _read_json(p)
    return Prestates(
        cannon64=_prestate_hash(data, "cannon64"),
        cannon_interop=_prestate_hash(data, "cannonInterop"),
        # Real devnets use the bare key "kona"; older fixtures used "cannonKona".
        cannon_kona=_prestate_hash(data, "kona") or _prestate_hash(data, "cannonKona"),
    )


def _prestate_hash(data: dict[str, Any], key: str) -> str | None:
    entry = data.get(key)
    if not isinstance(entry, dict):
        return None
    val = entry.get("hash")
    return val if isinstance(val, str) and val else None


def _load_deployer_state(root: Path) -> dict[str, Any]:
    p = root / "op-deployer" / "state.json"
    if not p.is_file():
        return {}
    return _read_json(p)


def _read_yaml(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise LoaderError(f"Missing file: {path}")
    try:
        with path.open() as f:
            data = yaml.load(f, Loader=_HexAwareLoader)
    except yaml.YAMLError as exc:
        raise LoaderError(f"Failed to parse YAML at {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise LoaderError(f"{path}: top-level must be a mapping")
    return data


def _read_json(path: Path) -> dict[str, Any]:
    try:
        with path.open() as f:
            data = json.load(f)
    except json.JSONDecodeError as exc:
        raise LoaderError(f"Failed to parse JSON at {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise LoaderError(f"{path}: top-level must be a mapping")
    return data


def _dig(data: dict[str, Any], dotted: str, src: Path) -> Any:
    cur: Any = data
    for part in dotted.split("."):
        if not isinstance(cur, dict) or part not in cur:
            raise LoaderError(f"{src}: missing field '{dotted}'")
        cur = cur[part]
    if cur is None:
        raise LoaderError(f"{src}: field '{dotted}' is null")
    return cur


def _dig_optional(data: dict[str, Any], dotted: str) -> Any | None:
    cur: Any = data
    for part in dotted.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return None
        cur = cur[part]
    return cur
