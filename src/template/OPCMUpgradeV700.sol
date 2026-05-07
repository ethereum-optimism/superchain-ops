// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim, GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice U19 OPCM upgrade template targeting op-contracts/v7.1.17.
///
/// Chain-agnostic: works for permissioned-only chains (only PERMISSIONED_CANNON live,
/// e.g. u19 betanets), permissionless chains (CANNON / SUPER_CANNON live, e.g. OP
/// Sepolia post-superroot), or both. Each `SUPER_*` variant in the post-upgrade
/// `DisputeGameConfig[]` is enabled iff its pre-super counterpart is currently
/// registered in the chain's `DisputeGameFactory`; the rest stay disabled. The example
/// task at `test/tasks/example/sep/037-opcm-upgrade-v700` exercises the permissioned-
/// only path on u19-beta-0.
///
/// V7.1.x is the "OPCMv2" architecture: the upgrade path is split in two.
///   1. `upgradeSuperchain(SuperchainUpgradeInput)` is called once and bumps the shared
///      SuperchainConfig + ProtocolVersions state.
///   2. `upgrade(UpgradeInput)` is called once per L2 and rewires SystemConfig, the
///      dispute game stack (seven game-type slots), and registers the EthLockbox.
/// Both calls are delegated through Multicall3DelegateCall by `OPCMTaskBase`.
///
/// Designed to work with chains that are NOT in the public superchain-registry.
/// Such chains (e.g. u19 betanets) supply addresses via `fallbackAddressesJsonPath` in
/// the task TOML — `SuperchainAddressRegistry` reads that file when a chain is missing
/// from `lib/superchain-registry/.../addresses.json`. The template makes no
/// assumptions about which JSON the addresses come from.
///
/// Per-chain config is decoded from `[[opcmUpgrades]]` rows. Solidity's `abi.decode`
/// on `parseRaw` requires the struct fields to be in alphabetical order — that is the
/// only reason `OPCMUpgrade` looks the way it does.
contract OPCMUpgradeV700 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Per-chain inputs.
    /// @dev Field order MUST be alphabetical (forge-std TOML decoder constraint).
    struct OPCMUpgrade {
        Claim cannonKonaPrestate;
        Claim cannonPrestate;
        uint256 chainId;
        string expectedValidationErrors;
        uint256 initBond;
        uint32 startingRespectedGameType;
    }

    /// @notice chainId => parsed config.
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice The OPCM we delegatecall into. Loaded from `[addresses].OPCM`.
    /// Must satisfy `version() == "7.1.17"`.
    IOPContractsManagerV700 public OPCM;

    /// @notice Standard validator returned by the OPCM. Used post-upgrade to assert each
    /// chain's state matches the v7.1.x standard, with role overrides for non-standard
    /// L1ProxyAdminOwner / Challenger (typical on betanets).
    IOPContractsManagerStandardValidator public STANDARD_VALIDATOR;

    /* ---------- GameType constants (op-contracts/v7.1.x GameTypes.sol) ---------- */
    uint32 internal constant CANNON = 0;
    uint32 internal constant PERMISSIONED_CANNON = 1;
    uint32 internal constant SUPER_CANNON = 4;
    uint32 internal constant SUPER_PERMISSIONED_CANNON = 5;
    uint32 internal constant CANNON_KONA = 8;
    uint32 internal constant SUPER_CANNON_KONA = 9;
    uint32 internal constant ZK_DISPUTE_GAME = 10;

    /// @notice Registry identifiers expected to receive storage writes during the task.
    /// Used by the OPCMTaskBase / L2TaskBase parent for state-diff assertions.
    /// @dev `PermissionlessWETH` is intentionally absent: this template targets the U19
    /// upgrade path on permissioned-only chains. Add it back if a permissionless-enabled
    /// chain is included.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory writes = new string[](14);
        writes[0] = "SuperchainConfig";
        writes[1] = "ProtocolVersions";
        writes[2] = "DisputeGameFactoryProxy";
        writes[3] = "SystemConfigProxy";
        writes[4] = "OptimismPortalProxy";
        writes[5] = "OptimismMintableERC20FactoryProxy";
        writes[6] = "AddressManager";
        writes[7] = "L1StandardBridgeProxy";
        writes[8] = "L1ERC721BridgeProxy";
        writes[9] = "L1CrossDomainMessengerProxy";
        writes[10] = "ProxyAdminOwner";
        writes[11] = "AnchorStateRegistryProxy";
        writes[12] = "PermissionedWETH";
        writes[13] = "EthLockboxProxy";
        return writes;
    }

    /// @notice No balance changes expected.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Allowlist storage writes for the upgrade.
    /// @dev L2TaskBase's default `_setAllowedStorageAccesses` calls `addrRegistry.get(key)`
    /// before falling back to per-chain `getAddress(key, chainId)`. For shared identifiers
    /// like "SuperchainConfig" and "ProtocolVersions", `get(key)` resolves against the
    /// sentinel-chain entries hardcoded in `src/addresses.toml` (the OP Sepolia / mainnet
    /// values), so the betanet-specific addresses never make it into the allowlist. We
    /// re-add them explicitly per chain after super runs so betanet upgrades pass the
    /// post-execution storage-access check.
    function _setAllowedStorageAccesses() internal virtual override {
        super._setAllowedStorageAccesses();
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            _allowedStorageAccesses.add(superchainAddrRegistry.getAddress("SuperchainConfig", chains[i].chainId));
            _allowedStorageAccesses.add(superchainAddrRegistry.getAddress("ProtocolVersions", chains[i].chainId));
        }
    }

    /// @notice Parse TOML, validate, and resolve OPCM + validator.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);

        string memory toml = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        require(chains.length > 0, "OPCMUpgradeV700: no chains configured");

        // Decode `[[opcmUpgrades]]` rows.
        OPCMUpgrade[] memory parsed = abi.decode(toml.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        require(parsed.length == chains.length, "OPCMUpgradeV700: opcmUpgrades length mismatch");
        for (uint256 i = 0; i < parsed.length; i++) {
            require(parsed[i].chainId != 0, "OPCMUpgradeV700: chainId zero");
            require(upgrades[parsed[i].chainId].chainId == 0, "OPCMUpgradeV700: duplicate chain config");
            require(Claim.unwrap(parsed[i].cannonPrestate) != bytes32(0), "OPCMUpgradeV700: cannonPrestate zero");
            require(
                Claim.unwrap(parsed[i].cannonKonaPrestate) != bytes32(0), "OPCMUpgradeV700: cannonKonaPrestate zero"
            );
            upgrades[parsed[i].chainId] = parsed[i];
        }

        // upgradeSuperchain() runs once and rewrites the shared SuperchainConfig — every
        // L2 in this task must therefore point at the same SuperchainConfig instance.
        address sharedSC = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        require(sharedSC != address(0), "OPCMUpgradeV700: SuperchainConfig not registered");
        require(sharedSC.code.length > 0, "OPCMUpgradeV700: SuperchainConfig has no code");
        for (uint256 i = 1; i < chains.length; i++) {
            require(
                superchainAddrRegistry.getAddress("SuperchainConfig", chains[i].chainId) == sharedSC,
                "OPCMUpgradeV700: chains do not share SuperchainConfig"
            );
        }

        // Resolve OPCM and verify version. Strict on "7.1.17" — bump deliberately when
        // moving to a newer patch so reviewers see the version delta in the diff.
        OPCM = IOPContractsManagerV700(toml.readAddress(".addresses.OPCM"));
        OPCM_TARGETS.push(address(OPCM));
        require(OPCM.version().eq("7.1.17"), "OPCMUpgradeV700: OPCM is not v7.1.17");
        vm.label(address(OPCM), "OPCM");

        // Validator is exposed by the OPCM; no need to plumb it through TOML.
        STANDARD_VALIDATOR = OPCM.opcmStandardValidator();
        require(address(STANDARD_VALIDATOR) != address(0), "OPCMUpgradeV700: validator zero");
        require(address(STANDARD_VALIDATOR).code.length > 0, "OPCMUpgradeV700: validator has no code");
        vm.label(address(STANDARD_VALIDATOR), "OPCMStandardValidator");
    }

    /* ---------- DisputeGameConfig builders ---------- */

    /// @notice Should the OPCM enable / re-init `gt` for `factory`?
    /// @dev Pre-superroot game types (CANNON / PERMISSIONED_CANNON / CANNON_KONA) are
    /// never re-enabled — they are deprecated in favour of their SUPER_* variants. Each
    /// SUPER_* variant is enabled iff its pre-super counterpart is currently registered
    /// in the factory; that lets the same template upgrade permissioned-only chains
    /// (only SUPER_PERMISSIONED_CANNON enabled) and permissionless chains (also
    /// SUPER_CANNON / SUPER_CANNON_KONA, depending on what's live). ZK_DISPUTE_GAME stays
    /// disabled — the OPCM gates it behind a dev feature flag and U19 doesn't ship a ZK
    /// prestate.
    function _isEnabled(IDisputeGameFactory factory, uint32 gt) internal view returns (bool) {
        if (gt == SUPER_CANNON) return address(factory.gameImpls(GameType.wrap(CANNON))) != address(0);
        if (gt == SUPER_PERMISSIONED_CANNON) {
            return address(factory.gameImpls(GameType.wrap(PERMISSIONED_CANNON))) != address(0);
        }
        if (gt == SUPER_CANNON_KONA) return address(factory.gameImpls(GameType.wrap(CANNON_KONA))) != address(0);
        return false;
    }

    /// @notice Pack one DisputeGameConfig row.
    function _gameConfig(
        IDisputeGameFactory factory,
        address proposer,
        address challenger,
        uint32 gt,
        bytes32 cannonPre,
        bytes32 cannonKonaPre,
        uint256 bond
    ) internal view returns (IOPContractsManagerV700.DisputeGameConfig memory) {
        bool enabled = _isEnabled(factory, gt);
        bytes memory args;
        if (enabled) {
            bytes32 prestate = (gt == CANNON_KONA || gt == SUPER_CANNON_KONA) ? cannonKonaPre : cannonPre;
            bool permissioned = (gt == PERMISSIONED_CANNON || gt == SUPER_PERMISSIONED_CANNON);
            args = permissioned ? abi.encode(prestate, proposer, challenger) : abi.encode(prestate);
        }
        return IOPContractsManagerV700.DisputeGameConfig({
            enabled: enabled,
            initBond: enabled ? bond : 0,
            gameType: gt,
            gameArgs: args
        });
    }

    /// @notice Build the 6-row DisputeGameConfig array for one chain.
    function _gameConfigs(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV700.DisputeGameConfig[] memory configs)
    {
        IDisputeGameFactory factory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));
        address proposer = superchainAddrRegistry.getAddress("Proposer", chainId);
        address challenger = superchainAddrRegistry.getAddress("Challenger", chainId);

        bytes32 cannonPre = Claim.unwrap(upgrades[chainId].cannonPrestate);
        bytes32 cannonKonaPre = Claim.unwrap(upgrades[chainId].cannonKonaPrestate);
        uint256 bond = upgrades[chainId].initBond;

        // The v7.x OPCM requires EXACTLY 7 configs in this exact insertion order — not
        // numeric ascending — and a 7-element validGameTypes array literal in
        // OPContractsManagerV2.sol drives the equality check. Any deviation reverts with
        // OPContractsManagerV2_InvalidGameConfigs:
        //   [CANNON, PERMISSIONED_CANNON, CANNON_KONA, SUPER_CANNON,
        //    SUPER_PERMISSIONED_CANNON, SUPER_CANNON_KONA, ZK_DISPUTE_GAME].
        uint32[7] memory gts = [
            CANNON,
            PERMISSIONED_CANNON,
            CANNON_KONA,
            SUPER_CANNON,
            SUPER_PERMISSIONED_CANNON,
            SUPER_CANNON_KONA,
            ZK_DISPUTE_GAME
        ];
        configs = new IOPContractsManagerV700.DisputeGameConfig[](7);
        for (uint256 i = 0; i < 7; i++) {
            configs[i] = _gameConfig(factory, proposer, challenger, gts[i], cannonPre, cannonKonaPre, bond);
        }
    }

    /// @notice Build the per-chain ExtraInstruction array.
    /// @dev v7.1.x recognises:
    ///   - "PermittedProxyDeployment": the OPCM may deploy this proxy (DelayedWETH).
    ///   - "overrides.cfg.startingRespectedGameType": abi.encode(uint32) override for
    ///     AnchorStateRegistry.startingRespectedGameType. Defaults to SUPER_CANNON_KONA
    ///     (9) if unset; permissioned-only chains typically pass SUPER_PERMISSIONED_CANNON
    ///     (5) instead.
    function _extraInstructions(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV700.ExtraInstruction[] memory ix)
    {
        ix = new IOPContractsManagerV700.ExtraInstruction[](2);
        ix[0] = IOPContractsManagerV700.ExtraInstruction({key: "PermittedProxyDeployment", data: bytes("DelayedWETH")});
        ix[1] = IOPContractsManagerV700.ExtraInstruction({
            key: "overrides.cfg.startingRespectedGameType",
            data: abi.encode(upgrades[chainId].startingRespectedGameType)
        });
    }

    /* ---------- Build / Validate ---------- */

    /// @notice Sequence: one upgradeSuperchain, then one upgrade per L2.
    /// @dev OPCMTaskBase routes both delegatecalls through Multicall3DelegateCall, so
    /// `address(OPCM).delegatecall(...)` runs in the rootSafe's context.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address sharedSC = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);

        (bool scOk,) = address(OPCM).delegatecall(
            abi.encodeCall(
                IOPContractsManagerV700.upgradeSuperchain,
                IOPContractsManagerV700.SuperchainUpgradeInput({
                    superchainConfig: ISuperchainConfig(sharedSC),
                    extraInstructions: new IOPContractsManagerV700.ExtraInstruction[](0)
                })
            )
        );
        require(scOk, "OPCMUpgradeV700: upgradeSuperchain failed");

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV700: missing config for chain");

            IOPContractsManagerV700.UpgradeInput memory inp = IOPContractsManagerV700.UpgradeInput({
                systemConfig: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                disputeGameConfigs: _gameConfigs(chainId),
                extraInstructions: _extraInstructions(chainId)
            });

            (bool ok,) =
                address(OPCM).delegatecall(abi.encodeWithSelector(IOPContractsManagerV700.upgrade.selector, inp));
            require(ok, string.concat("OPCMUpgradeV700: upgrade failed for chain ", vm.toString(chainId)));
        }
    }

    /// @notice Run the standard validator post-upgrade with optional role overrides.
    /// @dev Betanets typically run with non-standard L1ProxyAdminOwner / Challenger; we
    /// substitute their values into the validator only when they differ from the
    /// validator's hardcoded standard, which keeps the expected-error string stable
    /// across networks that do match the standard.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address standardL1PAO = STANDARD_VALIDATOR.l1PAOMultisig();
        address standardChallenger = STANDARD_VALIDATOR.challenger();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;

            IOPContractsManagerStandardValidator.ValidationInputDev memory input = IOPContractsManagerStandardValidator
                .ValidationInputDev({
                sysCfg: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                cannonPrestate: Claim.unwrap(upgrades[chainId].cannonPrestate),
                cannonKonaPrestate: Claim.unwrap(upgrades[chainId].cannonKonaPrestate),
                l2ChainID: chainId,
                proposer: superchainAddrRegistry.getAddress("Proposer", chainId)
            });

            address chainL1PAO = superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId);
            address chainChallenger = superchainAddrRegistry.getAddress("Challenger", chainId);
            address l1PAOOverride = chainL1PAO == standardL1PAO ? address(0) : chainL1PAO;
            address challengerOverride = chainChallenger == standardChallenger ? address(0) : chainChallenger;

            string memory errors;
            if (l1PAOOverride != address(0) || challengerOverride != address(0)) {
                errors = STANDARD_VALIDATOR.validateWithOverrides({
                    _input: input,
                    _allowFailure: true,
                    _overrides: IOPContractsManagerStandardValidator.ValidationOverrides({
                        l1PAOMultisig: l1PAOOverride,
                        challenger: challengerOverride
                    })
                });
            } else {
                errors = STANDARD_VALIDATOR.validate({_input: input, _allowFailure: true});
            }

            string memory expected = upgrades[chainId].expectedValidationErrors;
            require(errors.eq(expected), string.concat("Unexpected errors: ", errors, "; expected: ", expected));
        }
    }

    /// @notice Code-length exceptions for storage values written by the upgrade.
    /// @dev v7.1.x reinitializes SystemConfig and rewrites the slots that hold
    /// `owner`, `unsafeBlockSigner`, `batchInbox`, and the address derived from
    /// `batcherHash`. On betanets these are typically EOAs, not contracts, so the
    /// post-execution `Likely address in storage has no code` check would reject the
    /// writes. We skip the check for these specific values per chain.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address[] memory exceptions = new address[](chains.length * 4);
        uint256 cursor;
        for (uint256 i = 0; i < chains.length; i++) {
            ISystemConfigEOAs sc =
                ISystemConfigEOAs(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId));
            exceptions[cursor++] = sc.owner();
            exceptions[cursor++] = sc.unsafeBlockSigner();
            exceptions[cursor++] = sc.batchInbox();
            exceptions[cursor++] = address(uint160(uint256(sc.batcherHash())));
        }
        return exceptions;
    }
}

