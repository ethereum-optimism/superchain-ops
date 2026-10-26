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

/// @notice A template contract for configuring OPCMTaskBase templates.
/// Supports: op-contracts/v9.0.0 (OPContractsManagerV2 9.x)
/// @dev Upgrades chains already on op-contracts/v8 to the v9 release. Runs before the
/// OPCMMigrateV900 task: `migrate` requires every chain to be on the v9 OPCM.
contract OPCMUpgradeV900 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Struct to store inputs data for each L2 chain.
    /// @dev Read field by field in `_loadUpgrade`. `chainId` and `expectedValidationErrors` are
    /// required; `cannonKonaPrestate` is required when SUPER_CANNON_KONA is enabled. `initBond`
    /// and `startingRespectedGameType` default to the chain's live values.
    /// @dev No anchor-root input: the v9 OPCM only permits the `startingRespectedGameType`
    /// override, and chains arriving from v8 already anchor on a super root, which the
    /// upgrade carries forward from the AnchorStateRegistry.
    struct OPCMUpgrade {
        Claim cannonKonaPrestate;
        uint256 chainId;
        string expectedValidationErrors;
        uint256 initBond;
        uint32 startingRespectedGameType;
    }

    /// @notice Pre-upgrade AnchorStateRegistry starting anchor, asserted unchanged in `_validate`.
    struct AnchorSnapshot {
        bytes32 root;
        uint256 l2SequenceNumber;
    }

    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    uint256[] public chainsToUpgrade;
    mapping(uint256 => OPCMUpgrade) public upgrades;
    /// @notice Whether `startingRespectedGameType` differs from the live value, so the override is sent.
    mapping(uint256 => bool) public overridesRespectedGameType;
    mapping(uint256 => AnchorSnapshot) public preUpgradeAnchor;

    IOPContractsManagerV900 public opcm;
    IOPContractsManagerStandardValidator public standardValidator;
    bool public skipOPCMVersionCheck;

    // Game type constants (from GameTypes library in op-contracts v9.0.0).
    // SUPER_CANNON (4) is retired since v8: the OPCM does not accept a config for it.
    uint32 internal constant CANNON = 0;
    uint32 internal constant PERMISSIONED_CANNON = 1;
    uint32 internal constant SUPER_PERMISSIONED = 5;
    uint32 internal constant CANNON_KONA = 8;
    uint32 internal constant SUPER_CANNON_KONA = 9;
    uint32 internal constant ZK_DISPUTE_GAME = 10;

    /// @notice SystemConfig feature flag for the ETHLockbox (`Features.ETH_LOCKBOX`).
    bytes32 internal constant ETH_LOCKBOX_FEATURE = "ETH_LOCKBOX";

    /// @notice Names in the SuperchainAddressRegistry that are expected to be written during this task.
    /// @dev ProtocolVersions is absent: op-contracts/v8.0.0 removed the ProtocolVersions
    /// contract and its OPCM integration. SuperchainConfig is resolved per chain in
    /// `_setAllowedStorageAccesses` instead of through the generic registry lookup.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](12);
        storageWrites[0] = "DisputeGameFactoryProxy";
        storageWrites[1] = "SystemConfigProxy";
        storageWrites[2] = "OptimismPortalProxy";
        storageWrites[3] = "OptimismMintableERC20FactoryProxy";
        storageWrites[4] = "AddressManager";
        storageWrites[5] = "L1StandardBridgeProxy";
        storageWrites[6] = "L1ERC721BridgeProxy";
        storageWrites[7] = "L1CrossDomainMessengerProxy";
        storageWrites[8] = "AnchorStateRegistryProxy";
        storageWrites[9] = "PermissionedWETH";
        storageWrites[10] = "PermissionlessWETH";
        storageWrites[11] = "EthLockboxProxy";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Allowlist storage writes for the upgrade.
    /// @dev `SuperchainConfig` is resolved separately because the base implementation checks
    /// global or sentinel addresses before per-chain discovery. Add only each configured chain's
    /// discovered `SuperchainConfig`.
    function _setAllowedStorageAccesses() internal virtual override {
        super._setAllowedStorageAccesses();
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            _allowedStorageAccesses.add(superchainAddrRegistry.getAddress("SuperchainConfig", chains[i].chainId));
        }
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in
    /// this function.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        require(chains.length > 0, "OPCMUpgradeV900: no chains configured");

        // Load upgrades from TOML
        require(
            !tomlContent.keyExists(string.concat(".opcmUpgrades[", vm.toString(chains.length), "]")),
            "OPCMUpgradeV900: opcmUpgrades length mismatch"
        );
        for (uint256 i = 0; i < chains.length; i++) {
            _loadUpgrade(tomlContent, i);
        }

        address superchainConfig = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        require(superchainConfig != address(0), "OPCMUpgradeV900: SuperchainConfig not found");
        require(superchainConfig.code.length > 0, "OPCMUpgradeV900: SuperchainConfig has no code");
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV900: config not found for chain");
            require(
                superchainAddrRegistry.getAddress("SuperchainConfig", chainId) == superchainConfig,
                "OPCMUpgradeV900: all chains must share the same SuperchainConfig"
            );
        }

        // The template does not send `PermittedProxyDeployment=ETHLockbox`, so every chain must
        // already use a lockbox. Otherwise the OPCM would revert, or run `migrateLiquidity()`
        // and move the portal's ETH. Onchain discovery registers EthLockboxProxy from
        // `portal.ethLockbox()`, so the storage-write allowlist covers it.
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(
                IOptimismPortalView(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId)).ethLockbox()
                    != address(0),
                "OPCMUpgradeV900: chain has no ETHLockbox"
            );
            require(
                ISystemConfigV900(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)).isFeatureEnabled(
                    ETH_LOCKBOX_FEATURE
                ),
                "OPCMUpgradeV900: ETH_LOCKBOX feature is not enabled"
            );
        }

        // The OPCM gates enabling ZK_DISPUTE_GAME behind a dev feature (disabled on
        // production deployments) and its game args require a full ZKDisputeGameConfig
        // (verifier, durations, challenger bond) that this template does not carry. Fail
        // loudly up front rather than silently disabling a registered game type.
        for (uint256 i = 0; i < chains.length; i++) {
            IDisputeGameFactory factory =
                IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chains[i].chainId));
            require(
                address(factory.gameImpls(GameType.wrap(ZK_DISPUTE_GAME))) == address(0),
                "OPCMUpgradeV900: chains with a registered ZK_DISPUTE_GAME are not supported"
            );
        }

        // OPCM from TOML; must be an op-contracts/v9 OPCM. Any 9.x is accepted: a minor bump is
        // a replacement OPCM for the same upgrade, and isPermittedUpgradeSequence below is the
        // on-chain gate that the chains can step onto this OPCM.
        opcm = IOPContractsManagerV900(tomlContent.readAddress(".addresses.OPCM"));
        OPCM_TARGETS.push(address(opcm));
        require(address(opcm).code.length > 0, "OPCMUpgradeV900: OPCM has no code");
        skipOPCMVersionCheck =
            tomlContent.keyExists(".skipOPCMVersionCheck") && tomlContent.readBool(".skipOPCMVersionCheck");
        if (!skipOPCMVersionCheck) {
            require(opcm.version().startsWith("9."), "OPCMUpgradeV900: incorrect OPCM major version");
            for (uint256 i = 0; i < chains.length; i++) {
                require(
                    opcm.isPermittedUpgradeSequence(
                        ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId))
                    ),
                    "OPCMUpgradeV900: chain is not on the release preceding this OPCM"
                );
            }
        }
        vm.label(address(opcm), "OPCM");

        // Fetch the validator directly from OPCM so it doesn't need to be configured in TOML
        standardValidator = opcm.opcmStandardValidator();
        require(address(standardValidator) != address(0), "OPCM returned zero validator");
        require(address(standardValidator).code.length > 0, "Validator has no code");
        vm.label(address(standardValidator), "OPCMStandardValidator");
    }

    /// @notice Loads `opcmUpgrades[i]` from the TOML, defaulting optional fields to live chain state,
    /// and snapshots the chain's starting anchor for `_validate`.
    function _loadUpgrade(string memory tomlContent, uint256 i) internal {
        string memory p = string.concat(".opcmUpgrades[", vm.toString(i), "]");
        OPCMUpgrade memory u;
        u.chainId = tomlContent.readUint(string.concat(p, ".chainId"));
        require(u.chainId != 0, "OPCMUpgradeV900: chainId cannot be zero");
        require(upgrades[u.chainId].chainId == 0, "OPCMUpgradeV900: duplicate chain config");
        u.expectedValidationErrors = tomlContent.readString(string.concat(p, ".expectedValidationErrors"));

        IDisputeGameFactory factory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", u.chainId));
        IAnchorStateRegistryView asr =
            IAnchorStateRegistryView(superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", u.chainId));

        // The respected game type is carried forward; the override is only sent when the TOML sets
        // a different one, so an upgrade never silently undoes a Guardian change.
        uint32 liveRespected = asr.respectedGameType();
        uint256 respected = tomlContent.readUintOr(string.concat(p, ".startingRespectedGameType"), liveRespected);
        // Base game types (0/1/8) are always disabled and ZK requires a dev-feature-enabled
        // OPCM, so only the two super game types can ever satisfy the OPCM's
        // enabled-respected-game-type check.
        require(
            respected == SUPER_PERMISSIONED || respected == SUPER_CANNON_KONA,
            "OPCMUpgradeV900: startingRespectedGameType must be a super game type (5 or 9)"
        );
        u.startingRespectedGameType = uint32(respected);
        overridesRespectedGameType[u.chainId] = u.startingRespectedGameType != liveRespected;

        // The prestate and bond only apply to SUPER_CANNON_KONA, the one bonded game type.
        if (_isGameTypeEnabled(factory, SUPER_CANNON_KONA, u.startingRespectedGameType)) {
            u.cannonKonaPrestate = Claim.wrap(tomlContent.readBytes32(string.concat(p, ".cannonKonaPrestate")));
            require(Claim.unwrap(u.cannonKonaPrestate) != bytes32(0), "OPCMUpgradeV900: cannonKonaPrestate is zero");
            u.initBond = tomlContent.readUintOr(
                string.concat(p, ".initBond"), factory.initBonds(GameType.wrap(SUPER_CANNON_KONA))
            );
            require(u.initBond != 0, "OPCMUpgradeV900: initBond is zero");
        }

        (bytes32 root, uint256 l2SequenceNumber) = asr.getStartingAnchorRoot();
        require(root != bytes32(0), "OPCMUpgradeV900: starting anchor root is zero");
        preUpgradeAnchor[u.chainId] = AnchorSnapshot({root: root, l2SequenceNumber: l2SequenceNumber});

        chainsToUpgrade.push(u.chainId);
        upgrades[u.chainId] = u;
    }

    /// @notice Returns whether a dispute game should be enabled based on the existing factory state.
    /// @dev ZK_DISPUTE_GAME is never enabled: `_templateSetup` rejects chains with a registered
    /// ZK game, and the OPCM gates enabling it behind a dev feature anyway.
    function _isGameTypeEnabled(IDisputeGameFactory disputeGameFactory, uint32 gt, uint32 startingRespectedGameType)
        internal
        view
        returns (bool)
    {
        if (gt == CANNON) return false;
        if (gt == PERMISSIONED_CANNON) return false;
        if (gt == CANNON_KONA) return false;
        if (gt == startingRespectedGameType) return true;
        if (gt == SUPER_PERMISSIONED) {
            return true;
        }
        if (gt == SUPER_CANNON_KONA) {
            // Carried forward: the v8 upgrade already rotated CANNON_KONA chains onto it.
            return address(disputeGameFactory.gameImpls(GameType.wrap(SUPER_CANNON_KONA))) != address(0);
        }
        return false;
    }

    /// @notice Addresses needed to build game configs for a single chain.
    struct GameConfigAddrs {
        IDisputeGameFactory factory;
        address proposer;
    }

    /// @notice Builds a single DisputeGameConfig entry.
    /// @dev SUPER_PERMISSIONED (gt=5) uses the simplified super game: proposer-only args
    /// (no prestate, no challenger) and the OPCM requires its initBond to be zero.
    /// SUPER_CANNON_KONA (gt=9) is the only other game type this template can enable, so
    /// the Kona prestate is the only prestate ever encoded. The OPCM ignores the game args
    /// of a disabled config, so the retired Cannon game types need no prestate at all.
    function _buildOneGameConfig(
        GameConfigAddrs memory a,
        uint32 gt,
        bytes32 cannonKonaPre,
        uint256 bond,
        uint32 startingRespectedGameType
    ) internal view returns (IOPContractsManagerV900.DisputeGameConfig memory) {
        bool enabled = _isGameTypeEnabled(a.factory, gt, startingRespectedGameType);
        bytes memory gameArgs;
        if (enabled) {
            gameArgs = gt == SUPER_PERMISSIONED ? abi.encode(a.proposer) : abi.encode(cannonKonaPre);
        }
        return IOPContractsManagerV900.DisputeGameConfig({
            enabled: enabled,
            initBond: enabled && gt != SUPER_PERMISSIONED ? bond : 0,
            gameType: gt,
            gameArgs: gameArgs
        });
    }

    /// @notice Builds DisputeGameConfig[] for a chain from registry addresses and the Kona prestate.
    /// @dev The OPCM requires exactly these six game configs, in exactly this order.
    function _buildGameConfigs(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV900.DisputeGameConfig[] memory)
    {
        GameConfigAddrs memory a = GameConfigAddrs({
            factory: IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId)),
            proposer: superchainAddrRegistry.getAddress("Proposer", chainId)
        });

        bytes32 cannonKonaPre = Claim.unwrap(upgrades[chainId].cannonKonaPrestate);
        uint256 bond = upgrades[chainId].initBond;
        uint32 startingRespectedGameType = upgrades[chainId].startingRespectedGameType;

        IOPContractsManagerV900.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV900.DisputeGameConfig[](6);
        uint32[6] memory gts =
            [CANNON, PERMISSIONED_CANNON, CANNON_KONA, SUPER_PERMISSIONED, SUPER_CANNON_KONA, ZK_DISPUTE_GAME];
        for (uint256 i = 0; i < 6; i++) {
            cfgs[i] = _buildOneGameConfig(a, gts[i], cannonKonaPre, bond, startingRespectedGameType);
        }
        return cfgs;
    }

    /// @dev The v9 OPCM permits exactly two upgrade instructions: the
    /// `startingRespectedGameType` override and `PermittedProxyDeployment=ETHLockbox`. The
    /// override is sent only when the configured respected game type differs from the live one;
    /// otherwise the OPCM carries the live value forward. The anchor root is always carried
    /// forward (v9 rejects the `startingAnchorRoot` override). `_templateSetup` requires every
    /// chain to already use an ETHLockbox, so no proxy deployment is permitted.
    function _buildExtraInstructions(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV900.ExtraInstruction[] memory extraInstructions)
    {
        if (!overridesRespectedGameType[chainId]) return new IOPContractsManagerV900.ExtraInstruction[](0);
        extraInstructions = new IOPContractsManagerV900.ExtraInstruction[](1);
        extraInstructions[0] = IOPContractsManagerV900.ExtraInstruction({
            key: "overrides.cfg.startingRespectedGameType",
            data: abi.encode(upgrades[chainId].startingRespectedGameType)
        });
    }

    /// @notice Builds the actions for executing the operations.
    /// @dev OPCMTaskBase uses Multicall3DelegateCall, so calls to OPCM must use delegatecall.
    /// Any state written in this function is discarded after build completes.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        require(chains.length > 0, "OPCMUpgradeV900: no chains configured");

        // Upgrade superchain once (before per-chain upgrades)
        address sc = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        (bool scOk,) = address(opcm).delegatecall(
            abi.encodeCall(
                IOPContractsManagerV900.upgradeSuperchain,
                (
                    IOPContractsManagerV900.SuperchainUpgradeInput({
                        superchainConfig: ISuperchainConfig(sc),
                        extraInstructions: new IOPContractsManagerV900.ExtraInstruction[](0)
                    })
                )
            )
        );
        require(scOk, "OPCMUpgradeV900: upgradeSuperchain delegatecall failed");

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV900: Config not found for chain");

            IOPContractsManagerV900.UpgradeInput memory inp = IOPContractsManagerV900.UpgradeInput({
                systemConfig: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                disputeGameConfigs: _buildGameConfigs(chainId),
                extraInstructions: _buildExtraInstructions(chainId)
            });

            // Delegatecall the OPCM.upgrade() function once per chain
            (bool ok,) =
                address(opcm).delegatecall(abi.encodeWithSelector(IOPContractsManagerV900.upgrade.selector, inp));
            require(ok, "OPCMUpgradeV900: Delegatecall failed in _build.");
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        // Cache standard validator's expected values (same for all chains)
        address standardL1PAO = standardValidator.l1PAOMultisig();
        address standardChallenger = standardValidator.challenger();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;

            // The upgrade re-initializes the AnchorStateRegistry; assert the respected game type
            // is the configured one and the starting anchor is exactly the pre-upgrade one (an
            // unchanged starting anchor also keeps the current anchor game).
            IAnchorStateRegistryView asr =
                IAnchorStateRegistryView(superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId));
            require(
                asr.respectedGameType() == upgrades[chainId].startingRespectedGameType,
                "OPCMUpgradeV900: startingRespectedGameType not applied"
            );
            (bytes32 anchorRoot, uint256 anchorL2SequenceNumber) = asr.getStartingAnchorRoot();
            require(
                anchorRoot == preUpgradeAnchor[chainId].root
                    && anchorL2SequenceNumber == preUpgradeAnchor[chainId].l2SequenceNumber,
                "OPCMUpgradeV900: starting anchor root changed"
            );

            IOPContractsManagerStandardValidator.ValidationInputDev memory input = IOPContractsManagerStandardValidator
                .ValidationInputDev({
                sysCfg: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                // The validator only reads cannonPrestate on its non-super path. This template
                // always leaves the chain respecting a super game type, so the value is unused.
                cannonPrestate: bytes32(0),
                cannonKonaPrestate: Claim.unwrap(upgrades[chainId].cannonKonaPrestate),
                l2ChainID: chainId,
                proposer: superchainAddrRegistry.getAddress("Proposer", chainId)
            });

            // Compute overrides: non-zero only if chain differs from standard. Chains arriving
            // from v8 run super games only, and the super permissioned game carries no
            // challenger, so the registry has no `Challenger` entry for them: no override.
            address l1PAOOverride = superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId);
            address challengerOverride = _tryGetAddress("Challenger", chainId);

            l1PAOOverride = l1PAOOverride != standardL1PAO ? l1PAOOverride : address(0);
            challengerOverride = challengerOverride != standardChallenger ? challengerOverride : address(0);

            string memory errors;
            if (l1PAOOverride != address(0) || challengerOverride != address(0)) {
                errors = standardValidator.validateWithOverrides({
                    _input: input,
                    _allowFailure: true,
                    _overrides: IOPContractsManagerStandardValidator.ValidationOverrides({
                        l1PAOMultisig: l1PAOOverride,
                        challenger: challengerOverride
                    })
                });
            } else {
                errors = standardValidator.validate({_input: input, _allowFailure: true});
            }

            string memory expErrors = upgrades[chainId].expectedValidationErrors;
            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice Registry lookup that returns zero instead of reverting when the entry is absent.
    function _tryGetAddress(string memory name, uint256 chainId) internal view returns (address) {
        try superchainAddrRegistry.getAddress(name, chainId) returns (address found) {
            return found;
        } catch {
            return address(0);
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    /// @dev The upgrade reinitializes SystemConfig, re-writing storage slots whose values are
    /// legitimately EOAs.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address[] memory exceptions = new address[](chains.length * 3);
        uint256 cursor;
        for (uint256 i = 0; i < chains.length; i++) {
            ISystemConfigV900 sysCfg =
                ISystemConfigV900(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId));
            // Only include true, non-zero EOAs (no code). Contract addresses (e.g. multisig
            // owners) must not be in the exceptions list — they are handled by the normal
            // allowed storage accesses check instead — and a zero entry makes
            // `Utils.isLikelyAddressThatShouldHaveCode` revert.
            address[3] memory candidates =
                [sysCfg.owner(), sysCfg.unsafeBlockSigner(), address(uint160(uint256(sysCfg.batcherHash())))];
            for (uint256 j = 0; j < candidates.length; j++) {
                if (candidates[j] != address(0) && candidates[j].code.length == 0) exceptions[cursor++] = candidates[j];
            }
        }
        address[] memory result = new address[](cursor);
        for (uint256 i = 0; i < cursor; i++) {
            result[i] = exceptions[i];
        }
        return result;
    }
}

