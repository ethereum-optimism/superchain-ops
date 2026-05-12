from dataclasses import replace
from pathlib import Path

import pytest

from adapters import AdapterError, get
import adapters.opcm_migrate_v800 as migrate_v800
from devnet import load_devnet

FIXTURE = Path(__file__).resolve().parent / "fixtures" / "devnets" / "freya-u16"

DEFAULT_INIT_BOND_WEI = 80_000_000_000_000_000
DEFAULTS = {
    "startingAnchorRootL2SequenceNumber": "0",
    "startingAnchorRootRoot": "0x" + "11" * 32,
    "startingRespectedGameType": "5",
    "superChallenger": "0x" + "22" * 20,
    "superProposer": "0x" + "33" * 20,
}
ONCHAIN_DEFAULTS = {
    "startingRespectedGameType": "5",
    "superChallenger": "0x" + "22" * 20,
    "superProposer": "0x" + "33" * 20,
}


def test_migrate_v800_steady_state():
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides=dict(DEFAULTS))

    cfg = files.config_toml
    assert cfg["templateName"] == "OPCMMigrateV800"
    assert cfg["expectedOPCMVersion"] == "7.1.16"
    assert cfg["addresses"] == {"OPCM": "0x365b0aeb2b72387897ae0adcd293f75a60555b03"}

    migrations = cfg["opcmMigrations"]
    assert len(migrations) == 2
    assert list(migrations[0].keys()) == ["cannonKonaPrestate", "chainId"]
    assert migrations[0]["cannonKonaPrestate"] == (
        "0x03a7000000000000000000000000000000000000000000000000000000000001"
    )

    migrate = cfg["migrate"]
    assert list(migrate.keys()) == [
        "expectedValidationErrors",
        "initBond",
        "startingAnchorRootL2SequenceNumber",
        "startingAnchorRootRoot",
        "startingRespectedGameType",
        "superChallenger",
        "superProposer",
    ]
    assert migrate == {
        "expectedValidationErrors": "",
        "initBond": DEFAULT_INIT_BOND_WEI,
        "startingAnchorRootL2SequenceNumber": 0,
        "startingAnchorRootRoot": "0x" + "11" * 32,
        "startingRespectedGameType": 5,
        "superChallenger": "0x" + "22" * 20,
        "superProposer": "0x" + "33" * 20,
    }


def test_migrate_v800_addresses_json():
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides=dict(DEFAULTS))

    chain_a = files.addresses_json["420110015"]
    assert chain_a["SuperchainConfig"] == "0x1B1ce2a9cEd5A6d4C4b3384D8D8F7EA8031896E2"
    assert chain_a["ProtocolVersions"] == "0x2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A"
    assert chain_a["ProxyAdminOwner"] == "0xe934Dc97E347C6aCef74364B50125bb8689c40ff"
    assert chain_a["SystemConfigProxy"] == "0x207BF7d95964Ac655cB60B99c46c5a5AabEA1F8F"
    assert chain_a["OptimismPortalProxy"] == "0xA4cB202E86Cc7CDe348C912cd0955022B5f82758"
    assert chain_a["DisputeGameFactoryProxy"] == "0x03242a08EC839e24d8282fd11b7505CD682C71f5"
    assert chain_a["AnchorStateRegistryProxy"] == "0xdCfa047dE7B61c9F8Ba66b0Ae348Db26D0B87D34"
    assert chain_a["EthLockboxProxy"] == "0xf4A94b374B30E6cB97D6B0e00C409F096E0f0EF0"


def test_migrate_v800_overrides():
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    files = a.build(
        d,
        overrides={
            **DEFAULTS,
            "OPCM": "0x" + "44" * 20,
            "cannonKonaPrestate": "0x" + "55" * 32,
            "expectedValidationErrors": "custom error",
            "initBond": "0x10",
            "startingAnchorRootL2SequenceNumber": "0x20",
            "startingAnchorRootRoot": "0x" + "66" * 32,
            "startingRespectedGameType": "9",
        },
    )

    assert files.config_toml["addresses"]["OPCM"] == "0x" + "44" * 20
    assert files.config_toml["opcmMigrations"][0]["cannonKonaPrestate"] == "0x" + "55" * 32
    migrate = files.config_toml["migrate"]
    assert migrate["expectedValidationErrors"] == "custom error"
    assert migrate["initBond"] == 16
    assert migrate["startingAnchorRootL2SequenceNumber"] == 32
    assert migrate["startingAnchorRootRoot"] == "0x" + "66" * 32
    assert migrate["startingRespectedGameType"] == 9


