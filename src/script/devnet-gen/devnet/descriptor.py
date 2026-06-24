from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class L1Info:
    name: str
    chain_id: int
    owner_safe_address: str


@dataclass(frozen=True)
class Chain:
    name: str
    chain_id: int
    addresses: dict[str, str]
    # contracts.superchainDeployment from chain.yaml — mostly per-devnet shared
    # but stored per-chain because that's how the source files carry it.
    superchain_addresses: dict[str, str] = field(default_factory=dict)


@dataclass(frozen=True)
class Prestates:
    cannon64: str | None
    cannon_interop: str | None
    cannon_kona: str | None


@dataclass(frozen=True)
class Devnet:
    name: str
    type: str
    scope_url: str | None
    path: Path
    l1: L1Info
    chains: tuple[Chain, ...]
    prestates: Prestates
    deployer_state: dict[str, Any] = field(default_factory=dict)
