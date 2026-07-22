"""Adapter for the OPCMUpgradeV800 Solidity template."""

from __future__ import annotations

from devnet.descriptor import Devnet

from . import _opcm
from .base import AdapterError, InputSpec, TaskFiles

_ADDRESS_SOURCES = (
    _opcm.AddressSource("OpChainProxyAdminImpl", "ProxyAdmin"),
    _opcm.AddressSource("AddressManagerImpl", "AddressManager"),
    _opcm.AddressSource("L1Erc721BridgeProxy", "L1ERC721BridgeProxy"),
    _opcm.AddressSource(
        "OptimismMintableErc20FactoryProxy", "OptimismMintableERC20FactoryProxy"
    ),
    _opcm.AddressSource("DelayedWethPermissionedGameProxy", "PermissionedWETH"),
    _opcm.AddressSource("DelayedWethPermissionlessGameProxy", "PermissionlessWETH"),
    _opcm.AddressSource("SystemConfigProxy"),
    _opcm.AddressSource("L1CrossDomainMessengerProxy"),
    _opcm.AddressSource("L1StandardBridgeProxy"),
    _opcm.AddressSource("OptimismPortalProxy"),
    _opcm.AddressSource("DisputeGameFactoryProxy"),
    _opcm.AddressSource("AnchorStateRegistryProxy"),
    _opcm.AddressSource("EthLockboxProxy"),
    _opcm.AddressSource("SuperchainConfigProxy", "SuperchainConfig", "superchain"),
    _opcm.AddressSource("ProtocolVersionsProxy", "ProtocolVersions", "superchain"),
)

_REQUIRED = (
    "SuperchainConfig",
    "ProtocolVersions",
    "ProxyAdmin",
    "ProxyAdminOwner",
    "AddressManager",
    "SystemConfigProxy",
    "OptimismPortalProxy",
    "DisputeGameFactoryProxy",
    "AnchorStateRegistryProxy",
    "L1StandardBridgeProxy",
    "L1ERC721BridgeProxy",
    "L1CrossDomainMessengerProxy",
    "OptimismMintableERC20FactoryProxy",
    "PermissionedWETH",
    "PermissionlessWETH",
    "EthLockboxProxy",
    "Proposer",
    "Challenger",
)

DEFAULT_INIT_BOND_WEI = 80_000_000_000_000_000


class OPCMUpgradeV800(_opcm.OPCMUpgradeAdapter):
    template_name = "OPCMUpgradeV800"
    description = "Upgrade an OP chain's L1 contracts using the V800 template (op-contracts/v7.1.x)."
    # The V800 template's onchain check is `version().startsWith("7.1.")`, so
    # any 7.1.x is accepted. Mirror that here.
    expected_opcm_version = "7.1.x"

    def inputs(self) -> list[InputSpec]:
        return [
            InputSpec(
                name="OPCM",
                description="Target OPCM v7.1.x (delegatecall target).",
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
                source="op-program/prestates.json.kona.hash (or cannonKona.hash)",
            ),
            InputSpec(
                name="initBond",
                description=(
                    "Per-chain initBond (uint256, decimal). Defaults to 0.08 ETH "
                    "and is applied to every dispute game."
                ),
                source="default: 80000000000000000 wei; override with --override initBond=<wei>",
            ),
            InputSpec(
                name="startingRespectedGameType",
                description=(
                    "Per-chain startingRespectedGameType (uint32). "
                    "0=CANNON, 1=PERMISSIONED_CANNON, 4=SUPER_CANNON, "
                    "5=SUPER_PERMISSIONED_CANNON, 8=CANNON_KONA, 9=SUPER_CANNON_KONA."
                ),
                source="user-supplied",
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
                "op-program/prestates.json.kona.hash",
            ),
            overrides,
        )
        init_bond = (
            self.resolve_uint("initBond", overrides)
            if "initBond" in overrides
            else DEFAULT_INIT_BOND_WEI
        )
        starting_game_type = self.resolve_uint32("startingRespectedGameType", overrides)

        roles_by_chain = _opcm.index_roles_by_chain_id(devnet.deployer_state)

        l2chains = [{"name": c.name, "chainId": c.chain_id} for c in devnet.chains]

        opcm_upgrades = [
            {
                # Fields in alphabetical order — V800's forge TOML decoder requires it.
                "cannonKonaPrestate": cannon_kona_prestate,
                "cannonPrestate": cannon_prestate,
                "chainId": c.chain_id,
                "expectedValidationErrors": "",
                "initBond": init_bond,
                "startingRespectedGameType": starting_game_type,
            }
            for c in devnet.chains
        ]

        addresses_json = {
            str(c.chain_id): _opcm.build_chain_addresses(
                c,
                devnet.l1.owner_safe_address,
                _ADDRESS_SOURCES,
                _REQUIRED,
                extras=_role_addresses(roles_by_chain.get(c.chain_id, {})),
                template_name=self.template_name,
                hint=(
                    "Verify chain.yaml.contracts.opChainDeployment, "
                    "chain.yaml.contracts.superchainDeployment, and "
                    "op-deployer/state.json.appliedIntent.chains[].roles."
                ),
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


def _role_addresses(roles: dict[str, str]) -> dict[str, str]:
    out: dict[str, str] = {}
    if proposer := roles.get("proposer"):
        out["Proposer"] = proposer
    if challenger := roles.get("challenger"):
        out["Challenger"] = challenger
    return out