def test_migrate_v800_defaults_super_roles_from_first_lexicographic_chain_id():
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    files = a.build(
        d,
        overrides={
            "startingAnchorRootL2SequenceNumber": "0",
            "startingAnchorRootRoot": "0x" + "11" * 32,
            "startingRespectedGameType": "5",
        },
    )

    migrate = files.config_toml["migrate"]
    assert migrate["superChallenger"] == "0x293204bfa7f28c4a4275b377ccafd525d2225d37"
    assert migrate["superProposer"] == "0x000c245b7a2e946c9eee6b488f1da07af15ad4f4"


def test_migrate_v800_requires_user_supplied_migrate_fields():
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    with pytest.raises(AdapterError, match="startingRespectedGameType"):
        a.build(d, overrides={})


def test_migrate_v800_rejects_non_super_game_type():
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    with pytest.raises(AdapterError, match="enabled super game type"):
        a.build(d, overrides={**DEFAULTS, "startingRespectedGameType": "1"})


def test_migrate_v800_rejects_bad_anchor_root():
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    with pytest.raises(AdapterError, match="32-byte hash"):
        a.build(d, overrides={**DEFAULTS, "startingAnchorRootRoot": "0x1234"})


def test_migrate_v800_requires_anchor_root_overrides_as_pair():
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    with pytest.raises(AdapterError, match="supplied together"):
        a.build(d, overrides={**ONCHAIN_DEFAULTS, "startingAnchorRootRoot": "0x" + "11" * 32})


def test_migrate_v800_verify_reads_cannon_kona_prestate_from_onchain(monkeypatch):
    d = load_devnet(FIXTURE)
    d = replace(d, prestates=replace(d.prestates, cannon_kona=None))
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides=dict(DEFAULTS))

    assert files.config_toml["opcmMigrations"][0]["cannonKonaPrestate"] == "0x" + "00" * 32

    onchain_prestate = "0x" + "77" * 32
    _stub_verify(monkeypatch, game_impl="0x" + "88" * 20, game_args=bytes.fromhex(onchain_prestate[2:]))

    a.verify(d, files, "https://rpc.example")

    assert [m["cannonKonaPrestate"] for m in files.config_toml["opcmMigrations"]] == [
        onchain_prestate,
        onchain_prestate,
    ]
    assert files.readme_context["cannon_kona_prestate"] == onchain_prestate


def test_migrate_v800_verify_allows_missing_kona_prestate_for_super_permissioned(monkeypatch):
    d = load_devnet(FIXTURE)
    d = replace(d, prestates=replace(d.prestates, cannon_kona=None))
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides=dict(DEFAULTS))

    _stub_verify(monkeypatch, game_impl="0x" + "00" * 20, game_args=b"")

    a.verify(d, files, "https://rpc.example")

    assert [m["cannonKonaPrestate"] for m in files.config_toml["opcmMigrations"]] == [
        "0x" + "00" * 32,
        "0x" + "00" * 32,
    ]


def test_migrate_v800_verify_errors_when_super_cannon_kona_not_set_for_starting_type_9(monkeypatch):
    d = load_devnet(FIXTURE)
    d = replace(d, prestates=replace(d.prestates, cannon_kona=None))
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides={**DEFAULTS, "startingRespectedGameType": "9"})

    _stub_verify(monkeypatch, game_impl="0x" + "00" * 20, game_args=b"")

    with pytest.raises(AdapterError, match="SUPER_CANNON_KONA"):
        a.verify(d, files, "https://rpc.example")


def test_migrate_v800_verify_reads_anchor_root_from_onchain(monkeypatch):
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides=dict(ONCHAIN_DEFAULTS))

    assert files.config_toml["migrate"]["startingAnchorRootRoot"] == "0x" + "00" * 32
    assert files.config_toml["migrate"]["startingAnchorRootL2SequenceNumber"] == 0

    onchain_prestate = "0x" + "77" * 32
    onchain_root = "0x" + "99" * 32
    _stub_verify(
        monkeypatch,
        game_impl="0x" + "88" * 20,
        game_args=bytes.fromhex(onchain_prestate[2:]),
        anchor_root=onchain_root,
        anchor_sequence=123,
    )

    a.verify(d, files, "https://rpc.example")

    assert files.config_toml["migrate"]["startingAnchorRootRoot"] == onchain_root
    assert files.config_toml["migrate"]["startingAnchorRootL2SequenceNumber"] == 123


