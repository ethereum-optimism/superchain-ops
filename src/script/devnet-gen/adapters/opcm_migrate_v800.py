"""Adapter for the OPCMMigrateV800 Solidity template."""

from __future__ import annotations

import re

import rpc
from devnet.descriptor import Devnet

from . import _opcm
from .base import AdapterError, InputSpec, TaskFiles

_HEX_BYTES32 = re.compile(r"^0x[0-9a-fA-F]{64}$")
_ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
_ZERO_BYTES32 = "0x" + "00" * 32
_GAME_IMPLS_SELECTOR = "0x1b685b9e"  # gameImpls(uint32)
_GAME_ARGS_SELECTOR = "0x74cc86ac"  # gameArgs(uint32)
_GET_ANCHOR_ROOT_SELECTOR = "0xd83ef267"  # getAnchorRoot()

_ADDRESS_SOURCES = (
    _opcm.AddressSource("OpChainProxyAdminImpl", "ProxyAdmin"),
    _opcm.AddressSource("AddressManagerImpl", "AddressManager"),
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
    "L1CrossDomainMessengerProxy",
    "EthLockboxProxy",
)

DEFAULT_INIT_BOND_WEI = 80_000_000_000_000_000
DEFAULT_OPCM_VERSION = "7.1.16"
EXPECTED_OPCM_VERSION = "7.1.x"
SUPER_PERMISSIONED_CANNON = 5
SUPER_CANNON_KONA = 9


