"""Tests for the JSON-RPC helpers.

We exercise the ABI string-decoder directly and stub urllib for the eth_call
path. No real network access is performed by these tests.
"""

from __future__ import annotations

import io
import json

import pytest

import rpc


def _abi_encode_string(s: str) -> str:
    body = s.encode("utf-8")
    pad = (32 - len(body) % 32) % 32
    return (
        "0x"
        + (32).to_bytes(32, "big").hex()  # offset
        + len(body).to_bytes(32, "big").hex()  # length
        + body.hex()
        + ("00" * pad)
    )


def test_decode_string_short():
    encoded = _abi_encode_string("6.0.0")
    assert rpc._decode_string(encoded, "version") == "6.0.0"


def test_decode_string_unicode():
    encoded = _abi_encode_string("v7.1.15-rc.1+ʇsǝʇ")
    assert rpc._decode_string(encoded, "version") == "v7.1.15-rc.1+ʇsǝʇ"


def test_decode_string_rejects_truncated():
    truncated = "0x" + "00" * 32  # only the offset, no length
    with pytest.raises(rpc.RpcError, match="too short"):
        rpc._decode_string(truncated, "version")


def test_decode_string_rejects_oversized_length():
    bad = (
        "0x"
        + (32).to_bytes(32, "big").hex()
        + (1024).to_bytes(32, "big").hex()  # claims 1024 bytes but body is empty
    )
    with pytest.raises(rpc.RpcError, match="exceeds payload"):
        rpc._decode_string(bad, "version")


def test_eth_call_returns_result_string(monkeypatch):
    captured = {}

    class _FakeResp(io.BytesIO):
        def __enter__(self):
            return self

        def __exit__(self, *a):
            return False

    def _fake_urlopen(req, timeout):
        captured["url"] = req.full_url
        captured["body"] = json.loads(req.data)
        return _FakeResp(json.dumps({"jsonrpc": "2.0", "id": 1, "result": "0xdead"}).encode())

    monkeypatch.setattr(rpc.urllib.request, "urlopen", _fake_urlopen)

    result = rpc.eth_call("https://example/rpc", "0x" + "11" * 20, "0x54fd4d50")
    assert result == "0xdead"
    assert captured["url"] == "https://example/rpc"
    assert captured["body"]["method"] == "eth_call"
    assert captured["body"]["params"][0]["to"] == "0x" + "11" * 20
    assert captured["body"]["params"][0]["data"] == "0x54fd4d50"


def test_eth_call_surfaces_rpc_error(monkeypatch):
    class _FakeResp(io.BytesIO):
        def __enter__(self):
            return self

        def __exit__(self, *a):
            return False

    def _fake_urlopen(req, timeout):
        return _FakeResp(
            json.dumps({"jsonrpc": "2.0", "id": 1, "error": {"code": -32000, "message": "revert"}}).encode()
        )

    monkeypatch.setattr(rpc.urllib.request, "urlopen", _fake_urlopen)
    with pytest.raises(rpc.RpcError, match="RPC error"):
        rpc.eth_call("https://example/rpc", "0x" + "11" * 20, "0x54fd4d50")


def test_fetch_opcm_version(monkeypatch):
    encoded = _abi_encode_string("6.0.0")

    def _fake_eth_call(rpc_url, to, data, *, timeout=rpc.DEFAULT_TIMEOUT_SECONDS):
        return encoded

    monkeypatch.setattr(rpc, "eth_call", _fake_eth_call)
    assert rpc.fetch_opcm_version("https://example/rpc", "0x" + "11" * 20) == "6.0.0"
