"""Tests for adapters._opcm helpers."""

from __future__ import annotations

import pytest

from adapters import _opcm
from adapters.base import AdapterError


@pytest.mark.parametrize(
    "actual,expected",
    [
        ("6.0.0", "6.0.0"),
        ("7.0.0", "7.x.x"),
        ("7.1.15", "7.x.x"),
        ("7.99.0", "7.x.x"),
        ("7.0.0-rc.1", "7.x.x"),
        ("7.0.0", "7.x"),
        ("7.0.0", "7.0.x"),
        ("7.0.0.0", "7.x.x"),  # extra trailing components OK
        ("7.0.0", "x.x.x"),
    ],
)
def test_version_matches_accept(actual: str, expected: str):
    assert _opcm.version_matches(actual, expected)


@pytest.mark.parametrize(
    "actual,expected",
    [
        ("6.0.0", "7.0.0"),         # exact mismatch
        ("8.0.0", "7.x.x"),         # major mismatch under wildcard
        ("7", "7.x.x"),             # too few components
        ("7.0", "7.x.x"),           # still too few — pattern wants 3
        ("7.1.15", "7.0.x"),        # minor pinned, mismatch
        ("not.a.version", "7.x.x"), # major mismatch
    ],
)
def test_version_matches_reject(actual: str, expected: str):
    assert not _opcm.version_matches(actual, expected)


def test_verify_opcm_version_exact_pass(monkeypatch):
    monkeypatch.setattr(_opcm, "fetch_opcm_version", lambda url, addr: "6.0.0")
    _opcm.verify_opcm_version("https://rpc", "0x" + "11" * 20, "6.0.0")


def test_verify_opcm_version_wildcard_pass(monkeypatch):
    monkeypatch.setattr(_opcm, "fetch_opcm_version", lambda url, addr: "7.1.17")
    _opcm.verify_opcm_version("https://rpc", "0x" + "11" * 20, "7.x.x")


def test_verify_opcm_version_wildcard_rejects_other_major(monkeypatch):
    monkeypatch.setattr(_opcm, "fetch_opcm_version", lambda url, addr: "8.0.0")
    with pytest.raises(AdapterError, match="reports version '8.0.0'"):
        _opcm.verify_opcm_version("https://rpc", "0x" + "11" * 20, "7.x.x")