class OPCMMigrateV800(_opcm.OPCMUpgradeAdapter):
    template_name = "OPCMMigrateV800"
    description = (
        "Migrate V800/Super Root OP chains into a shared dispute game set "
        "(op-contracts/v7.1.x)."
    )
    expected_opcm_version = EXPECTED_OPCM_VERSION

    def inputs(self) -> list[InputSpec]:
        return [
            InputSpec(
                name="OPCM",
                description="Target OPCM v7.1.x with migrator support (delegatecall target).",
                source="op-deployer/state.json.implementationsDeployment.OpcmV2Impl or OpcmImpl",
            ),
            InputSpec(
                name="cannonKonaPrestate",
                description=(
                    "Cannon-Kona absolute prestate hash shared by all migrated chains. "
                    "By default this is read from DisputeGameFactory.gameArgs(9) onchain."
                ),
                source=(
                    "onchain DisputeGameFactory.gameArgs(SUPER_CANNON_KONA); "
                    "override with --override cannonKonaPrestate=0x..."
                ),
            ),
            InputSpec(
                name="initBond",
                description=(
                    "Shared initBond (uint256, decimal). Defaults to 0.08 ETH "
                    "and is applied to both super dispute games."
                ),
                source="default: 80000000000000000 wei; override with --override initBond=<wei>",
            ),
            InputSpec(
                name="startingAnchorRootL2SequenceNumber",
                description=(
                    "Shared starting anchor root L2 sequence number (uint256). "
                    "By default this is read from AnchorStateRegistry.getAnchorRoot() "
                    "for the lexicographically first manifest chain ID."
                ),
                source=(
                    "onchain AnchorStateRegistry.getAnchorRoot() for the lexicographically "
                    "first manifest chain ID; override together with startingAnchorRootRoot"
                ),
            ),
            InputSpec(
                name="startingAnchorRootRoot",
                description=(
                    "Shared starting anchor root hash (bytes32). By default this is read "
                    "from AnchorStateRegistry.getAnchorRoot() for the lexicographically "
                    "first manifest chain ID."
                ),
                source=(
                    "onchain AnchorStateRegistry.getAnchorRoot() for the lexicographically "
                    "first manifest chain ID; override together with "
                    "startingAnchorRootL2SequenceNumber"
                ),
            ),
            InputSpec(
                name="startingRespectedGameType",
                description=(
                    "Shared startingRespectedGameType (uint32). "
                    "5=SUPER_PERMISSIONED_CANNON, 9=SUPER_CANNON_KONA."
                ),
                source="user-supplied",
            ),
            InputSpec(
                name="superChallenger",
                description="Shared challenger address for SUPER_PERMISSIONED_CANNON.",
                source=(
                    "op-deployer/state.json.appliedIntent.chains[].roles.challenger "
                    "for the lexicographically first manifest chain ID"
                ),
            ),
            InputSpec(
                name="superProposer",
                description="Shared proposer address for SUPER_PERMISSIONED_CANNON.",
                source=(
                    "op-deployer/state.json.appliedIntent.chains[].roles.proposer "
                    "for the lexicographically first manifest chain ID"
                ),
            ),
            InputSpec(
                name="expectedValidationErrors",
                description="Expected migration validator errors. Defaults to the empty string.",
                source="default: empty string; override with --override expectedValidationErrors=<string>",
            ),
        ]

    def build(self, devnet: Devnet, overrides: dict[str, str]) -> TaskFiles:
        opcm = self.resolve_opcm(devnet, overrides)
        cannon_kona_prestate = _resolve_initial_cannon_kona_prestate(self, devnet, overrides)
        init_bond = (
            self.resolve_uint("initBond", overrides)
            if "initBond" in overrides
            else DEFAULT_INIT_BOND_WEI
        )
        starting_anchor_root_root, starting_anchor_root_l2_sequence_number = (
            self._resolve_initial_anchor_root(overrides)
        )
        starting_game_type = self.resolve_uint32("startingRespectedGameType", overrides)
        if starting_game_type not in (SUPER_PERMISSIONED_CANNON, SUPER_CANNON_KONA):
            raise AdapterError(
                "startingRespectedGameType must be an enabled super game type "
                f"({SUPER_PERMISSIONED_CANNON} or {SUPER_CANNON_KONA})"
            )
        roles_by_chain = _opcm.index_roles_by_chain_id(devnet.deployer_state)
        super_challenger = _resolve_super_role(
            devnet,
            roles_by_chain,
            overrides,
            name="superChallenger",
            role="challenger",
        )
        super_proposer = _resolve_super_role(
            devnet,
            roles_by_chain,
            overrides,
            name="superProposer",
            role="proposer",
        )

        l2chains = [{"name": c.name, "chainId": c.chain_id} for c in devnet.chains]
        opcm_migrations = [
            {
                # Fields in alphabetical order - the forge TOML decoder requires it.
                "cannonKonaPrestate": cannon_kona_prestate,
                "chainId": c.chain_id,
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
                hint=(
                    "Verify chain.yaml.contracts.opChainDeployment and "
                    "chain.yaml.contracts.superchainDeployment."
                ),
            )
            for c in devnet.chains
        }

        config_toml = {
            "l2chains": l2chains,
            "templateName": self.template_name,
            "expectedOPCMVersion": DEFAULT_OPCM_VERSION,
            "opcmMigrations": opcm_migrations,
            "migrate": {
                # Fields in alphabetical order - the forge TOML decoder requires it.
                "expectedValidationErrors": overrides.get("expectedValidationErrors", ""),
                "initBond": init_bond,
                "startingAnchorRootL2SequenceNumber": starting_anchor_root_l2_sequence_number,
                "startingAnchorRootRoot": starting_anchor_root_root,
                "startingRespectedGameType": starting_game_type,
                "superChallenger": super_challenger,
                "superProposer": super_proposer,
            },
            "addresses": {"OPCM": opcm},
        }

        readme_context = {
            "opcm": opcm,
            "cannon_kona_prestate": cannon_kona_prestate,
            "opcm_overridden": "OPCM" in overrides,
            "cannon_kona_prestate_overridden": "cannonKonaPrestate" in overrides,
            "anchor_root_overridden": _anchor_root_overridden(overrides),
        }

        return TaskFiles(
            config_toml=config_toml,
            addresses_json=addresses_json,
            readme_context=readme_context,
        )

    def verify(self, devnet: Devnet, task_files: TaskFiles, rpc_url: str) -> None:
        actual_opcm_version = _fetch_and_verify_opcm_version(
            rpc_url,
            task_files.config_toml["addresses"]["OPCM"],
            EXPECTED_OPCM_VERSION,
        )
        task_files.config_toml["expectedOPCMVersion"] = actual_opcm_version

        starting_game_type = task_files.config_toml["migrate"]["startingRespectedGameType"]
        require_kona_prestate = starting_game_type == SUPER_CANNON_KONA
        if task_files.readme_context.get("cannon_kona_prestate_overridden"):
            pass
        else:
            prestates = []
            for chain in devnet.chains:
                chain_addresses = task_files.addresses_json[str(chain.chain_id)]
                dispute_game_factory = chain_addresses["DisputeGameFactoryProxy"]
                prestates.append(
                    _fetch_super_cannon_kona_prestate(
                        rpc_url,
                        dispute_game_factory,
                        chain_name=chain.name,
                        chain_id=chain.chain_id,
                        required=require_kona_prestate,
                    )
                )

            if require_kona_prestate:
                first = prestates[0]
                for chain, prestate in zip(devnet.chains[1:], prestates[1:]):
                    if prestate != first:
                        raise AdapterError(
                            "SUPER_CANNON_KONA cannonKonaPrestate mismatch: "
                            f"{devnet.chains[0].name} has {first}, {chain.name} has {prestate}"
                        )
            else:
                first = next((p for p in prestates if p != _ZERO_BYTES32), _ZERO_BYTES32)

            for migration in task_files.config_toml["opcmMigrations"]:
                migration["cannonKonaPrestate"] = first
            task_files.readme_context["cannon_kona_prestate"] = first

        if not task_files.readme_context.get("anchor_root_overridden"):
            anchor_chain = _first_chain_by_lexicographic_chain_id(devnet)
            chain_addresses = task_files.addresses_json[str(anchor_chain.chain_id)]
            anchor_state_registry = chain_addresses["AnchorStateRegistryProxy"]
            anchor_root, anchor_sequence = _fetch_anchor_root(
                rpc_url,
                anchor_state_registry,
                chain_name=anchor_chain.name,
                chain_id=anchor_chain.chain_id,
            )

            task_files.config_toml["migrate"]["startingAnchorRootRoot"] = anchor_root
            task_files.config_toml["migrate"]["startingAnchorRootL2SequenceNumber"] = (
                anchor_sequence
            )

    def validate_offline(self, devnet: Devnet, task_files: TaskFiles) -> None:
        starting_game_type = task_files.config_toml["migrate"]["startingRespectedGameType"]
        if (
            starting_game_type == SUPER_CANNON_KONA
            and not task_files.readme_context.get("cannon_kona_prestate_overridden")
        ):
            raise AdapterError(
                "cannonKonaPrestate must be read from onchain DisputeGameFactory.gameArgs(9); "
                "remove --offline or pass --override cannonKonaPrestate=0x..."
            )
        if not task_files.readme_context.get("anchor_root_overridden"):
            first_chain = _first_chain_by_lexicographic_chain_id(devnet)
            raise AdapterError(
                "startingAnchorRootRoot and startingAnchorRootL2SequenceNumber must be read "
                "from onchain AnchorStateRegistry.getAnchorRoot() for "
                f"{first_chain.name} ({first_chain.chain_id}); remove --offline or pass "
                "both --override startingAnchorRootRoot=0x... and "
                "--override startingAnchorRootL2SequenceNumber=<decimal>"
            )

    def _resolve_initial_anchor_root(self, overrides: dict[str, str]) -> tuple[str, int]:
        has_root = "startingAnchorRootRoot" in overrides
        has_sequence = "startingAnchorRootL2SequenceNumber" in overrides
        if has_root != has_sequence:
            raise AdapterError(
                "startingAnchorRootRoot and startingAnchorRootL2SequenceNumber must be "
                "supplied together, or both omitted to read from onchain"
            )
        if has_root:
            return (
                _resolve_bytes32("startingAnchorRootRoot", overrides),
                self.resolve_uint("startingAnchorRootL2SequenceNumber", overrides),
            )
        return _ZERO_BYTES32, 0


