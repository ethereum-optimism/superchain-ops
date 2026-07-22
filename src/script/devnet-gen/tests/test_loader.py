from pathlib import Path

import pytest

from devnet import LoaderError, load_devnet

FIXTURE = Path(__file__).resolve().parent / "fixtures" / "devnets" / "freya-u16"


def test_load_freya_u16_basics():
    d = load_devnet(FIXTURE)
    assert d.name == "freya-u16"
    assert d.type == "betanet"
    assert d.l1.name == "sepolia"
    assert d.l1.chain_id == 11155111
    assert d.l1.owner_safe_address == "0xe934Dc97E347C6aCef74364B50125bb8689c40ff"
    assert len(d.chains) == 2
    assert d.chains[0].name == "freya-u16-0"
    assert d.chains[0].chain_id == 420110015
    assert d.chains[1].chain_id == 420110016


def test_load_prestates():
    d = load_devnet(FIXTURE)
    assert d.prestates.cannon64 == (
        "0x03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef"
    )
    assert d.prestates.cannon_kona == (
        "0x03a7000000000000000000000000000000000000000000000000000000000001"
    )


def test_load_chain_addresses_verbatim():
    d = load_devnet(FIXTURE)
    chain = d.chains[0]
    # Keys preserved as-is (camelCase from chain.yaml).
    assert chain.addresses["SystemConfigProxy"] == "0x207BF7d95964Ac655cB60B99c46c5a5AabEA1F8F"
    assert chain.addresses["L1Erc721BridgeProxy"] == "0xC864e4c7f5B89f08b3BE20C105a3F0487Ad58472"


def test_load_superchain_addresses():
    d = load_devnet(FIXTURE)
    chain = d.chains[0]
    assert (
        chain.superchain_addresses["SuperchainConfigProxy"]
        == "0x1B1ce2a9cEd5A6d4C4b3384D8D8F7EA8031896E2"
    )
    assert (
        chain.superchain_addresses["ProtocolVersionsProxy"]
        == "0x2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A2A"
    )


def test_load_deployer_state():
    d = load_devnet(FIXTURE)
    assert (
        d.deployer_state["implementationsDeployment"]["OpcmImpl"]
        == "0x365b0aeb2b72387897ae0adcd293f75a60555b03"
    )


def test_missing_path_errors(tmp_path):
    with pytest.raises(LoaderError):
        load_devnet(tmp_path / "nope")


def test_missing_chain_yaml(tmp_path):
    # Copy manifest only — chain dirs missing.
    (tmp_path / "manifest.yaml").write_text((FIXTURE / "manifest.yaml").read_text())
    with pytest.raises(LoaderError, match="Missing chain descriptor"):
        load_devnet(tmp_path)


def test_load_with_embedded_locator(tmp_path):
    """Manifests using ``locator: embedded`` don't carry a ``version`` field
    under ``l1-contracts``. The loader must not require it."""
    manifest = """\
name: sdg-v1
type: alphanet
l1:
  name: sepolia
  chain_id: 11155111
  owner_safe_address: 0xe934Dc97E347C6aCef74364B50125bb8689c40ff
l2:
  deployment:
    op-deployer:
      version: 0.7.0-alpha.2
    l1-contracts:
      locator: embedded
    l2-contracts:
      locator: embedded
  chains:
    - name: sdg-v1-0
      chain_id: "420100099"
"""
    (tmp_path / "manifest.yaml").write_text(manifest)
    chain_dir = tmp_path / "sdg-v1-0"
    chain_dir.mkdir()
    (chain_dir / "chain.yaml").write_text(
        "name: sdg-v1-0\nchain_id: 420100099\ncontracts:\n  opChainDeployment: {}\n"
    )
    d = load_devnet(tmp_path)
    assert d.name == "sdg-v1"
    assert d.chains[0].chain_id == 420100099