def test_migrate_v800_verify_uses_first_lexicographic_chain_anchor_root(monkeypatch):
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides=dict(ONCHAIN_DEFAULTS))

    monkeypatch.setattr(migrate_v800.rpc, "fetch_opcm_version", lambda *args: "7.1.17")
    monkeypatch.setattr(
        migrate_v800,
        "_fetch_super_cannon_kona_prestate",
        lambda *args, **kwargs: "0x" + "77" * 32,
    )
    seen_chain_ids = []

    def _fake_anchor_root(*args, chain_id, **kwargs):
        seen_chain_ids.append(chain_id)
        return ("0x" + "99" * 32, 123)

    monkeypatch.setattr(migrate_v800, "_fetch_anchor_root", _fake_anchor_root)

    a.verify(d, files, "https://rpc.example")

    assert seen_chain_ids == [420110015]
    assert files.config_toml["migrate"]["startingAnchorRootRoot"] == "0x" + "99" * 32
    assert files.config_toml["migrate"]["startingAnchorRootL2SequenceNumber"] == 123


def test_migrate_v800_verify_accepts_and_records_actual_7_1_patch(monkeypatch):
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides=dict(ONCHAIN_DEFAULTS))

    _stub_verify(
        monkeypatch,
        opcm_version="7.1.17",
        game_impl="0x" + "88" * 20,
        game_args=bytes.fromhex(("0x" + "77" * 32)[2:]),
    )

    a.verify(d, files, "https://rpc.example")

    assert files.config_toml["expectedOPCMVersion"] == "7.1.17"


def test_migrate_v800_verify_errors_when_anchor_root_zero(monkeypatch):
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides=dict(ONCHAIN_DEFAULTS))

    _stub_verify(
        monkeypatch,
        game_impl="0x" + "88" * 20,
        game_args=bytes.fromhex(("0x" + "77" * 32)[2:]),
        anchor_root="0x" + "00" * 32,
        anchor_sequence=0,
    )

    with pytest.raises(AdapterError, match="anchor root is zero"):
        a.verify(d, files, "https://rpc.example")


def test_migrate_v800_offline_requires_onchain_or_overrides():
    d = load_devnet(FIXTURE)
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides={**ONCHAIN_DEFAULTS, "startingRespectedGameType": "9"})

    with pytest.raises(AdapterError, match="cannonKonaPrestate must be read from onchain"):
        a.validate_offline(d, files)


def test_migrate_v800_offline_allows_zero_kona_for_super_permissioned_with_anchor_override():
    d = load_devnet(FIXTURE)
    d = replace(d, prestates=replace(d.prestates, cannon_kona=None))
    a = get("OPCMMigrateV800")
    files = a.build(d, overrides=dict(DEFAULTS))

    a.validate_offline(d, files)


def _stub_verify(
    monkeypatch,
    *,
    opcm_version: str = "7.1.16",
    game_impl: str,
    game_args: bytes,
    anchor_root: str = "0x" + "99" * 32,
    anchor_sequence: int = 123,
):
    monkeypatch.setattr(migrate_v800.rpc, "fetch_opcm_version", lambda *args: opcm_version)

    def _fake_eth_call(rpc_url, to, data):
        assert rpc_url == "https://rpc.example"
        if data.startswith(migrate_v800._GAME_IMPLS_SELECTOR):
            return _abi_address(game_impl)
        if data.startswith(migrate_v800._GAME_ARGS_SELECTOR):
            return _abi_bytes(game_args)
        if data == migrate_v800._GET_ANCHOR_ROOT_SELECTOR:
            return _abi_anchor_root(anchor_root, anchor_sequence)
        raise AssertionError(f"unexpected call data: {data}")

    monkeypatch.setattr(migrate_v800.rpc, "eth_call", _fake_eth_call)


def _abi_address(addr: str) -> str:
    return "0x" + ("00" * 12) + addr[2:]


def _abi_bytes(payload: bytes) -> str:
    padding = b"\x00" * ((32 - (len(payload) % 32)) % 32)
    return "0x" + (
        (32).to_bytes(32, "big")
        + len(payload).to_bytes(32, "big")
        + payload
        + padding
    ).hex()


def _abi_anchor_root(root: str, sequence: int) -> str:
    return "0x" + (bytes.fromhex(root[2:]) + sequence.to_bytes(32, "big")).hex()