def _first_chain_by_lexicographic_chain_id(devnet: Devnet):
    return min(devnet.chains, key=lambda c: str(c.chain_id))


def _resolve_bytes32(name: str, overrides: dict[str, str]) -> str:
    if name not in overrides:
        raise AdapterError(
            f"{name} has no devnet source; supply via --override {name}=0x..."
        )
    value = overrides[name]
    if not _HEX_BYTES32.match(value):
        raise AdapterError(f"{name} is not a 0x-prefixed 32-byte hash: {value!r}")
    return value


def _resolve_address(name: str, overrides: dict[str, str]) -> str:
    if name not in overrides:
        raise AdapterError(
            f"{name} has no devnet source; supply via --override {name}=0x..."
        )
    return _opcm.clean_address(overrides[name], name)


def _resolve_super_role(
    devnet: Devnet,
    roles_by_chain: dict[int, dict[str, str]],
    overrides: dict[str, str],
    *,
    name: str,
    role: str,
) -> str:
    if name in overrides:
        return _opcm.clean_address(overrides[name], name)
    first_chain = _first_chain_by_lexicographic_chain_id(devnet)
    roles = roles_by_chain.get(first_chain.chain_id, {})
    value = roles.get(role)
    if not value:
        raise AdapterError(
            f"{name} not found in op-deployer/state.json.appliedIntent for "
            f"first chain {first_chain.name} ({first_chain.chain_id}). "
            f"Supply via --override {name}=0x..."
        )
    return _opcm.clean_address(value, name)


