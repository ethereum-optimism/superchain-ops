"""Shared helpers for OPCM-family adapters."""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any

from devnet.descriptor import Chain, Devnet
from rpc import RpcError, fetch_opcm_version

from .base import Adapter, AdapterError, TaskFiles

_ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
_HEX_ADDRESS = re.compile(r"^0x[0-9a-fA-F]{40}$")
_HEX_BYTES32 = re.compile(r"^0x[0-9a-fA-F]{64}$")

# Keys op-deployer has used for the OPCM impl across versions, in the order
# we should prefer them. Newer deployers (v0.7+) write OpcmV2Impl; older
# ones (v0.5/v0.6) write OpcmImpl. Some deployer versions set both — only one
# of them is non-zero, so we pick the first non-zero match.
_OPCM_IMPL_KEYS = ("OpcmV2Impl", "OpcmImpl", "opcmV2Impl", "opcmImpl")


@dataclass(frozen=True)
class AddressSource:
    source: str
    target: str | None = None
    group: str = "op"


@dataclass(frozen=True)
class PrestateSource:
    name: str
    value: str | None
    path: str


class OPCMUpgradeAdapter(Adapter):
    """Common behavior for OPCM upgrade templates.

    Subclasses still own the template-specific TOML shape and address list, but
    the source resolution rules stay in one place.
    """

    expected_opcm_version: str

    def verify(self, devnet: Devnet, task_files: TaskFiles, rpc_url: str) -> None:
        opcm = task_files.config_toml["addresses"]["OPCM"]
        verify_opcm_version(rpc_url, opcm, self.expected_opcm_version)

    def resolve_opcm(self, devnet: Devnet, overrides: dict[str, str]) -> str:
        if "OPCM" in overrides:
            value = overrides["OPCM"]
        else:
            value = resolve_opcm_from_state(devnet.deployer_state)
            if not value:
                keys = ", ".join(_OPCM_IMPL_KEYS)
                raise AdapterError(
                    "OPCM not found at "
                    "op-deployer/state.json.implementationsDeployment "
                    f"(checked {keys}; all missing or zero). "
                    "Supply via --override OPCM=0x..."
                )
        return clean_address(value, "OPCM")

    def resolve_prestate(self, source: PrestateSource, overrides: dict[str, str]) -> str:
        value = overrides.get(source.name) or source.value
        if not value:
            raise AdapterError(
                f"{source.name} not found at {source.path}. "
                f"Supply via --override {source.name}=0x..."
            )
        if not _HEX_BYTES32.match(value):
            raise AdapterError(
                f"{source.name} is not a 0x-prefixed 32-byte hash: {value!r}"
            )
        return value

    def resolve_uint(self, name: str, overrides: dict[str, str]) -> int:
        if name not in overrides:
            raise AdapterError(
                f"{name} has no devnet source; supply via --override {name}=<decimal>"
            )
        raw = overrides[name]
        try:
            value = int(raw, 0)
        except ValueError as exc:
            raise AdapterError(f"{name} is not a valid integer: {raw!r}") from exc
        if value < 0:
            raise AdapterError(f"{name} must be non-negative: {value}")
        return value

    def resolve_uint32(self, name: str, overrides: dict[str, str]) -> int:
        value = self.resolve_uint(name, overrides)
        if value >= 2**32:
            raise AdapterError(f"{name} must fit in uint32: got {value}")
        return value


def resolve_opcm_from_state(deployer_state: dict[str, Any]) -> str | None:
    """Find the deployed OPCM address in op-deployer/state.json.

    Returns the first non-zero address under any known
    ``implementationsDeployment.<OpcmImpl|OpcmV2Impl>`` key, or ``None`` if
    every candidate is missing or zero.
    """
    impls = deployer_state.get("implementationsDeployment") or {}
    for key in _OPCM_IMPL_KEYS:
        value = impls.get(key)
        if isinstance(value, str) and value.lower() != _ZERO_ADDRESS:
            return value
    return None


