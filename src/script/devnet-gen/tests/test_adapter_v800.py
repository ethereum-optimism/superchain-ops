from pathlib import Path

import pytest

from adapters import AdapterError, get
from devnet import load_devnet

FIXTURE = Path(__file__).resolve().parent / "fixtures" / "devnets" / "freya-u16"

# V800 defaults initBond to the standard 0.08 ETH bond; the user still supplies
# startingRespectedGameType because it depends on upgrade intent.
DEFAULT_INIT_BOND_WEI = 80_000_000_000_000_000
DEFAULTS = {"startingRespectedGameType": "1"}


def test_v800_defaults_init_bond():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV800")
    files = a.build(d, overrides={"startingRespectedGameType": "1"})
    assert files.config_toml["opcmUpgrades"][0]["initBond"] == DEFAULT_INIT_BOND_WEI


def test_v800_requires_starting_game_type():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV800")
    with pytest.raises(AdapterError, match="startingRespectedGameType"):
        a.build(d, overrides={})


def test_v800_steady_state():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV800")
    files = a.build(d, overrides=dict(DEFAULTS))

    cfg = files.config_toml
    assert cfg["templateName"] == "OPCMUpgradeV800"
    assert cfg["addresses"] == {"OPCM": "0x365b0aeb2b72387897ae0adcd293f75a60555b03"}
    assert "StandardValidator" not in cfg["addresses"]

    upgrades = cfg["opcmUpgrades"]
    assert len(upgrades) == 2
    # Per-chain entries carry the V800-specific fields.
    assert upgrades[0]["initBond"] == DEFAULT_INIT_BOND_WEI
    assert upgrades[0]["startingRespectedGameType"] == 1
    # Same prestate values across chains (per-devnet).
    assert (
        upgrades[0]["cannonPrestate"]
        == "0x03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef"
    )
    assert (
        upgrades[0]["cannonKonaPrestate"]
        == "0x03a7000000000000000000000000000000000000000000000000000000000001"
    )
    # Alphabetical key order matches V800's TOML decoder expectation.
    assert list(upgrades[0].keys()) == [
        "cannonKonaPrestate",
        "cannonPrestate",
        "chainId",
        "expectedValidationErrors",
        "initBond",
        "startingRespectedGameType",
    ]


def test_v800_addresses_json_v800_renames():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV800")
    files = a.build(d, overrides=dict(DEFAULTS))

    chain_a = files.addresses_json["420110015"]
    # V800 WETH renames (different from V600).
    assert chain_a["PermissionedWETH"] == "0x65843EcB299E22489CE580Bc88F0EDcB9557Ed53"
    assert chain_a["PermissionlessWETH"] == "0x0000000000000000000000000000000000000000"
    # SuperchainConfig + ProtocolVersions sourced from chain.yaml.superchainDeployment.
    assert chain_a["SuperchainConfig"] == "0x1B1ce2a9cEd5A6d4C4b3384D8D8F7EA8031896E2"
    assert chain_a["ProtocolVersions"] == "0x2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A"
    # EthLockboxProxy passthrough.
    assert chain_a["EthLockboxProxy"] == "0xf4A94b374B30E6cB97D6B0e00C409F096E0f0EF0"
    # ProxyAdminOwner from manifest.l1.owner_safe_address.
    assert chain_a["ProxyAdminOwner"] == "0xe934Dc97E347C6aCef74364B50125bb8689c40ff"
    # Proposer + Challenger from op-deployer state.appliedIntent roles.
    assert chain_a["Proposer"] == "0x000c245b7a2e946c9eee6b488f1da07af15ad4f4"
    assert chain_a["Challenger"] == "0x293204bfa7f28c4a4275b377ccafd525d2225d37"


def test_v800_per_chain_roles():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV800")
    files = a.build(d, overrides=dict(DEFAULTS))

    chain_a = files.addresses_json["420110015"]
    chain_b = files.addresses_json["420110016"]
    # Different chains -> different roles in the fixture state.json.
    assert chain_a["Proposer"] != chain_b["Proposer"]
    assert chain_a["Challenger"] != chain_b["Challenger"]