def _anchor_root_overridden(overrides: dict[str, str]) -> bool:
    return (
        "startingAnchorRootRoot" in overrides
        and "startingAnchorRootL2SequenceNumber" in overrides
    )


def _resolve_initial_cannon_kona_prestate(
    adapter: OPCMMigrateV800,
    devnet: Devnet,
    overrides: dict[str, str],
) -> str:
    if "cannonKonaPrestate" in overrides:
        return adapter.resolve_prestate(
            _opcm.PrestateSource(
                "cannonKonaPrestate",
                devnet.prestates.cannon_kona,
                "op-program/prestates.json.kona.hash",
            ),
            overrides,
        )
    if devnet.prestates.cannon_kona:
        return adapter.resolve_prestate(
            _opcm.PrestateSource(
                "cannonKonaPrestate",
                devnet.prestates.cannon_kona,
                "op-program/prestates.json.kona.hash",
            ),
            overrides,
        )
    return _ZERO_BYTES32


def _fetch_and_verify_opcm_version(
    rpc_url: str,
    opcm_address: str,
    expected: str,
) -> str:
    try:
        actual = rpc.fetch_opcm_version(rpc_url, opcm_address)
    except rpc.RpcError as exc:
        raise AdapterError(
            f"failed to read OPCM.version() at {opcm_address} via {rpc_url}: {exc}. "
            "Pass --rpc-url to use a different RPC, or --offline to skip the check."
        ) from exc
    if not _opcm.version_matches(actual, expected):
        raise AdapterError(
            f"OPCM at {opcm_address} reports version {actual!r}, expected {expected!r}. "
            "Likely cause: the wrong OPCM address was sourced from the devnet (or the "
            "devnet was redeployed). Pass --override OPCM=0x... to point at the right one."
        )
    return actual


