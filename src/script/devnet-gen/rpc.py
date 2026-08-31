"""Minimal JSON-RPC client used for adapter sanity checks.

Stdlib-only (urllib + json) so the generator's lockfile doesn't grow a new
HTTP client dependency. Only `eth_call` is needed today, so the surface stays
small.
"""

from __future__ import annotations

import json
import urllib.error
import urllib.request

# Solidity selector for `version()` (keccak256("version()")[:4]).
VERSION_SELECTOR = "0x54fd4d50"

DEFAULT_TIMEOUT_SECONDS = 10.0


class RpcError(Exception):
    pass


def eth_call(rpc_url: str, to: str, data: str, *, timeout: float = DEFAULT_TIMEOUT_SECONDS) -> str:
    """Perform a JSON-RPC ``eth_call`` and return the hex result string.

    Raises :class:`RpcError` on transport, decode, or RPC-level errors.
    """
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "eth_call",
        "params": [{"to": to, "data": data}, "latest"],
    }
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        rpc_url,
        data=body,
        headers={
            "Content-Type": "application/json",
            # Some public RPC providers (e.g. publicnode) reject the default
            # Python urllib UA with 403; identify ourselves explicitly.
            "User-Agent": "superchain-ops-devnet-gen/0.1",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
    except (urllib.error.URLError, TimeoutError) as exc:
        raise RpcError(f"eth_call to {rpc_url} failed: {exc}") from exc

    try:
        decoded = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RpcError(f"eth_call returned invalid JSON: {raw!r}") from exc

    if not isinstance(decoded, dict):
        raise RpcError(f"eth_call returned a non-object response: {decoded!r}")
    if "error" in decoded and decoded["error"]:
        raise RpcError(f"eth_call returned an RPC error: {decoded['error']}")
    result = decoded.get("result")
    if not isinstance(result, str):
        raise RpcError(f"eth_call response missing 'result': {decoded!r}")
    return result


def fetch_string(rpc_url: str, address: str, *, selector: str, name: str) -> str:
    """Call a function returning a single ``string`` and ABI-decode the result.

    ``name`` is used purely for error messages.
    """
    raw = eth_call(rpc_url, address, selector)
    return _decode_string(raw, name)


def fetch_opcm_version(rpc_url: str, opcm_address: str) -> str:
    """Call ``OPCM.version()`` and return the resulting version string."""
    return fetch_string(rpc_url, opcm_address, selector=VERSION_SELECTOR, name="version")


def _decode_string(raw_hex: str, name: str) -> str:
    """ABI-decode a single dynamic ``string`` return value.

    Layout:
        bytes  0..32 — offset (always 0x20 for a single string return)
        bytes 32..64 — length in bytes
        bytes 64..   — UTF-8 string data, right-padded to a 32-byte boundary
    """
    if not isinstance(raw_hex, str) or not raw_hex.startswith("0x"):
        raise RpcError(f"{name}: expected 0x-prefixed hex string, got {raw_hex!r}")
    body = bytes.fromhex(raw_hex[2:])
    if len(body) < 64:
        raise RpcError(f"{name}: response too short to be a string ABI return: {raw_hex!r}")
    length = int.from_bytes(body[32:64], "big")
    if 64 + length > len(body):
        raise RpcError(f"{name}: declared length {length} exceeds payload size")
    try:
        return body[64 : 64 + length].decode("utf-8")
    except UnicodeDecodeError as exc:
        raise RpcError(f"{name}: response is not valid UTF-8: {body[64:64 + length]!r}") from exc