def test_v800_overrides():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV800")
    files = a.build(
        d,
        overrides={
            **DEFAULTS,
            "OPCM": "0x1111111111111111111111111111111111111111",
            "initBond": "80000000000000000",  # 0.08 eth in wei
            "startingRespectedGameType": "5",
        },
    )
    assert files.config_toml["addresses"]["OPCM"] == "0x1111111111111111111111111111111111111111"
    assert files.config_toml["opcmUpgrades"][0]["initBond"] == 80000000000000000
    assert files.config_toml["opcmUpgrades"][0]["startingRespectedGameType"] == 5


def test_v800_init_bond_accepts_hex():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV800")
    files = a.build(d, overrides={**DEFAULTS, "initBond": "0x10"})
    assert files.config_toml["opcmUpgrades"][0]["initBond"] == 16


def test_v800_rejects_non_uint32_game_type():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV800")
    with pytest.raises(AdapterError, match="uint32"):
        a.build(d, overrides={**DEFAULTS, "startingRespectedGameType": str(2**33)})


def test_v800_rejects_negative_init_bond():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV800")
    with pytest.raises(AdapterError, match="non-negative"):
        a.build(d, overrides={**DEFAULTS, "initBond": "-1"})


def test_v800_resolves_opcm_v2_impl_when_legacy_key_zero(tmp_path, monkeypatch):
    """Newer op-deployer (v0.7+) writes OpcmV2Impl and zeros OpcmImpl; the
    adapter must pick the non-zero key."""
    from devnet.descriptor import Chain, Devnet, L1Info, Prestates

    devnet = Devnet(
        name="sdg-v1",
        type="alphanet",
        scope_url=None,
        path=tmp_path,
        l1=L1Info(
            name="sepolia",
            chain_id=11155111,
            owner_safe_address="0xe934Dc97E347C6aCef74364B50125bb8689c40ff",
        ),
        chains=(
            Chain(
                name="sdg-v1-0",
                chain_id=420100099,
                addresses={
                    "OpChainProxyAdminImpl": "0x" + "11" * 20,
                    "AddressManagerImpl": "0x" + "12" * 20,
                    "L1Erc721BridgeProxy": "0x" + "13" * 20,
                    "OptimismMintableErc20FactoryProxy": "0x" + "14" * 20,
                    "DelayedWethPermissionedGameProxy": "0x" + "15" * 20,
                    "DelayedWethPermissionlessGameProxy": "0x" + "16" * 20,
                    "SystemConfigProxy": "0x" + "17" * 20,
                    "L1CrossDomainMessengerProxy": "0x" + "18" * 20,
                    "L1StandardBridgeProxy": "0x" + "19" * 20,
                    "OptimismPortalProxy": "0x" + "1a" * 20,
                    "DisputeGameFactoryProxy": "0x" + "1b" * 20,
                    "AnchorStateRegistryProxy": "0x" + "1c" * 20,
                    "EthLockboxProxy": "0x" + "1d" * 20,
                },
                superchain_addresses={
                    "SuperchainConfigProxy": "0x" + "20" * 20,
                    "ProtocolVersionsProxy": "0x" + "21" * 20,
                },
            ),
        ),
        prestates=Prestates(
            cannon64="0x" + "ab" * 32,
            cannon_interop=None,
            cannon_kona="0x" + "cd" * 32,
        ),
        deployer_state={
            "implementationsDeployment": {
                # Legacy key zeroed, V2 key carries the real address.
                "OpcmImpl": "0x0000000000000000000000000000000000000000",
                "OpcmV2Impl": "0x15c65ee282777e4a2856fdf26d33ee4d5bab30c4",
            },
            "appliedIntent": {
                "chains": [
                    {
                        "id": "0x" + format(420100099, "064x"),
                        "roles": {
                            "proposer": "0x" + "30" * 20,
                            "challenger": "0x" + "31" * 20,
                        },
                    }
                ]
            },
        },
    )
    a = get("OPCMUpgradeV800")
    files = a.build(devnet, overrides=dict(DEFAULTS))
    assert (
        files.config_toml["addresses"]["OPCM"]
        == "0x15c65ee282777e4a2856fdf26d33ee4d5bab30c4"
    )
