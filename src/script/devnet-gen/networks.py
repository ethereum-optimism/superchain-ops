"""Hardcoded L1 RPC URLs.

Devnet manifests don't reliably carry a usable L1 RPC, so the generator
maintains its own mapping from L1 chain name to a publicly-reachable RPC.
Override per-invocation via ``--rpc-url``.
"""

from __future__ import annotations

L1_RPC_URLS = {
    "sepolia": "https://ethereum-sepolia.publicnode.com",
    "mainnet": "https://ethereum.publicnode.com",
}


def l1_rpc_url(l1_name: str) -> str:
    if l1_name not in L1_RPC_URLS:
        known = ", ".join(sorted(L1_RPC_URLS))
        raise KeyError(
            f"No hardcoded L1 RPC for L1 network {l1_name!r}. "
            f"Known: {known}. Add an entry in networks.py or pass --rpc-url."
        )
    return L1_RPC_URLS[l1_name]