def _fetch_super_cannon_kona_prestate(
    rpc_url: str,
    dispute_game_factory: str,
    *,
    chain_name: str,
    chain_id: int,
    required: bool,
) -> str:
    try:
        impl = _fetch_game_impl(rpc_url, dispute_game_factory, SUPER_CANNON_KONA)
        if impl.lower() == _ZERO_ADDRESS:
            if required:
                raise AdapterError(
                    f"{chain_name} ({chain_id}) has no implementation set for "
                    "SUPER_CANNON_KONA game type 9"
                )
            return _ZERO_BYTES32
        game_args = _fetch_game_args(rpc_url, dispute_game_factory, SUPER_CANNON_KONA)
    except rpc.RpcError as exc:
        raise AdapterError(
            f"failed to read SUPER_CANNON_KONA config from DisputeGameFactory "
            f"{dispute_game_factory} for {chain_name} ({chain_id}) via {rpc_url}: {exc}"
        ) from exc

    if len(game_args) < 32:
        if required:
            raise AdapterError(
                f"{chain_name} ({chain_id}) has no cannonKonaPrestate set in "
                "SUPER_CANNON_KONA gameArgs"
            )
        return _ZERO_BYTES32
    prestate = "0x" + game_args[:32].hex()
    if prestate == _ZERO_BYTES32:
        if required:
            raise AdapterError(
                f"{chain_name} ({chain_id}) has zero cannonKonaPrestate set in "
                "SUPER_CANNON_KONA gameArgs"
            )
        return _ZERO_BYTES32
    return prestate


def _fetch_anchor_root(
    rpc_url: str,
    anchor_state_registry: str,
    *,
    chain_name: str,
    chain_id: int,
) -> tuple[str, int]:
    try:
        raw = rpc.eth_call(rpc_url, anchor_state_registry, _GET_ANCHOR_ROOT_SELECTOR)
        body = _decode_hex(raw, "getAnchorRoot")
    except rpc.RpcError as exc:
        raise AdapterError(
            f"failed to read AnchorStateRegistry.getAnchorRoot() from "
            f"{anchor_state_registry} for {chain_name} ({chain_id}) via {rpc_url}: {exc}"
        ) from exc

    if len(body) < 64:
        raise AdapterError(
            f"{chain_name} ({chain_id}) AnchorStateRegistry.getAnchorRoot() "
            f"response is too short: {raw!r}"
        )
    root = "0x" + body[0:32].hex()
    if root == _ZERO_BYTES32:
        raise AdapterError(
            f"{chain_name} ({chain_id}) AnchorStateRegistry starting anchor root is zero"
        )
    return root, int.from_bytes(body[32:64], "big")


def _fetch_game_impl(rpc_url: str, dispute_game_factory: str, game_type: int) -> str:
    raw = rpc.eth_call(
        rpc_url,
        dispute_game_factory,
        _encode_uint32_call(_GAME_IMPLS_SELECTOR, game_type),
    )
    body = _decode_hex(raw, "gameImpls")
    if len(body) < 32:
        raise rpc.RpcError(f"gameImpls: response too short: {raw!r}")
    return "0x" + body[12:32].hex()


def _fetch_game_args(rpc_url: str, dispute_game_factory: str, game_type: int) -> bytes:
    raw = rpc.eth_call(
        rpc_url,
        dispute_game_factory,
        _encode_uint32_call(_GAME_ARGS_SELECTOR, game_type),
    )
    body = _decode_hex(raw, "gameArgs")
    if len(body) < 64:
        raise rpc.RpcError(f"gameArgs: response too short to be bytes ABI return: {raw!r}")
    offset = int.from_bytes(body[0:32], "big")
    if offset + 32 > len(body):
        raise rpc.RpcError(f"gameArgs: offset {offset} exceeds payload size")
    length = int.from_bytes(body[offset : offset + 32], "big")
    start = offset + 32
    end = start + length
    if end > len(body):
        raise rpc.RpcError(f"gameArgs: declared length {length} exceeds payload size")
    return body[start:end]


def _encode_uint32_call(selector: str, value: int) -> str:
    return selector + value.to_bytes(32, "big").hex()


def _decode_hex(raw: str, name: str) -> bytes:
    if not isinstance(raw, str) or not raw.startswith("0x"):
        raise rpc.RpcError(f"{name}: expected 0x-prefixed hex string, got {raw!r}")
    try:
        return bytes.fromhex(raw[2:])
    except ValueError as exc:
        raise rpc.RpcError(f"{name}: response is not valid hex: {raw!r}") from exc