/// @notice Read-only SystemConfig accessors used to populate `_getCodeExceptions`.
interface ISystemConfigEOAs {
    function owner() external view returns (address);
    function unsafeBlockSigner() external view returns (address);
    function batchInbox() external view returns (address);
    function batcherHash() external view returns (bytes32);
}

/* ---------- v7.1.x interfaces ("OPCMv2") ---------- */

interface IOPContractsManagerV700 {
    struct DisputeGameConfig {
        bool enabled;
        uint256 initBond;
        uint32 gameType;
        bytes gameArgs;
    }

    struct ExtraInstruction {
        string key;
        bytes data;
    }

    struct SuperchainUpgradeInput {
        ISuperchainConfig superchainConfig;
        ExtraInstruction[] extraInstructions;
    }

    struct UpgradeInput {
        ISystemConfig systemConfig;
        DisputeGameConfig[] disputeGameConfigs;
        ExtraInstruction[] extraInstructions;
    }

    function version() external view returns (string memory);
    function upgrade(UpgradeInput memory _inp) external;
    function upgradeSuperchain(SuperchainUpgradeInput memory _input) external;
    function opcmStandardValidator() external view returns (IOPContractsManagerStandardValidator);
}

interface IOPContractsManagerStandardValidator {
    struct ValidationInputDev {
        ISystemConfig sysCfg;
        bytes32 cannonPrestate;
        bytes32 cannonKonaPrestate;
        uint256 l2ChainID;
        address proposer;
    }

    struct ValidationOverrides {
        address l1PAOMultisig;
        address challenger;
    }

    function validate(ValidationInputDev memory _input, bool _allowFailure) external view returns (string memory);
    function validateWithOverrides(
        ValidationInputDev memory _input,
        bool _allowFailure,
        ValidationOverrides memory _overrides
    ) external view returns (string memory);
    function l1PAOMultisig() external view returns (address);
    function challenger() external view returns (address);
    function version() external view returns (string memory);
}

interface ISuperchainConfig {}

interface IDisputeGameFactory {
    function gameImpls(GameType gameType) external view returns (address);
}

interface ISystemConfig {
    struct Addresses {
        address l1CrossDomainMessenger;
        address l1ERC721Bridge;
        address l1StandardBridge;
        address optimismPortal;
        address optimismMintableERC20Factory;
        address delayedWETH;
        address opcm;
    }

    function getAddresses() external view returns (Addresses memory);
}
