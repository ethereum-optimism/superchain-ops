import json
from pathlib import Path

import pytest
import tomllib

from cli import main

FIXTURE = Path(__file__).resolve().parent / "fixtures" / "devnets" / "freya-u16"


@pytest.fixture(autouse=True)
def _stub_opcm_version(monkeypatch):
    """Default: pretend the onchain OPCM reports the version each adapter expects.

    Tests that want to exercise the version-mismatch path override this stub.
    """
    expected_by_template = {
        "OPCMUpgradeV600": "6.0.0",
        "OPCMUpgradeV800": "7.1.17",
        "OPCMMigrateV800": "7.1.17",
    }

    def _fake(rpc_url, address, expected, *, _expected_by_template=expected_by_template):
        # The helper compares actual to expected internally; we just need to
        # avoid the real HTTP call. Returning None matches the real signature.
        return None

    import adapters._opcm as opcm_helpers

    monkeypatch.setattr(opcm_helpers, "verify_opcm_version", _fake)


def test_cli_list(capsys):
    rc = main(["list"])
    assert rc == 0
    out = capsys.readouterr().out
    assert "OPCMUpgradeV600" in out
    assert "OPCMMigrateV800" in out


def test_cli_info(capsys):
    rc = main(["info", "OPCMUpgradeV600"])
    assert rc == 0
    out = capsys.readouterr().out
    assert "OPCM" in out
    assert "cannonPrestate" in out
    assert "op-deployer/state.json" in out


def test_cli_info_unknown_template(capsys):
    rc = main(["info", "NopeTemplate"])
    assert rc == 1
    err = capsys.readouterr().err
    assert "No adapter registered" in err


def test_cli_gen_writes_files(tmp_path):
    out = tmp_path / "src" / "tasks"
    out.mkdir(parents=True)
    rc = main(
        [
            "OPCMUpgradeV600",
            str(FIXTURE),
            "--out",
            str(out / "sep"),
        ]
    )
    assert rc == 0
    task_dir = out / "sep" / "000-opcm-upgrade-v600-freya-u16"
    assert (task_dir / "config.toml").is_file()
    cfg = tomllib.loads((task_dir / "config.toml").read_text())
    assert cfg["templateName"] == "OPCMUpgradeV600"

    addresses = json.loads((task_dir / "addresses.json").read_text())
    assert "420110015" in addresses


def test_cli_gen_subcommand_form(tmp_path):
    out = tmp_path / "src" / "tasks"
    out.mkdir(parents=True)
    rc = main(
        [
            "gen",
            "OPCMUpgradeV600",
            str(FIXTURE),
            "--out",
            str(out / "sep"),
        ]
    )
    assert rc == 0


def test_cli_dry_run_writes_nothing(tmp_path, capsys):
    out = tmp_path / "src" / "tasks"
    out.mkdir(parents=True)
    rc = main(
        [
            "OPCMUpgradeV600",
            str(FIXTURE),
            "--out",
            str(out / "sep"),
            "--dry-run",
        ]
    )
    assert rc == 0
    # No task directory should have been created.
    sep_children = list((out / "sep").iterdir()) if (out / "sep").exists() else []
    assert sep_children == []
    assert "templateName" in capsys.readouterr().out


def test_cli_override(tmp_path):
    out = tmp_path / "src" / "tasks"
    out.mkdir(parents=True)
    new_opcm = "0x" + "ab" * 20
    rc = main(
        [
            "OPCMUpgradeV600",
            str(FIXTURE),
            "--out",
            str(out / "sep"),
            "--override",
            f"OPCM={new_opcm}",
        ]
    )
    assert rc == 0
    cfg = tomllib.loads(
        (
            out
            / "sep"
            / "000-opcm-upgrade-v600-freya-u16"
            / "config.toml"
        ).read_text()
    )
    assert cfg["addresses"]["OPCM"] == new_opcm


def test_cli_unknown_template(capsys):
    rc = main(["NopeTemplate", str(FIXTURE)])
    assert rc == 1
    assert "No adapter registered" in capsys.readouterr().err


def test_cli_offline_skips_rpc(tmp_path, monkeypatch):
    """With --offline, even a totally unreachable RPC must not be touched."""

    def _explode(*args, **kwargs):
        raise AssertionError("RPC call attempted under --offline")

    import adapters._opcm as opcm_helpers

    monkeypatch.setattr(opcm_helpers, "verify_opcm_version", _explode)

    out = tmp_path / "src" / "tasks"
    out.mkdir(parents=True)
    rc = main(
        [
            "OPCMUpgradeV600",
            str(FIXTURE),
            "--out",
            str(out / "sep"),
            "--offline",
        ]
    )
    assert rc == 0


def test_cli_version_mismatch_aborts(tmp_path, monkeypatch, capsys):
    """A real version mismatch (no --offline) must abort with a clear message."""
    from adapters.base import AdapterError

    def _mismatch(rpc_url, address, expected):
        raise AdapterError(
            f"OPCM at {address} reports version '5.0.0', expected '6.0.0'."
        )

    import adapters._opcm as opcm_helpers

    monkeypatch.setattr(opcm_helpers, "verify_opcm_version", _mismatch)

    out = tmp_path / "src" / "tasks"
    out.mkdir(parents=True)
    rc = main(
        [
            "OPCMUpgradeV600",
            str(FIXTURE),
            "--out",
            str(out / "sep"),
        ]
    )
    assert rc == 1
    assert "version" in capsys.readouterr().err.lower()
    # Mismatch must abort before any file is written.
    sep_children = list((out / "sep").iterdir()) if (out / "sep").exists() else []
    assert sep_children == []


def test_cli_custom_rpc_url(tmp_path, monkeypatch):
    """--rpc-url must be passed through to the verify helper."""
    seen = {}

    def _capture(rpc_url, address, expected):
        seen["rpc_url"] = rpc_url

    import adapters._opcm as opcm_helpers

    monkeypatch.setattr(opcm_helpers, "verify_opcm_version", _capture)

    out = tmp_path / "src" / "tasks"
    out.mkdir(parents=True)
    rc = main(
        [
            "OPCMUpgradeV600",
            str(FIXTURE),
            "--out",
            str(out / "sep"),
            "--rpc-url",
            "https://custom.example/rpc",
        ]
    )
    assert rc == 0
    assert seen["rpc_url"] == "https://custom.example/rpc"
