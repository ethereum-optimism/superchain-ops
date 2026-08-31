import json
from pathlib import Path

import tomllib

import pytest

from adapters import get
from devnet import load_devnet
from writer import WriterError, render

FIXTURE = Path(__file__).resolve().parent / "fixtures" / "devnets" / "freya-u16"


def _setup(tmp_path):
    repo_root = tmp_path / "repo"
    out_dir = repo_root / "src" / "tasks" / "sep"
    out_dir.mkdir(parents=True)
    devnet = load_devnet(FIXTURE)
    adapter = get("OPCMUpgradeV600")
    return repo_root, out_dir, devnet, adapter


def test_writer_creates_full_task_dir(tmp_path):
    repo_root, out_dir, devnet, adapter = _setup(tmp_path)
    files = adapter.build(devnet, overrides={})
    result = render(
        adapter=adapter,
        devnet=devnet,
        task_files=files,
        out_dir=out_dir,
        repo_root=repo_root,
    )

    # Tasks land directly under <out_dir> with the devnet name in the slug.
    assert result.task_dir == out_dir / "000-opcm-upgrade-v600-freya-u16"
    assert (result.task_dir / "config.toml").is_file()
    assert (result.task_dir / "addresses.json").is_file()
    assert (result.task_dir / "README.md").is_file()
    assert (result.task_dir / "VALIDATION.md").is_file()
    assert (result.task_dir / ".env").is_file()


def test_writer_config_toml_roundtrips(tmp_path):
    repo_root, out_dir, devnet, adapter = _setup(tmp_path)
    files = adapter.build(devnet, overrides={})
    result = render(
        adapter=adapter,
        devnet=devnet,
        task_files=files,
        out_dir=out_dir,
        repo_root=repo_root,
    )
    cfg = tomllib.loads((result.task_dir / "config.toml").read_text())
    assert cfg["templateName"] == "OPCMUpgradeV600"
    assert cfg["fallbackAddressesJsonPath"].endswith("addresses.json")
    # The fallback path is relative to the repo root.
    assert not cfg["fallbackAddressesJsonPath"].startswith("/")
    assert "src/tasks/sep/000-opcm-upgrade-v600-freya-u16/addresses.json" in (
        cfg["fallbackAddressesJsonPath"]
    )


def test_writer_addresses_json_valid(tmp_path):
    repo_root, out_dir, devnet, adapter = _setup(tmp_path)
    files = adapter.build(devnet, overrides={})
    result = render(
        adapter=adapter,
        devnet=devnet,
        task_files=files,
        out_dir=out_dir,
        repo_root=repo_root,
    )
    data = json.loads((result.task_dir / "addresses.json").read_text())
    assert set(data.keys()) == {"420110015", "420110016"}


def test_writer_auto_increments_prefix(tmp_path):
    repo_root, out_dir, devnet, adapter = _setup(tmp_path)
    files = adapter.build(devnet, overrides={})
    first = render(
        adapter=adapter,
        devnet=devnet,
        task_files=files,
        out_dir=out_dir,
        repo_root=repo_root,
    )
    second = render(
        adapter=adapter,
        devnet=devnet,
        task_files=files,
        out_dir=out_dir,
        repo_root=repo_root,
    )
    assert first.task_dir.name == "000-opcm-upgrade-v600-freya-u16"
    assert second.task_dir.name == "001-opcm-upgrade-v600-freya-u16"


def test_writer_force_overwrite(tmp_path):
    repo_root, out_dir, devnet, adapter = _setup(tmp_path)
    files = adapter.build(devnet, overrides={})
    render(
        adapter=adapter,
        devnet=devnet,
        task_files=files,
        out_dir=out_dir,
        repo_root=repo_root,
        name_override="custom-task",
    )
    with pytest.raises(WriterError, match="already exists"):
        render(
            adapter=adapter,
            devnet=devnet,
            task_files=files,
            out_dir=out_dir,
            repo_root=repo_root,
            name_override="custom-task",
        )
    # With force, succeeds.
    render(
        adapter=adapter,
        devnet=devnet,
        task_files=files,
        out_dir=out_dir,
        repo_root=repo_root,
        name_override="custom-task",
        force=True,
    )


def test_writer_readme_includes_devnet_context(tmp_path):
    repo_root, out_dir, devnet, adapter = _setup(tmp_path)
    files = adapter.build(devnet, overrides={"OPCM": "0x" + "11" * 20})
    result = render(
        adapter=adapter,
        devnet=devnet,
        task_files=files,
        out_dir=out_dir,
        repo_root=repo_root,
    )
    readme = (result.task_dir / "README.md").read_text()
    assert "freya-u16" in readme
    assert "Devnet Context" in readme
    assert "(overridden)" in readme  # OPCM was overridden
    assert "Status: DEVNET" in readme
