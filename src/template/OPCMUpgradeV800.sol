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
/// Supports: op-contracts/v8.0.0-rc.2
contract OPCMUpgradeV800 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Struct to store inputs data for each L2 chain.
    /// @dev Fields must remain in alphabetical order for TOML decoding.
    /// @dev `startingAnchorRootRoot` / `startingAnchorRootL2SequenceNumber` are the honest
    /// super root (and its timestamp) the chain's AnchorStateRegistry is re-anchored to.
    /// Rotating a chain from an output-root game to a super-root game MUST supply a super
    /// root here — the pre-upgrade anchor is an output root at an L2 block number, which is
    /// meaningless to super-root games.
    struct OPCMUpgrade {
        Claim cannonKonaPrestate;
        Claim cannonPrestate;
        uint256 chainId;
        uint256 initBond;
        uint256 startingAnchorRootL2SequenceNumber;
        bytes32 startingAnchorRootRoot;
        uint32 startingRespectedGameType;
    }

    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    uint256[] public chainsToUpgrade;
    mapping(uint256 => OPCMUpgrade) public upgrades;
    mapping(uint256 => bool) public konaGameWasRegistered;

    IOPContractsManagerV800 public opcm;
    IOPContractsManagerStandardValidator public standardValidator;

    // Game type constants (from GameTypes library in op-contracts v8.0.0-rc.2).
    // SUPER_CANNON (4) is retired: the v8 OPCM does not accept a config for it and
    // unconditionally clears its DisputeGameFactory registration during upgrade.
    uint32 internal constant CANNON = 0;
    uint32 internal constant PERMISSIONED_CANNON = 1;
    uint32 internal constant SUPER_PERMISSIONED = 5;
    uint32 internal constant CANNON_KONA = 8;
    uint32 internal constant SUPER_CANNON_KONA = 9;
    uint32 internal constant ZK_DISPUTE_GAME = 10;

    /// @notice Names in the SuperchainAddressRegistry that are expected to be written during this task.
    /// @dev ProtocolVersions is absent: op-contracts/v8.0.0 removed the ProtocolVersions
    /// contract and its OPCM integration, so the upgrade no longer writes to it.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](14);
        storageWrites[0] = "SuperchainConfig";
        storageWrites[1] = "DisputeGameFactoryProxy";
        storageWrites[2] = "SystemConfigProxy";
        storageWrites[3] = "OptimismPortalProxy";
        storageWrites[4] = "OptimismMintableERC20FactoryProxy";
        storageWrites[5] = "AddressManager";
        storageWrites[6] = "L1StandardBridgeProxy";
        storageWrites[7] = "L1ERC721BridgeProxy";
        storageWrites[8] = "L1CrossDomainMessengerProxy";
        storageWrites[9] = "ProxyAdminOwner";
        storageWrites[10] = "AnchorStateRegistryProxy";
        storageWrites[11] = "PermissionedWETH";
        storageWrites[12] = "PermissionlessWETH";
        storageWrites[13] = "EthLockboxProxy";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Allowlist storage writes for the upgrade.
    /// @dev L2TaskBase's default `_setAllowedStorageAccesses` calls `addrRegistry.get(key)`
    /// before falling back to per-chain `getAddress(key, chainId)`. For shared identifiers
    /// like `SuperchainConfig`, `get(key)` resolves against the sentinel-chain entries
    /// hardcoded in `src/addresses.toml` (the OP Sepolia / mainnet values), so
    /// devnet-specific addresses never make it into the allowlist. We re-add
    /// them explicitly per chain so devnet upgrades pass the post-execution check.
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

        require(chains.length > 0, "OPCMUpgradeV800: no chains configured");

        // Load upgrades from TOML
        OPCMUpgrade[] memory _upgrades = _parseUpgrades(tomlContent);
        require(_upgrades.length == chains.length, "OPCMUpgradeV800: opcmUpgrades length mismatch");
        for (uint256 i = 0; i < _upgrades.length; i++) {
            require(_upgrades[i].chainId != 0, "OPCMUpgradeV800: chainId cannot be zero");
            require(upgrades[_upgrades[i].chainId].chainId == 0, "OPCMUpgradeV800: duplicate chain config");
            require(Claim.unwrap(_upgrades[i].cannonPrestate) != bytes32(0), "OPCMUpgradeV800: cannonPrestate is zero");
            require(
                Claim.unwrap(_upgrades[i].cannonKonaPrestate) != bytes32(0),
                "OPCMUpgradeV800: cannonKonaPrestate is zero"
            );
            // The v8 upgrade rotates chains onto super-root games: base game types (0/1/8) are
            // always disabled and ZK requires a dev-feature-enabled OPCM, so only the two super
            // game types can ever satisfy the OPCM's enabled-respected-game-type check.
            require(
                _upgrades[i].startingRespectedGameType == SUPER_PERMISSIONED
                    || _upgrades[i].startingRespectedGameType == SUPER_CANNON_KONA,
                "OPCMUpgradeV800: startingRespectedGameType must be a super game type (5 or 9)"
            );
            require(
                _upgrades[i].startingAnchorRootRoot != bytes32(0), "OPCMUpgradeV800: startingAnchorRootRoot is zero"
            );
            require(
                _upgrades[i].startingAnchorRootL2SequenceNumber < type(uint64).max,
                "OPCMUpgradeV800: startingAnchorRootL2SequenceNumber must leave room for a uint64 successor"
            );
            chainsToUpgrade.push(_upgrades[i].chainId);
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        address superchainConfig = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        require(superchainConfig != address(0), "OPCMUpgradeV800: SuperchainConfig not found");
        require(superchainConfig.code.length > 0, "OPCMUpgradeV800: SuperchainConfig has no code");
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV800: config not found for chain");
            require(
                superchainAddrRegistry.getAddress("SuperchainConfig", chainId) == superchainConfig,
                "OPCMUpgradeV800: all chains must share the same SuperchainConfig"
            );
            _validateContractRelationships(
                superchainAddrRegistry.getAddress("SystemConfigProxy", chainId),
                superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId),
                superchainConfig,
                superchainAddrRegistry.getAddress("ProxyAdmin", chainId),
                superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId),
                superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId),
                rootSafe
            );
        }

        // Register EthLockboxProxy for each chain. The V800 upgrade writes to EthLockboxProxy
        // storage. Onchain discovery already registers it via `portal.ethLockbox()` for chains
        // whose portal has a wired lockbox; `saveAddress` reverts on duplicate keys, so only
        // fall back to the superchain-registry addresses.json when discovery found nothing.
        string memory addrJson = vm.readFile(superchainAddrRegistry.SUPERCHAIN_REGISTRY_ADDRESSES_PATH());
        for (uint256 i = 0; i < chains.length; i++) {
            try superchainAddrRegistry.getAddress("EthLockboxProxy", chains[i].chainId) returns (address) {
                continue;
            } catch {}
            string memory key = string.concat("$.", vm.toString(chains[i].chainId), ".EthLockboxProxy");
            if (vm.keyExistsJson(addrJson, key)) {
                address ethLockbox = vm.parseJsonAddress(addrJson, key);
                superchainAddrRegistry.saveAddress("EthLockboxProxy", chains[i], ethLockbox);
                vm.label(ethLockbox, "EthLockboxProxy");
            }
        }

        // The v8 OPCM gates enabling ZK_DISPUTE_GAME behind a dev feature (disabled on
        // production deployments) and its game args require a full ZKDisputeGameConfig
        // (verifier, durations, challenger bond) that this template does not carry. Fail
        // loudly up front rather than silently disabling a registered game type.
        for (uint256 i = 0; i < chains.length; i++) {
            IDisputeGameFactory factory =
                IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chains[i].chainId));
            konaGameWasRegistered[chains[i].chainId] =
                address(factory.gameImpls(GameType.wrap(CANNON_KONA))) != address(0);
            require(
                address(factory.gameImpls(GameType.wrap(ZK_DISPUTE_GAME))) == address(0),
                "OPCMUpgradeV800: chains with a registered ZK_DISPUTE_GAME are not supported"
            );
        }

        // OPCM from TOML; must be the op-contracts/v8.0.0 release (version 8.0.x).
        opcm = IOPContractsManagerV800(tomlContent.readAddress(".addresses.OPCM"));
        OPCM_TARGETS.push(address(opcm));
        require(opcm.version().startsWith("8.0."), "Incorrect OPCM major/minor version");
        vm.label(address(opcm), "OPCM");

        // Fetch the validator directly from OPCM so it doesn't need to be configured in TOML
        standardValidator = opcm.opcmStandardValidator();
        require(address(standardValidator) != address(0), "OPCM returned zero validator");
        require(address(standardValidator).code.length > 0, "Validator has no code");
        vm.label(address(standardValidator), "OPCMStandardValidator");
    }

    /// @notice Parses only fields consumed by this template so legacy TOML fields are harmless.
    function _parseUpgrades(string memory toml) internal view returns (OPCMUpgrade[] memory parsed) {
        uint256 count;
        while (toml.keyExists(string.concat(".opcmUpgrades[", vm.toString(count), "].chainId"))) {
            count++;
        }

        parsed = new OPCMUpgrade[](count);
        for (uint256 i = 0; i < count; i++) {
            string memory base = string.concat(".opcmUpgrades[", vm.toString(i), "]");
            uint256 startingRespectedGameType = toml.readUint(string.concat(base, ".startingRespectedGameType"));
            require(
                startingRespectedGameType <= type(uint32).max,
                "OPCMUpgradeV800: startingRespectedGameType exceeds uint32"
            );
            parsed[i] = OPCMUpgrade({
                cannonKonaPrestate: Claim.wrap(toml.readBytes32(string.concat(base, ".cannonKonaPrestate"))),
                cannonPrestate: Claim.wrap(toml.readBytes32(string.concat(base, ".cannonPrestate"))),
                chainId: toml.readUint(string.concat(base, ".chainId")),
                initBond: toml.readUint(string.concat(base, ".initBond")),
                startingAnchorRootL2SequenceNumber: toml.readUint(
                    string.concat(base, ".startingAnchorRootL2SequenceNumber")
                ),
                startingAnchorRootRoot: toml.readBytes32(string.concat(base, ".startingAnchorRootRoot")),
                startingRespectedGameType: uint32(startingRespectedGameType)
            });
        }
    }

    /// @notice Ensures registry inputs describe contracts controlled by the task's signing Safe.
    function _validateContractRelationships(
        address systemConfig,
        address optimismPortal,
        address superchainConfig,
        address proxyAdmin,
        address proxyAdminOwner,
        address disputeGameFactory,
        address rootSafe
    ) internal view {
        require(systemConfig != address(0), "OPCMUpgradeV800: SystemConfig is zero address");
        require(optimismPortal != address(0), "OPCMUpgradeV800: OptimismPortal is zero address");
        require(superchainConfig != address(0), "OPCMUpgradeV800: SuperchainConfig is zero address");
        require(proxyAdmin != address(0), "OPCMUpgradeV800: ProxyAdmin is zero address");
        require(proxyAdminOwner != address(0), "OPCMUpgradeV800: ProxyAdminOwner is zero address");
        require(disputeGameFactory != address(0), "OPCMUpgradeV800: DisputeGameFactory is zero address");
        require(rootSafe == proxyAdminOwner, "OPCMUpgradeV800: rootSafe is not ProxyAdminOwner");
        require(rootSafe.code.length > 0, "OPCMUpgradeV800: rootSafe has no code");
        require(IGnosisSafeView(rootSafe).getOwners().length > 0, "OPCMUpgradeV800: rootSafe has no owners");

        require(
            IOptimismPortalV800(optimismPortal).superchainConfig() == superchainConfig,
            "OPCMUpgradeV800: OptimismPortal SuperchainConfig mismatch"
        );
        require(
            IOptimismPortalV800(optimismPortal).systemConfig() == systemConfig,
            "OPCMUpgradeV800: OptimismPortal SystemConfig mismatch"
        );
        require(
            ISystemConfigV800(systemConfig).disputeGameFactory() == disputeGameFactory,
            "OPCMUpgradeV800: SystemConfig DisputeGameFactory mismatch"
        );
        require(
            IProxyAdminV800(proxyAdmin).getProxyAdmin(payable(systemConfig)) == proxyAdmin,
            "OPCMUpgradeV800: SystemConfig ProxyAdmin mismatch"
        );
        require(
            ISuperchainConfigV800(superchainConfig).guardian() != address(0),
            "OPCMUpgradeV800: guardian is zero address"
        );
        require(IOwnedV800(proxyAdmin).owner() == rootSafe, "OPCMUpgradeV800: ProxyAdmin owner mismatch");
        require(
            IOwnedV800(disputeGameFactory).owner() == proxyAdminOwner,
            "OPCMUpgradeV800: DisputeGameFactory owner mismatch"
        );
    }

    /// @notice Derives the standard-validator exceptions from live roles and pre-upgrade Kona support.
    /// @dev Ordering matches validator output and the former Netchef inspector.
    struct ValidationErrorInputs {
        address challenger;
        bool konaWasRegistered;
        address proxyAdminOwner;
        uint32 startingRespectedGameType;
        address standardChallenger;
        address standardL1PAO;
        address standardSuperchainConfig;
        address superchainConfig;
    }

    function _expectedValidationErrors(ValidationErrorInputs memory inputs)
        internal
        pure
        returns (string memory errors)
    {
        if (inputs.proxyAdminOwner != inputs.standardL1PAO) {
            errors = _appendValidationError(errors, "OVERRIDES-L1PAOMULTISIG");
        }
        if (inputs.challenger != inputs.standardChallenger) {
            errors = _appendValidationError(errors, "OVERRIDES-CHALLENGER");
        }
        if (inputs.superchainConfig != inputs.standardSuperchainConfig) {
            errors = _appendValidationError(errors, "SYSCON-130");
        }
        if (inputs.startingRespectedGameType == SUPER_PERMISSIONED && !inputs.konaWasRegistered) {
            errors = _appendValidationError(errors, "SCKDG-SHAPE");
            errors = _appendValidationError(errors, "SCKDG-10");
        }
    }

    function _expectedValidationErrorsForChain(uint256 chainId) internal view returns (string memory) {
        return _expectedValidationErrors(
            ValidationErrorInputs({
                challenger: superchainAddrRegistry.getAddress("Challenger", chainId),
                konaWasRegistered: konaGameWasRegistered[chainId],
                proxyAdminOwner: superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId),
                startingRespectedGameType: upgrades[chainId].startingRespectedGameType,
                standardChallenger: standardValidator.challenger(),
                standardL1PAO: standardValidator.l1PAOMultisig(),
                standardSuperchainConfig: standardValidator.superchainConfig(),
                superchainConfig: superchainAddrRegistry.getAddress("SuperchainConfig", chainId)
            })
        );
    }

    function _appendValidationError(string memory errors, string memory next) private pure returns (string memory) {
        return bytes(errors).length == 0 ? next : string.concat(errors, ",", next);
    }

    /// @notice Returns whether a dispute game should be enabled based on the existing factory state.
    /// @dev ZK_DISPUTE_GAME is never enabled: `_templateSetup` rejects chains with a registered
    /// ZK game, and the v8 OPCM gates enabling it behind a dev feature anyway.
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
            return address(disputeGameFactory.gameImpls(GameType.wrap(CANNON_KONA))) != address(0);
        }
        return false;
    }

    /// @notice Addresses needed to build game configs for a single chain.
    struct GameConfigAddrs {
        IDisputeGameFactory factory;
        address proposer;
    }

    /// @notice Builds a single DisputeGameConfig entry.
    /// @dev SUPER_PERMISSIONED (gt=5) uses the simplified v8 game: proposer-only args
    /// (no prestate, no challenger) and the OPCM requires its initBond to be zero.
    function _buildOneGameConfig(
        GameConfigAddrs memory a,
        uint32 gt,
        bytes32 cannonPre,
        bytes32 cannonKonaPre,
        uint256 bond,
        uint32 startingRespectedGameType
    ) internal view returns (IOPContractsManagerV800.DisputeGameConfig memory) {
        bool enabled = _isGameTypeEnabled(a.factory, gt, startingRespectedGameType);
        bytes memory gameArgs;
        if (enabled) {
            if (gt == SUPER_PERMISSIONED) {
                gameArgs = abi.encode(a.proposer);
            } else {
                bool isKona = gt == CANNON_KONA || gt == SUPER_CANNON_KONA;
                gameArgs = abi.encode(isKona ? cannonKonaPre : cannonPre);
            }
        }
        return IOPContractsManagerV800.DisputeGameConfig({
            enabled: enabled,
            initBond: enabled && gt != SUPER_PERMISSIONED ? bond : 0,
            gameType: gt,
            gameArgs: gameArgs
        });
    }

    /// @notice Builds DisputeGameConfig[] for a chain from registry addresses and config prestates.
    /// @dev The v8 OPCM requires exactly these six game configs, in exactly this order.
    function _buildGameConfigs(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV800.DisputeGameConfig[] memory)
    {
        GameConfigAddrs memory a = GameConfigAddrs({
            factory: IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId)),
            proposer: superchainAddrRegistry.getAddress("Proposer", chainId)
        });

        bytes32 cannonPre = Claim.unwrap(upgrades[chainId].cannonPrestate);
        bytes32 cannonKonaPre = Claim.unwrap(upgrades[chainId].cannonKonaPrestate);
        uint256 bond = upgrades[chainId].initBond;
        uint32 startingRespectedGameType = upgrades[chainId].startingRespectedGameType;

        IOPContractsManagerV800.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV800.DisputeGameConfig[](6);
        uint32[6] memory gts =
            [CANNON, PERMISSIONED_CANNON, CANNON_KONA, SUPER_PERMISSIONED, SUPER_CANNON_KONA, ZK_DISPUTE_GAME];
        for (uint256 i = 0; i < 6; i++) {
            cfgs[i] = _buildOneGameConfig(a, gts[i], cannonPre, cannonKonaPre, bond, startingRespectedGameType);
        }
        return cfgs;
    }

    /// @dev The v8 OPCM rejects any extra instruction key other than the explicitly permitted
    /// overrides (the `PermittedProxyDeployment` allowance for DelayedWETH was removed from
    /// the upgrade path in v8.0.0).
    /// The `startingRespectedGameType` override is needed because the currently-respected
    /// game type gets disabled and OPCM validation requires the respected type to correspond
    /// to an enabled game config. The `startingAnchorRoot` override re-anchors the
    /// AnchorStateRegistry to an honest super root — without it the OPCM would reload the
    /// pre-upgrade anchor, which for chains rotating from output-root games is an output
    /// root that super-root games cannot prove against.
    function _buildExtraInstructions(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV800.ExtraInstruction[] memory)
    {
        IOPContractsManagerV800.ExtraInstruction[] memory extraInstructions =
            new IOPContractsManagerV800.ExtraInstruction[](2);
        extraInstructions[0] = IOPContractsManagerV800.ExtraInstruction({
            key: "overrides.cfg.startingRespectedGameType",
            data: abi.encode(upgrades[chainId].startingRespectedGameType)
        });
        extraInstructions[1] = IOPContractsManagerV800.ExtraInstruction({
            key: "overrides.cfg.startingAnchorRoot",
            data: abi.encode(upgrades[chainId].startingAnchorRootRoot, upgrades[chainId].startingAnchorRootL2SequenceNumber)
        });
        return extraInstructions;
    }

    /// @notice Builds the actions for executing the operations.
    /// @dev OPCMTaskBase uses Multicall3DelegateCall, so calls to OPCM must use delegatecall.
    /// Any state written in this function is discarded after build completes.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        require(chains.length > 0, "OPCMUpgradeV800: no chains configured");

        // Upgrade superchain once (before per-chain upgrades)
        address sc = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        (bool scOk,) = address(opcm).delegatecall(
            abi.encodeCall(
                IOPContractsManagerV800.upgradeSuperchain,
                (
                    IOPContractsManagerV800.SuperchainUpgradeInput({
                        superchainConfig: ISuperchainConfig(sc),
                        extraInstructions: new IOPContractsManagerV800.ExtraInstruction[](0)
                    })
                )
            )
        );
        require(scOk, "OPCMUpgradeV800: upgradeSuperchain delegatecall failed");

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV800: Config not found for chain");

            IOPContractsManagerV800.UpgradeInput memory inp = IOPContractsManagerV800.UpgradeInput({
                systemConfig: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                disputeGameConfigs: _buildGameConfigs(chainId),
                extraInstructions: _buildExtraInstructions(chainId)
            });

            // Delegatecall the OPCM.upgrade() function once per chain
            (bool ok,) =
                address(opcm).delegatecall(abi.encodeWithSelector(IOPContractsManagerV800.upgrade.selector, inp));
            require(ok, "OPCMUpgradeV800: Delegatecall failed in _build.");
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

            // The upgrade re-initializes the AnchorStateRegistry with the configured anchor
            // root; assert the override actually landed.
            IAnchorStateRegistryView asr =
                IAnchorStateRegistryView(superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId));
            (bytes32 anchorRoot, uint256 anchorL2SequenceNumber) = asr.getStartingAnchorRoot();
            require(
                anchorRoot == upgrades[chainId].startingAnchorRootRoot
                    && anchorL2SequenceNumber == upgrades[chainId].startingAnchorRootL2SequenceNumber,
                "OPCMUpgradeV800: startingAnchorRoot not applied"
            );

            IOPContractsManagerStandardValidator.ValidationInputDev memory input = IOPContractsManagerStandardValidator
                .ValidationInputDev({
                sysCfg: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                cannonPrestate: Claim.unwrap(upgrades[chainId].cannonPrestate),
                cannonKonaPrestate: Claim.unwrap(upgrades[chainId].cannonKonaPrestate),
                l2ChainID: chainId,
                proposer: superchainAddrRegistry.getAddress("Proposer", chainId)
            });

            // Compute overrides: non-zero only if chain differs from standard
            address l1PAOOverride = superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId);
            address challengerOverride = superchainAddrRegistry.getAddress("Challenger", chainId);

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

            string memory expErrors = _expectedValidationErrorsForChain(chainId);
            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    /// @dev The upgrade reinitializes SystemConfig, re-writing storage slots whose values are
    /// legitimately EOAs. This runs post-execution (SystemConfig is v4.0.0 by then), so
    /// `batchInbox()` no longer exists — its legacy slot is zeroed during reinitialization,
    /// which needs no exception.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address[] memory exceptions = new address[](chains.length * 3);
        uint256 cursor;
        for (uint256 i = 0; i < chains.length; i++) {
            ISystemConfigV800 sysCfg =
                ISystemConfigV800(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId));
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
/// @notice OPCM Interface (op-contracts/v8.0.0 OPContractsManagerV2).
interface IOPContractsManagerV800 {
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
    function superchainConfig() external view returns (address);
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
}

interface IOwnedV800 {
    function owner() external view returns (address);
}

interface IProxyAdminV800 {
    function getProxyAdmin(address payable proxy) external view returns (address);
}

interface IGnosisSafeView {
    function getOwners() external view returns (address[] memory);
}

interface ISuperchainConfigV800 {
    function guardian() external view returns (address);
}

interface IOptimismPortalV800 {
    function superchainConfig() external view returns (address);
    function systemConfig() external view returns (address);
}

/// @notice Read-only AnchorStateRegistry accessor. `getStartingAnchorRoot` returns a
/// `Proposal` struct, which ABI-decodes as its two fields.
interface IAnchorStateRegistryView {
    function getStartingAnchorRoot() external view returns (bytes32 root, uint256 l2SequenceNumber);
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

/// @notice Read-only SystemConfig accessors used to populate `_getCodeExceptions`.
/// @dev `batchInbox()` exists only pre-upgrade: SystemConfig v4.0.0 removed the getter.
/// It is kept here for callers that read the pre-upgrade SystemConfig (e.g. tests).
interface ISystemConfigV800 {
    function owner() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function unsafeBlockSigner() external view returns (address);
    function batchInbox() external view returns (address);
    function batcherHash() external view returns (bytes32);
}
