"""Adapter for the OPCMUpgradeV600 Solidity template."""

from __future__ import annotations

from devnet.descriptor import Devnet

from . import _opcm
from .base import InputSpec, TaskFiles

_ADDRESS_SOURCES = (
    _opcm.AddressSource("OpChainProxyAdminImpl", "ProxyAdmin"),
    _opcm.AddressSource("AddressManagerImpl", "AddressManager"),
    _opcm.AddressSource("L1Erc721BridgeProxy", "L1ERC721BridgeProxy"),
    _opcm.AddressSource(
        "OptimismMintableErc20FactoryProxy", "OptimismMintableERC20FactoryProxy"
    ),
    _opcm.AddressSource("DelayedWethPermissionedGameProxy", "PermissionedDelayedWETHProxy"),
    _opcm.AddressSource("DelayedWethPermissionlessGameProxy", "DelayedWETHProxy"),
    _opcm.AddressSource("SystemConfigProxy"),
    _opcm.AddressSource("L1CrossDomainMessengerProxy"),
    _opcm.AddressSource("L1StandardBridgeProxy"),
    _opcm.AddressSource("OptimismPortalProxy"),
    _opcm.AddressSource("DisputeGameFactoryProxy"),
    _opcm.AddressSource("AnchorStateRegistryProxy"),
)

_REQUIRED = (
    "ProxyAdmin",
    "ProxyAdminOwner",
    "SystemConfigProxy",
    "OptimismPortalProxy",
    "DisputeGameFactoryProxy",
    "AnchorStateRegistryProxy",
    "L1StandardBridgeProxy",
    "L1ERC721BridgeProxy",
    "L1CrossDomainMessengerProxy",
    "AddressManager",
    "DelayedWETHProxy",
    "PermissionedDelayedWETHProxy",
)


class OPCMUpgradeV600(_opcm.OPCMUpgradeAdapter):
    template_name = "OPCMUpgradeV600"
    description = "Upgrade an OP chain's L1 contracts to op-contracts/v6.0.0."
    expected_opcm_version = "6.0.0"

    def inputs(self) -> list[InputSpec]:
        return [
            InputSpec(
                name="OPCM",
                description="Target OPCM v6.0.0 (delegatecall target).",
                source="op-deployer/state.json.implementationsDeployment.OpcmImpl",
            ),
            InputSpec(
                name="cannonPrestate",
                description="Cannon64 absolute prestate hash.",
                source="op-program/prestates.json.cannon64.hash",
            ),
            InputSpec(
                name="cannonKonaPrestate",
                description="Cannon-Kona absolute prestate hash.",
                source="op-program/prestates.json.cannonKona.hash",
            ),
        ]

    def build(self, devnet: Devnet, overrides: dict[str, str]) -> TaskFiles:
        opcm = self.resolve_opcm(devnet, overrides)
        cannon_prestate = self.resolve_prestate(
            _opcm.PrestateSource(
                "cannonPrestate",
                devnet.prestates.cannon64,
                "op-program/prestates.json.cannon64.hash",
            ),
            overrides,
        )
        cannon_kona_prestate = self.resolve_prestate(
            _opcm.PrestateSource(
                "cannonKonaPrestate",
                devnet.prestates.cannon_kona,
                "op-program/prestates.json.cannonKona.hash",
            ),
            overrides,
        )

        l2chains = [{"name": c.name, "chainId": c.chain_id} for c in devnet.chains]

        opcm_upgrades = [
            {
                "chainId": c.chain_id,
                "cannonPrestate": cannon_prestate,
                "cannonKonaPrestate": cannon_kona_prestate,
                "expectedValidationErrors": "",
            }
            for c in devnet.chains
        ]

        addresses_json = {
            str(c.chain_id): _opcm.build_chain_addresses(
                c,
                devnet.l1.owner_safe_address,
                _ADDRESS_SOURCES,
                _REQUIRED,
                template_name=self.template_name,
            )
            for c in devnet.chains
        }

        config_toml = {
            "l2chains": l2chains,
            "templateName": self.template_name,
            "opcmUpgrades": opcm_upgrades,
            "addresses": {"OPCM": opcm},
        }

        readme_context = {
            "opcm": opcm,
            "cannon_prestate": cannon_prestate,
            "cannon_kona_prestate": cannon_kona_prestate,
            "opcm_overridden": "OPCM" in overrides,
            "cannon_prestate_overridden": "cannonPrestate" in overrides,
            "cannon_kona_prestate_overridden": "cannonKonaPrestate" in overrides,
        }

        return TaskFiles(
            config_toml=config_toml,
            addresses_json=addresses_json,
            readme_context=readme_context,
        )