/* ---------- Interfaces ---------- */
/// @notice OPCM Interface (op-contracts/v9.0.0 OPContractsManagerV2), reduced to what upgrade needs.
interface IOPContractsManagerV900 {
    struct DisputeGameConfig {
        bool enabled;
        uint256 initBond;
        uint32 gameType; // GameType
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

    function isPermittedUpgradeSequence(ISystemConfig _systemConfig) external view returns (bool);

    function upgradeSuperchain(SuperchainUpgradeInput memory _input) external;

    function opcmStandardValidator() external view returns (IOPContractsManagerStandardValidator);
}

/// @notice Validator interface for validateWithOverrides usage.
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
    function l1PAOMultisig() external view returns (address);
    function challenger() external view returns (address);
    function validateWithOverrides(
        ValidationInputDev memory _input,
        bool _allowFailure,
        ValidationOverrides memory _overrides
    ) external view returns (string memory);

    function version() external view returns (string memory);
}

interface ISuperchainConfig {}

interface IDisputeGameFactory {
    function gameImpls(GameType gameType) external view returns (address);
    function initBonds(GameType gameType) external view returns (uint256);
}

interface IOptimismPortalView {
    function ethLockbox() external view returns (address);
}

/// @notice Read-only AnchorStateRegistry accessors. `getStartingAnchorRoot` returns a
/// `Proposal` struct, which ABI-decodes as its two fields.
interface IAnchorStateRegistryView {
    function getStartingAnchorRoot() external view returns (bytes32 root, uint256 l2SequenceNumber);
    function respectedGameType() external view returns (uint32);
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

/// @notice Read-only SystemConfig accessors used by `_templateSetup` and `_getCodeExceptions`.
interface ISystemConfigV900 {
    function owner() external view returns (address);
    function unsafeBlockSigner() external view returns (address);
    function batcherHash() external view returns (bytes32);
    function isFeatureEnabled(bytes32 _feature) external view returns (bool);
}