def build_chain_addresses(
    chain: Chain,
    owner_safe: str,
    sources: tuple[AddressSource, ...],
    required: tuple[str, ...],
    *,
    extras: dict[str, str] | None = None,
    template_name: str = "template",
    hint: str | None = None,
) -> dict[str, str]:
    out = {"ProxyAdminOwner": clean_address(owner_safe, "ProxyAdminOwner")}
    groups = {
        "op": chain.addresses,
        "superchain": chain.superchain_addresses,
    }
    for spec in sources:
        source_group = groups.get(spec.group)
        if source_group is None:
            raise AdapterError(f"unknown address source group: {spec.group}")
        if spec.source in source_group:
            target = spec.target or spec.source
            out[target] = clean_address(source_group[spec.source], target)

    for name, value in (extras or {}).items():
        out[name] = clean_address(value, name)

    missing = [name for name in required if name not in out]
    if missing:
        message = (
            f"chain {chain.name} ({chain.chain_id}) is missing addresses required by "
            f"{template_name}: {', '.join(missing)}"
        )
        if hint:
            message += f". {hint}"
        raise AdapterError(message)
    return out


def clean_address(addr: str, name: str) -> str:
    if not isinstance(addr, str) or not _HEX_ADDRESS.match(addr):
        raise AdapterError(f"{name} is not a 0x-prefixed 20-byte address: {addr!r}")
    if addr.startswith("0X"):
        return "0x" + addr[2:]
    return addr


def index_roles_by_chain_id(deployer_state: dict[str, Any]) -> dict[int, dict[str, str]]:
    out: dict[int, dict[str, str]] = {}
    chains = (deployer_state.get("appliedIntent") or {}).get("chains") or []
    for entry in chains:
        raw_id = entry.get("id")
        roles = entry.get("roles") or {}
        if not isinstance(raw_id, str) or not isinstance(roles, dict):
            continue
        try:
            chain_id = int(raw_id, 16)
        except ValueError:
            continue
        out[chain_id] = {k: v for k, v in roles.items() if isinstance(v, str)}
    return out


def verify_opcm_version(rpc_url: str, opcm_address: str, expected: str) -> None:
    """Call ``OPCM.version()`` over RPC and assert it matches ``expected``.

    ``expected`` is either:

    - An exact version string, e.g. ``"6.0.0"`` — the actual reported version
      must equal it byte-for-byte.
    - A wildcard pattern using ``x`` for unconstrained dotted components, e.g.
      ``"7.x.x"`` — the actual version's components must match component-wise
      where ``expected`` is not ``x``. ``"7.x.x"`` accepts ``7.0.0``,
      ``7.1.15``, ``7.0.0-rc.1`` (extra trailing components are OK).

    Wildcard form is appropriate when a template targets an OPCM family that
    is still in active development and minor/patch versions are expected to
    drift before the template is finalised.

    Raises :class:`AdapterError` on mismatch or on RPC failure.
    """
    try:
        actual = fetch_opcm_version(rpc_url, opcm_address)
    except RpcError as exc:
        raise AdapterError(
            f"failed to read OPCM.version() at {opcm_address} via {rpc_url}: {exc}. "
            "Pass --rpc-url to use a different RPC, or --offline to skip the check."
        ) from exc
    if not version_matches(actual, expected):
        raise AdapterError(
            f"OPCM at {opcm_address} reports version {actual!r}, expected {expected!r}. "
            "Likely cause: the wrong OPCM address was sourced from the devnet (or the "
            "devnet was redeployed). Pass --override OPCM=0x... to point at the right one."
        )


def version_matches(actual: str, expected: str) -> bool:
    """Return whether ``actual`` satisfies ``expected``.

    Exact match unless ``expected`` contains an ``x`` component, in which case
    the comparison is component-wise with ``x`` accepting any value.
    """
    expected_parts = expected.split(".")
    if not any(p.lower() == "x" for p in expected_parts):
        return actual == expected
    actual_parts = actual.split(".")
    if len(actual_parts) < len(expected_parts):
        return False
    for ep, ap in zip(expected_parts, actual_parts):
        if ep.lower() == "x":
            continue
        if ep != ap:
            return False
    return True
