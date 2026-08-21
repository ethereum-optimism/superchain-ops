from pathlib import Path

import pytest

from adapters import AdapterError, get
from devnet import load_devnet

FIXTURE = Path(__file__).resolve().parent / "fixtures" / "devnets" / "freya-u16"


def test_v600_steady_state():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV600")
    files = a.build(d, overrides={})

    cfg = files.config_toml
    assert cfg["templateName"] == "OPCMUpgradeV600"
    assert cfg["l2chains"] == [
        {"name": "freya-u16-0", "chainId": 420110015},
        {"name": "freya-u16-1", "chainId": 420110016},
    ]
    assert cfg["addresses"] == {"OPCM": "0x365b0aeb2b72387897ae0adcd293f75a60555b03"}
    # No StandardValidator — V600 derives it at runtime.
    assert "StandardValidator" not in cfg["addresses"]

    upgrades = cfg["opcmUpgrades"]
    assert len(upgrades) == 2
    assert upgrades[0]["chainId"] == 420110015
    assert (
        upgrades[0]["cannonPrestate"]
        == "0x03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef"
    )
    assert upgrades[0]["cannonKonaPrestate"] == (
        "0x03a7000000000000000000000000000000000000000000000000000000000001"
    )
    assert upgrades[0]["expectedValidationErrors"] == ""


def test_v600_addresses_json_renames():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV600")
    files = a.build(d, overrides={})

    chain_a = files.addresses_json["420110015"]
    # ProxyAdminOwner sourced from manifest.l1.owner_safe_address, not chain.yaml.
    assert chain_a["ProxyAdminOwner"] == "0xe934Dc97E347C6aCef74364B50125bb8689c40ff"
    # Renames applied.
    assert chain_a["ProxyAdmin"] == "0x7d9b0Aa175dc8769a576C2aD1C791AAAcbe873a9"
    assert chain_a["AddressManager"] == "0xfC8d28c1856E0622C97141CfbcB38de2e9714076"
    assert chain_a["L1ERC721BridgeProxy"] == "0xC864e4c7f5B89f08b3BE20C105a3F0487Ad58472"
    assert (
        chain_a["OptimismMintableERC20FactoryProxy"]
        == "0xe00B432C3Ce39C938A3Af7Aef80A2A4e2a7cb1F7"
    )
    assert chain_a["DelayedWETHProxy"] == "0x0000000000000000000000000000000000000000"
    assert chain_a["PermissionedDelayedWETHProxy"] == (
        "0x65843EcB299E22489CE580Bc88F0EDcB9557Ed53"
    )
    # Passthrough.
    assert chain_a["SystemConfigProxy"] == "0x207BF7d95964Ac655cB60B99c46c5a5AabEA1F8F"


def test_v600_overrides():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV600")
    files = a.build(
        d,
        overrides={
            "OPCM": "0x1111111111111111111111111111111111111111",
            "cannonPrestate": "0x" + "ab" * 32,
        },
    )
    assert files.config_toml["addresses"]["OPCM"] == "0x1111111111111111111111111111111111111111"
    assert files.config_toml["opcmUpgrades"][0]["cannonPrestate"] == "0x" + "ab" * 32
    # Non-overridden value still flows from devnet.
    assert (
        files.config_toml["opcmUpgrades"][0]["cannonKonaPrestate"]
        == "0x03a7000000000000000000000000000000000000000000000000000000000001"
    )


def test_v600_rejects_bad_address():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV600")
    with pytest.raises(AdapterError, match="OPCM is not a"):
        a.build(d, overrides={"OPCM": "not-a-hex-address"})


def test_v600_rejects_bad_prestate():
    d = load_devnet(FIXTURE)
    a = get("OPCMUpgradeV600")
    with pytest.raises(AdapterError, match="cannonPrestate is not"):
        a.build(d, overrides={"cannonPrestate": "0xshort"})
