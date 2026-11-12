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

/// @notice Upgrades OP Stack chains through OPContractsManagerV2 10.0.0 (Upgrade 22).
/// Supports: op-contracts/v10.0.0-rc.1 (OPContractsManagerV2 10.0.0)
/// @dev Serves two of the three U22 OPCM calls:
///   1. v9 -> v10 with the chain's current games and respected game type (task 1).
///   2. A re-run on chains already migrated by `OPCMMigrateV1000` (task 3) that enables
///      ZK_DISPUTE_GAME, disables SUPER_CANNON_KONA and rotates the respected game type,
///      including a later SUPER_PERMISSIONED fallback.
/// ZK_DISPUTE_GAME may only be enabled on migrated (INTEROP) chains: `migrate()` cannot respect
/// ZK, and a chain that enabled ZK before migrating would abandon its ZK games on the
/// pre-migration DisputeGameFactory.
contract OPCMUpgradeV1000 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Struct to store inputs data for each L2 chain.
    /// @dev Fields must remain in alphabetical order for TOML decoding. Every key is required; a
    /// disabled game's fields must be zero.
    /// @dev No anchor-root input: v10 rejects the `startingAnchorRoot` override and carries the
    /// anchor root forward from the AnchorStateRegistry.
    /// @dev A live game's bond (and, for ZK_DISPUTE_GAME, its durations and challenger bond) must
    /// equal the config: the upgrade never silently changes them. Prestates may change. Change
    /// the others in a SetDisputeGameArgs task.
    struct OPCMUpgrade {
        // SUPER_CANNON_KONA prestate; zero iff SUPER_CANNON_KONA is disabled.
        Claim cannonKonaPrestate;
        uint256 chainId;
        string expectedValidationErrors;
        // 5, 9 or 10; must be an enabled game. Only a migrated chain may change it.
        uint32 startingRespectedGameType;
        bool superCannonKonaEnabled;
        // Zero iff SUPER_CANNON_KONA is disabled.
        uint256 superCannonKonaInitBond;
        // ZK_DISPUTE_GAME fields: all zero iff ZK_DISPUTE_GAME is disabled.
        uint256 zkChallengerBond;
        bool zkEnabled;
        uint256 zkInitBond;
        uint64 zkMaxChallengeDuration;
        uint64 zkMaxProveDuration;
        // SP1 program verification key (superchain-registry prestate type "kona-sp1").
        Claim zkPrestate;
    }

    uint256[] public chainsToUpgrade;
    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    mapping(uint256 => OPCMUpgrade) internal upgrades;

    IOPContractsManagerV1000 public opcm;
    IOPContractsManagerStandardValidator public standardValidator;
    /// @notice Set by `skipOPCMVersionCheck = true` in the task config. Disables three OPCM gates, not
    /// one: the 10.0.0 version pin, the empty dev-feature bitmap and `isPermittedUpgradeSequence`.
    /// Only for dev OPCM builds; never set it on a governed chain.
    bool public skipOPCMVersionCheck;

    // Game type constants (from GameTypes library in op-contracts v10.0.0).
    // SUPER_CANNON (4) is retired since v8: the OPCM does not accept a config for it.
    uint32 internal constant CANNON = 0;
    uint32 internal constant PERMISSIONED_CANNON = 1;
    uint32 internal constant SUPER_PERMISSIONED = 5;
    uint32 internal constant CANNON_KONA = 8;
    uint32 internal constant SUPER_CANNON_KONA = 9;
    uint32 internal constant ZK_DISPUTE_GAME = 10;

    // Feature keys (from the Features library in op-contracts v10.0.0).
    bytes32 internal constant ETH_LOCKBOX = "ETH_LOCKBOX";
    bytes32 internal constant INTEROP = "INTEROP";

    /// @notice Per-chain lockbox recorded in `_templateSetup`, before the upgrade. v10 never deploys
    /// a lockbox, so the upgrade must keep it.
    mapping(uint256 => address) public preUpgradeLockbox;

    /// @notice Per-chain starting anchor root recorded in `_templateSetup`; the upgrade carries it forward.
    mapping(uint256 => bytes32) public preUpgradeAnchorRoot;
    mapping(uint256 => uint256) public preUpgradeAnchorL2SequenceNumber;

    /// @notice Per-chain anchor game recorded in `_templateSetup`. Chains past their first resolved
    /// game read the anchor from `anchorGame`, not the starting anchor root, so it must survive too.
    mapping(uint256 => address) public preUpgradeAnchorGame;

    /// @notice Per-chain withdrawal delays recorded in `_templateSetup`. v10 carries them forward
    /// from live state and rejects overrides; the template pins them itself.
    mapping(uint256 => uint256) public preUpgradeWethDelay;
    mapping(uint256 => uint256) public preUpgradeProofMaturityDelay;
    mapping(uint256 => uint256) public preUpgradeFinalityDelay;

    /// @notice Names in the SuperchainAddressRegistry that are expected to be written during this task.
    /// @dev ProtocolVersions is absent: op-contracts/v8.0.0 removed the ProtocolVersions
    /// contract and its OPCM integration. SuperchainConfig and each chain's DelayedWETH are
    /// resolved per chain in `_setAllowedStorageAccesses`: the registry only derives a WETH
    /// name from game types a chain may no longer run. On migrated chains the dispute names
    /// resolve to the interop set's shared contracts.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](10);
        storageWrites[0] = "DisputeGameFactoryProxy";
        storageWrites[1] = "SystemConfigProxy";
        storageWrites[2] = "OptimismPortalProxy";
        storageWrites[3] = "OptimismMintableERC20FactoryProxy";
        storageWrites[4] = "AddressManager";
        storageWrites[5] = "L1StandardBridgeProxy";
        storageWrites[6] = "L1ERC721BridgeProxy";
        storageWrites[7] = "L1CrossDomainMessengerProxy";
        storageWrites[8] = "AnchorStateRegistryProxy";
        storageWrites[9] = "EthLockboxProxy";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// @dev Empty: no ETH moves (see `preUpgradeLockbox`).
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Allowlist storage writes for the upgrade.
    /// @dev `SuperchainConfig` is resolved separately because the base implementation checks
    /// global or sentinel addresses before per-chain discovery. The DelayedWETH the upgrade
    /// re-initializes is the one SystemConfig points at, whatever game types the chain runs.
    function _setAllowedStorageAccesses() internal virtual override {
        super._setAllowedStorageAccesses();
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            _allowedStorageAccesses.add(superchainAddrRegistry.getAddress("SuperchainConfig", chainId));

            address delayedWETH =
                ISystemConfigV1000(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)).delayedWETH();
            require(delayedWETH != address(0), "OPCMUpgradeV1000: SystemConfig has no DelayedWETH");
            require(delayedWETH.code.length > 0, "OPCMUpgradeV1000: DelayedWETH has no code");
            _allowedStorageAccesses.add(delayedWETH);
            vm.label(delayedWETH, string.concat("DelayedWETH-", vm.toString(chainId)));
        }
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in
    /// this function.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        require(chains.length > 0, "OPCMUpgradeV1000: no chains configured");

        // Load upgrades from TOML
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        require(_upgrades.length == chains.length, "OPCMUpgradeV1000: opcmUpgrades length mismatch");
        for (uint256 i = 0; i < _upgrades.length; i++) {
            require(_upgrades[i].chainId != 0, "OPCMUpgradeV1000: chainId cannot be zero");
            require(upgrades[_upgrades[i].chainId].chainId == 0, "OPCMUpgradeV1000: duplicate chain config");
            _checkConfigFields(_upgrades[i]);
            chainsToUpgrade.push(_upgrades[i].chainId);
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        address superchainConfig = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        require(superchainConfig != address(0), "OPCMUpgradeV1000: SuperchainConfig not found");
        require(superchainConfig.code.length > 0, "OPCMUpgradeV1000: SuperchainConfig has no code");
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV1000: config not found for chain");
            require(
                superchainAddrRegistry.getAddress("SuperchainConfig", chainId) == superchainConfig,
                "OPCMUpgradeV1000: all chains must share the same SuperchainConfig"
            );
            _recordPreUpgradeState(chainId);
            _checkGameState(chainId, tomlContent);
        }

        _checkSharedFactories(chains);
        _loadOPCM(tomlContent, chains);
    }

    /// @notice Static checks on one `[[opcmUpgrades]]` entry. The ZK bounds mirror the OPCM's
    /// `_isValidZKDisputeGameConfig`; the non-zero bonds mirror its rule that every enabled game
    /// other than SUPER_PERMISSIONED carries a bond.
    function _checkConfigFields(OPCMUpgrade memory u) internal pure {
        uint32 rgt = u.startingRespectedGameType;
        require(
            rgt == SUPER_PERMISSIONED || (rgt == SUPER_CANNON_KONA && u.superCannonKonaEnabled)
                || (rgt == ZK_DISPUTE_GAME && u.zkEnabled),
            "OPCMUpgradeV1000: startingRespectedGameType must be an enabled super game type (5, 9 or 10)"
        );

        if (u.superCannonKonaEnabled) {
            require(Claim.unwrap(u.cannonKonaPrestate) != bytes32(0), "OPCMUpgradeV1000: cannonKonaPrestate is zero");
            require(u.superCannonKonaInitBond != 0, "OPCMUpgradeV1000: superCannonKonaInitBond is zero");
        } else {
            require(
                Claim.unwrap(u.cannonKonaPrestate) == bytes32(0) && u.superCannonKonaInitBond == 0,
                "OPCMUpgradeV1000: disabled SUPER_CANNON_KONA must have zero cannonKonaPrestate and superCannonKonaInitBond"
            );
        }

        if (u.zkEnabled) {
            require(Claim.unwrap(u.zkPrestate) != bytes32(0), "OPCMUpgradeV1000: zkPrestate is zero");
            require(
                u.zkMaxChallengeDuration > 0 && u.zkMaxChallengeDuration <= type(uint32).max,
                "OPCMUpgradeV1000: zkMaxChallengeDuration out of range"
            );
            require(
                u.zkMaxProveDuration > 0 && u.zkMaxProveDuration <= type(uint32).max,
                "OPCMUpgradeV1000: zkMaxProveDuration out of range"
            );
            require(u.zkChallengerBond != 0, "OPCMUpgradeV1000: zkChallengerBond is zero");
            require(u.zkInitBond != 0, "OPCMUpgradeV1000: zkInitBond is zero");
        } else {
            require(
                Claim.unwrap(u.zkPrestate) == bytes32(0) && u.zkMaxChallengeDuration == 0 && u.zkMaxProveDuration == 0
                    && u.zkChallengerBond == 0 && u.zkInitBond == 0,
                "OPCMUpgradeV1000: disabled ZK_DISPUTE_GAME must have zero zk fields"
            );
        }
    }

    /// @notice Records the state the upgrade must carry forward. On migrated chains these reads
    /// resolve to the interop set's shared contracts.
    function _recordPreUpgradeState(uint256 chainId) internal {
        IOptimismPortalView portal =
            IOptimismPortalView(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId));
        IAnchorStateRegistryView asr = IAnchorStateRegistryView(portal.anchorStateRegistry());
        address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

        (preUpgradeAnchorRoot[chainId], preUpgradeAnchorL2SequenceNumber[chainId]) = asr.getStartingAnchorRoot();
        preUpgradeAnchorGame[chainId] = asr.anchorGame();
        preUpgradeFinalityDelay[chainId] = asr.disputeGameFinalityDelaySeconds();
        preUpgradeProofMaturityDelay[chainId] = portal.proofMaturityDelaySeconds();
        preUpgradeWethDelay[chainId] = IDelayedWETHView(ISystemConfigV1000(sysCfg).delayedWETH()).delay();

        // v10 rejects `PermittedProxyDeployment`, so a chain must already have a lockbox. With the
        // ETH_LOCKBOX feature off the OPCM would also move the portal's ETH.
        address lockbox = portal.ethLockbox();
        require(lockbox != address(0), "OPCMUpgradeV1000: chain has no ETHLockbox");
        require(
            ISystemConfigV1000(sysCfg).isFeatureEnabled(ETH_LOCKBOX),
            "OPCMUpgradeV1000: ETH_LOCKBOX feature not enabled"
        );
        preUpgradeLockbox[chainId] = lockbox;
    }

    /// @notice Checks the config against the chain's live dispute games.
    /// @dev ZK_DISPUTE_GAME requires INTEROP. Since a respected type of 10 requires `zkEnabled`, this
    /// also gates respecting ZK.
    function _checkGameState(uint256 chainId, string memory tomlContent) internal view {
        OPCMUpgrade memory u = upgrades[chainId];
        IDisputeGameFactory factory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));
        bool migrated = ISystemConfigV1000(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId))
            .isFeatureEnabled(INTEROP);

        require(
            !u.zkEnabled || migrated,
            "OPCMUpgradeV1000: ZK_DISPUTE_GAME can only be enabled on a migrated interop chain"
        );
        if (!migrated) _checkGamesKept(chainId, factory, u);

        if (u.superCannonKonaEnabled) {
            if (address(factory.gameImpls(GameType.wrap(SUPER_CANNON_KONA))) != address(0)) {
                require(
                    factory.initBonds(GameType.wrap(SUPER_CANNON_KONA)) == u.superCannonKonaInitBond,
                    "OPCMUpgradeV1000: superCannonKonaInitBond must equal the chain's current SUPER_CANNON_KONA bond"
                );
            }
            _checkPrestateInRegistry(
                chainId, Claim.unwrap(u.cannonKonaPrestate), "cannonKonaPrestate", "cannon64-kona-interop", tomlContent
            );
        }

        if (u.zkEnabled) {
            if (address(factory.gameImpls(GameType.wrap(ZK_DISPUTE_GAME))) != address(0)) {
                _checkZKCarriedForward(factory, u);
            }
            _checkPrestateInRegistry(chainId, Claim.unwrap(u.zkPrestate), "zkPrestate", "kona-sp1", tomlContent);
        }
    }

    /// @notice A chain that is not migrated (task 1) keeps its respected game type and its games:
    /// only a migrated chain's re-run may rotate them.
    function _checkGamesKept(uint256 chainId, IDisputeGameFactory factory, OPCMUpgrade memory u) internal view {
        IAnchorStateRegistryView asr = IAnchorStateRegistryView(
            IOptimismPortalView(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId)).anchorStateRegistry()
        );
        require(
            asr.respectedGameType() == u.startingRespectedGameType,
            "OPCMUpgradeV1000: a chain that is not migrated must keep its respected game type"
        );
        require(
            (address(factory.gameImpls(GameType.wrap(SUPER_CANNON_KONA))) != address(0)) == u.superCannonKonaEnabled,
            "OPCMUpgradeV1000: a chain that is not migrated must keep its SUPER_CANNON_KONA registration"
        );
        require(
            address(factory.gameImpls(GameType.wrap(ZK_DISPUTE_GAME))) == address(0),
            "OPCMUpgradeV1000: a chain that is not migrated must not have a ZK_DISPUTE_GAME"
        );
    }

    /// @notice Requires a live ZK_DISPUTE_GAME's bond, durations and challenger bond to equal the
    /// config. Only the prestate may change in an upgrade.
    function _checkZKCarriedForward(IDisputeGameFactory factory, OPCMUpgrade memory u) internal view {
        require(
            factory.initBonds(GameType.wrap(ZK_DISPUTE_GAME)) == u.zkInitBond,
            "OPCMUpgradeV1000: zkInitBond must equal the chain's current ZK_DISPUTE_GAME bond"
        );
        (uint64 maxChallengeDuration, uint64 maxProveDuration, uint256 challengerBond) =
            _decodeZKTiming(factory.gameArgs(GameType.wrap(ZK_DISPUTE_GAME)));
        require(
            maxChallengeDuration == u.zkMaxChallengeDuration,
            "OPCMUpgradeV1000: zkMaxChallengeDuration must equal the chain's current value"
        );
        require(
            maxProveDuration == u.zkMaxProveDuration,
            "OPCMUpgradeV1000: zkMaxProveDuration must equal the chain's current value"
        );
        require(
            challengerBond == u.zkChallengerBond,
            "OPCMUpgradeV1000: zkChallengerBond must equal the chain's current value"
        );
    }

    /// @notice Decodes the timing fields of the 140-byte packed ZK_DISPUTE_GAME game args:
    /// prestate(32) | verifier(20) | maxChallengeDuration(8) | maxProveDuration(8) |
    /// challengerBond(32) | anchorStateRegistry(20) | weth(20). Offsets match
    /// `SetDisputeGameArgs._decodeZKArgs`.
    function _decodeZKTiming(bytes memory args)
        internal
        pure
        returns (uint64 maxChallengeDuration, uint64 maxProveDuration, uint256 challengerBond)
    {
        require(args.length == 140, "OPCMUpgradeV1000: unexpected ZK_DISPUTE_GAME gameArgs length");
        assembly {
            maxChallengeDuration := shr(192, mload(add(args, 0x54)))
            maxProveDuration := shr(192, mload(add(args, 0x5c)))
            challengerBond := mload(add(args, 0x64))
        }
    }

    /// @notice Requires every pair of listed chains that shares a DisputeGameFactory (a migrated
    /// interop set) to carry identical game configs. Each member's `upgrade()` rewrites the shared
    /// DisputeGameFactory and AnchorStateRegistry, so with differing configs the last call would
    /// silently win. List every member of the set: an unlisted member's shared contracts are
    /// rewritten but its chain is not validated.
    function _checkSharedFactories(SuperchainAddressRegistry.ChainInfo[] memory chains) internal view {
        for (uint256 i = 0; i < chains.length; i++) {
            address factory = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chains[i].chainId);
            for (uint256 j = i + 1; j < chains.length; j++) {
                if (superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chains[j].chainId) != factory) {
                    continue;
                }
                require(
                    _gameConfigHash(upgrades[chains[i].chainId]) == _gameConfigHash(upgrades[chains[j].chainId]),
                    "OPCMUpgradeV1000: chains sharing a DisputeGameFactory must use identical game configs"
                );
            }
        }
    }

    /// @notice Hash of an entry's game config, excluding `chainId` and `expectedValidationErrors`.
    /// Split in two to keep each `abi.encode` shallow.
    function _gameConfigHash(OPCMUpgrade memory u) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    abi.encode(
                        u.cannonKonaPrestate,
                        u.startingRespectedGameType,
                        u.superCannonKonaEnabled,
                        u.superCannonKonaInitBond
                    )
                ),
                keccak256(
                    abi.encode(
                        u.zkChallengerBond,
                        u.zkEnabled,
                        u.zkInitBond,
                        u.zkMaxChallengeDuration,
                        u.zkMaxProveDuration,
                        u.zkPrestate
                    )
                )
            )
        );
    }

    /// @notice Loads the OPCM from TOML and its StandardValidator. Must be the op-contracts/v10.0.0
    /// OPCM: a dev build with a higher patch version passes the on-chain sequence gate, and a chain
    /// upgraded with it is then refused by the release OPCM.
    function _loadOPCM(string memory tomlContent, SuperchainAddressRegistry.ChainInfo[] memory chains) internal {
        opcm = IOPContractsManagerV1000(tomlContent.readAddress(".addresses.OPCM"));
        OPCM_TARGETS.push(address(opcm));
        require(address(opcm).code.length > 0, "OPCMUpgradeV1000: OPCM has no code");
        skipOPCMVersionCheck =
            tomlContent.keyExists(".skipOPCMVersionCheck") && tomlContent.readBool(".skipOPCMVersionCheck");
        if (!skipOPCMVersionCheck) {
            require(opcm.version().eq("10.0.0"), "OPCMUpgradeV1000: incorrect OPCM version");
            require(opcm.devFeatureBitmap() == bytes32(0), "OPCMUpgradeV1000: OPCM has dev features enabled");
            // v10 permits a v9 chain (task 1) and a re-run of the same OPCM (task 3).
            for (uint256 i = 0; i < chains.length; i++) {
                require(
                    opcm.isPermittedUpgradeSequence(
                        ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId))
                    ),
                    "OPCMUpgradeV1000: OPCM does not permit upgrading this chain"
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

    /// @notice Returns whether a dispute game is enabled by the config. The base game types
    /// (0, 1, 8) are retired and always disabled.
    function _isGameTypeEnabled(uint32 gt, OPCMUpgrade memory u) internal pure returns (bool) {
        if (gt == SUPER_PERMISSIONED) return true;
        if (gt == SUPER_CANNON_KONA) return u.superCannonKonaEnabled;
        if (gt == ZK_DISPUTE_GAME) return u.zkEnabled;
        return false;
    }

    /// @notice Builds a single DisputeGameConfig entry. A disabled game gets empty args and a zero bond.
    /// @dev SUPER_PERMISSIONED (5): proposer-only args; the OPCM requires its bond to be zero.
    /// SUPER_CANNON_KONA (9): `FaultDisputeGameConfig{absolutePrestate}`.
    /// ZK_DISPUTE_GAME (10): `ZKDisputeGameConfig{absolutePrestate, maxChallengeDuration,
    /// maxProveDuration, challengerBond}`, exactly 128 bytes; the OPCM reverts
    /// `OPContractsManagerUtils_InvalidZKGameArgsLength` on any other length.
    function _buildOneGameConfig(address proposer, uint32 gt, OPCMUpgrade memory u)
        internal
        pure
        returns (IOPContractsManagerV1000.DisputeGameConfig memory cfg)
    {
        cfg.gameType = gt;
        if (!_isGameTypeEnabled(gt, u)) return cfg;
        cfg.enabled = true;
        if (gt == SUPER_PERMISSIONED) {
            cfg.gameArgs = abi.encode(proposer);
        } else if (gt == SUPER_CANNON_KONA) {
            cfg.gameArgs = abi.encode(u.cannonKonaPrestate);
            cfg.initBond = u.superCannonKonaInitBond;
        } else {
            cfg.gameArgs = abi.encode(u.zkPrestate, u.zkMaxChallengeDuration, u.zkMaxProveDuration, u.zkChallengerBond);
            cfg.initBond = u.zkInitBond;
        }
    }

    /// @notice Builds DisputeGameConfig[] for a chain from its config and registry proposer.
    /// @dev The OPCM requires exactly these six game configs, in exactly this order (v10
    /// `VALID_GAME_TYPES`). On migrated chains `Proposer` is the shared SUPER_PERMISSIONED proposer
    /// that `migrate()` set.
    function _buildGameConfigs(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV1000.DisputeGameConfig[] memory cfgs)
    {
        address proposer = superchainAddrRegistry.getAddress("Proposer", chainId);
        OPCMUpgrade memory u = upgrades[chainId];

        cfgs = new IOPContractsManagerV1000.DisputeGameConfig[](6);
        uint32[6] memory gts =
            [CANNON, PERMISSIONED_CANNON, CANNON_KONA, SUPER_PERMISSIONED, SUPER_CANNON_KONA, ZK_DISPUTE_GAME];
        for (uint256 i = 0; i < 6; i++) {
            cfgs[i] = _buildOneGameConfig(proposer, gts[i], u);
        }
    }

    /// @dev Sends exactly one upgrade instruction for every chain: the `startingRespectedGameType`
    /// override, which re-states the chain's respected game type (task 1) or rotates it (task 3).
    /// The OPCM requires it to be an enabled game. The anchor root and withdrawal delays carry
    /// forward from live state; v10 rejects overrides for them.
    function _buildExtraInstructions(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV1000.ExtraInstruction[] memory)
    {
        IOPContractsManagerV1000.ExtraInstruction[] memory extraInstructions =
            new IOPContractsManagerV1000.ExtraInstruction[](1);
        extraInstructions[0] = IOPContractsManagerV1000.ExtraInstruction({
            key: "overrides.cfg.startingRespectedGameType",
            data: abi.encode(upgrades[chainId].startingRespectedGameType)
        });
        return extraInstructions;
    }

    /// @notice Builds the actions for executing the operations.
    /// @dev OPCMTaskBase uses Multicall3DelegateCall, so calls to OPCM must use delegatecall.
    /// Any state written in this function is discarded after build completes.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        require(chains.length > 0, "OPCMUpgradeV1000: no chains configured");

        // Upgrade superchain once (before per-chain upgrades)
        address sc = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        _delegatecallOPCM(
            abi.encodeCall(
                IOPContractsManagerV1000.upgradeSuperchain,
                (
                    IOPContractsManagerV1000.SuperchainUpgradeInput({
                        superchainConfig: ISuperchainConfig(sc),
                        extraInstructions: new IOPContractsManagerV1000.ExtraInstruction[](0)
                    })
                )
            ),
            "upgradeSuperchain"
        );

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV1000: Config not found for chain");

            IOPContractsManagerV1000.UpgradeInput memory inp = IOPContractsManagerV1000.UpgradeInput({
                systemConfig: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                disputeGameConfigs: _buildGameConfigs(chainId),
                extraInstructions: _buildExtraInstructions(chainId)
            });

            // Delegatecall the OPCM.upgrade() function once per chain
            _delegatecallOPCM(abi.encodeCall(IOPContractsManagerV1000.upgrade, (inp)), "upgrade");
        }
    }

    /// @notice Delegatecalls the OPCM and re-raises its revert data, so an OPCM error surfaces as itself.
    function _delegatecallOPCM(bytes memory data, string memory context) internal {
        (bool ok, bytes memory returnData) = address(opcm).delegatecall(data);
        if (ok) return;
        if (returnData.length > 0) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
        revert(string.concat("OPCMUpgradeV1000: ", context, " delegatecall failed"));
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        // Cache standard validator's expected values (same for all chains)
        address standardL1PAO = standardValidator.l1PAOMultisig();
        address standardChallenger = standardValidator.challenger();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            OPCMUpgrade memory u = upgrades[chainId];

            _validateAnchorState(chainId, u.startingRespectedGameType);
            _validateDisputeGames(chainId, u);
            _validateWithdrawalDelays(chainId);
            _validateDelayedWETH(chainId);
            _validateLockbox(chainId);

            string memory errors = _runStandardValidator(chainId, u, standardL1PAO, standardChallenger);
            string memory expErrors = u.expectedValidationErrors;
            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice The upgrade re-initializes the portal's AnchorStateRegistry; asserts the respected
    /// game type was applied and the starting anchor root and anchor game were carried forward.
    function _validateAnchorState(uint256 chainId, uint32 rgt) internal view {
        IAnchorStateRegistryView asr = IAnchorStateRegistryView(
            IOptimismPortalView(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId)).anchorStateRegistry()
        );
        require(asr.respectedGameType() == rgt, "OPCMUpgradeV1000: startingRespectedGameType not applied");
        (bytes32 anchorRoot, uint256 anchorL2SequenceNumber) = asr.getStartingAnchorRoot();
        require(
            anchorRoot == preUpgradeAnchorRoot[chainId]
                && anchorL2SequenceNumber == preUpgradeAnchorL2SequenceNumber[chainId],
            "OPCMUpgradeV1000: starting anchor root changed"
        );
        require(asr.anchorGame() == preUpgradeAnchorGame[chainId], "OPCMUpgradeV1000: anchor game changed");
    }

    /// @notice Pins the factory's registrations and bonds to the config. For ZK_DISPUTE_GAME it
    /// also pins the full game args: the validator only bounds-checks its durations and challenger
    /// bond.
    function _validateDisputeGames(uint256 chainId, OPCMUpgrade memory u) internal view {
        IDisputeGameFactory factory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));
        require(
            address(factory.gameImpls(GameType.wrap(SUPER_PERMISSIONED))) != address(0),
            "OPCMUpgradeV1000: SUPER_PERMISSIONED not registered"
        );
        require(
            (address(factory.gameImpls(GameType.wrap(SUPER_CANNON_KONA))) != address(0)) == u.superCannonKonaEnabled,
            "OPCMUpgradeV1000: SUPER_CANNON_KONA registration does not match config"
        );
        require(
            factory.initBonds(GameType.wrap(SUPER_CANNON_KONA)) == u.superCannonKonaInitBond,
            "OPCMUpgradeV1000: SUPER_CANNON_KONA bond not applied"
        );
        require(
            (address(factory.gameImpls(GameType.wrap(ZK_DISPUTE_GAME))) != address(0)) == u.zkEnabled,
            "OPCMUpgradeV1000: ZK_DISPUTE_GAME registration does not match config"
        );
        require(
            factory.initBonds(GameType.wrap(ZK_DISPUTE_GAME)) == u.zkInitBond,
            "OPCMUpgradeV1000: ZK_DISPUTE_GAME bond not applied"
        );
        if (u.zkEnabled) {
            require(
                keccak256(factory.gameArgs(GameType.wrap(ZK_DISPUTE_GAME)))
                    == keccak256(_expectedZKGameArgs(chainId, u)),
                "OPCMUpgradeV1000: ZK_DISPUTE_GAME gameArgs mismatch"
            );
        }
    }

    /// @notice The packed ZK_DISPUTE_GAME game args the OPCM writes, mirroring
    /// `OPContractsManagerUtils.makeGameArgs`. Its verifier is the OPCM's `sp1PlonkAdapterImpl`,
    /// which the StandardValidator exposes.
    function _expectedZKGameArgs(uint256 chainId, OPCMUpgrade memory u) internal view returns (bytes memory) {
        address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
        address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
        return abi.encodePacked(
            Claim.unwrap(u.zkPrestate),
            standardValidator.sp1PlonkAdapterImpl(),
            u.zkMaxChallengeDuration,
            u.zkMaxProveDuration,
            u.zkChallengerBond,
            IOptimismPortalView(portal).anchorStateRegistry(),
            ISystemConfigV1000(sysCfg).delayedWETH()
        );
    }

    /// @notice Pins the withdrawal delays the upgrade carries forward from live state.
    function _validateWithdrawalDelays(uint256 chainId) internal view {
        IOptimismPortalView portal =
            IOptimismPortalView(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId));
        address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
        require(
            portal.proofMaturityDelaySeconds() == preUpgradeProofMaturityDelay[chainId],
            "OPCMUpgradeV1000: proof maturity delay changed"
        );
        require(
            IAnchorStateRegistryView(portal.anchorStateRegistry()).disputeGameFinalityDelaySeconds()
                == preUpgradeFinalityDelay[chainId],
            "OPCMUpgradeV1000: dispute game finality delay changed"
        );
        require(
            IDelayedWETHView(ISystemConfigV1000(sysCfg).delayedWETH()).delay() == preUpgradeWethDelay[chainId],
            "OPCMUpgradeV1000: DelayedWETH delay changed"
        );
    }

    /// @notice Requires the prestate to be a `prestateType` entry in the pinned superchain-registry
    /// `standard-prestates.toml`. Variants share version keys there, so a hash from the wrong variant
    /// is easy to pick and nothing else catches it: the validator compares the on-chain args against
    /// this same input. Chains outside the registry (custom prestates) are exempted by listing them
    /// in `skipPrestateRegistryCheckChainIds`, which covers every prestate of the chain.
    function _checkPrestateInRegistry(
        uint256 chainId,
        bytes32 prestate,
        string memory field,
        string memory prestateType,
        string memory tomlContent
    ) internal view {
        if (tomlContent.keyExists(".skipPrestateRegistryCheckChainIds")) {
            uint256[] memory skip = tomlContent.readUintArray(".skipPrestateRegistryCheckChainIds");
            for (uint256 j = 0; j < skip.length; j++) {
                if (skip[j] == chainId) return;
            }
        }
        string memory prestates = vm.readFile("lib/superchain-registry/validation/standard/standard-prestates.toml");
        string memory entry = string.concat("type=\"", prestateType, "\"\nhash=\"", vm.toString(prestate), "\"");
        require(
            prestates.contains(entry),
            string.concat(
                "OPCMUpgradeV1000: ",
                field,
                " is not a ",
                prestateType,
                " prestate in the registry for chain ",
                vm.toString(chainId)
            )
        );
    }

    /// @notice Pins a chain's DelayedWETH after the upgrade: the OPCM's implementation version and
    /// wired to the chain's ETHLockbox (its pause identifier). Covers chains where the validator
    /// skips it (neither SUPER_CANNON_KONA nor ZK_DISPUTE_GAME registered).
    function _validateDelayedWETH(uint256 chainId) internal view {
        address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);
        address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
        IDelayedWETHView weth = IDelayedWETHView(ISystemConfigV1000(sysCfg).delayedWETH());
        require(
            weth.version().eq(IDelayedWETHView(standardValidator.delayedWETHImpl()).version()),
            "OPCMUpgradeV1000: DelayedWETH not upgraded"
        );
        require(
            weth.ethLockbox() == IOptimismPortalView(portal).ethLockbox(),
            "OPCMUpgradeV1000: DelayedWETH not wired to the chain's ETHLockbox"
        );
    }

    /// @notice Pins a chain's lockbox wiring after the upgrade: the existing lockbox is kept and
    /// still authorizes the portal.
    function _validateLockbox(uint256 chainId) internal view {
        address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
        ISystemConfigV1000 sysCfg = ISystemConfigV1000(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId));
        address lockbox = IOptimismPortalView(portal).ethLockbox();
        require(lockbox == preUpgradeLockbox[chainId], "OPCMUpgradeV1000: existing lockbox was replaced");
        require(
            IETHLockboxView(lockbox).authorizedPortals(portal), "OPCMUpgradeV1000: portal not authorized on lockbox"
        );
        require(sysCfg.isFeatureEnabled(ETH_LOCKBOX), "OPCMUpgradeV1000: ETH_LOCKBOX feature not enabled");
    }

    /// @notice Runs the OPCM's StandardValidator for one chain and returns its error string.
    /// @dev The validator skips unregistered SUPER_CANNON_KONA and ZK_DISPUTE_GAME games, so the
    /// zero prestates of disabled games are never read.
    function _runStandardValidator(
        uint256 chainId,
        OPCMUpgrade memory u,
        address standardL1PAO,
        address standardChallenger
    ) internal view returns (string memory) {
        IOPContractsManagerStandardValidator.ValidationInputDev memory input = IOPContractsManagerStandardValidator
            .ValidationInputDev({
            sysCfg: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
            // The validator only reads cannonPrestate on its non-super path. This template
            // always leaves the chain respecting a super game type, so the value is unused.
            cannonPrestate: bytes32(0),
            cannonKonaPrestate: Claim.unwrap(u.cannonKonaPrestate),
            zkPrestate: Claim.unwrap(u.zkPrestate),
            l2ChainID: chainId,
            proposer: superchainAddrRegistry.getAddress("Proposer", chainId)
        });

        // Compute overrides: non-zero only if chain differs from standard. Chains run super
        // games only, and the super permissioned game carries no challenger, so the registry
        // has no `Challenger` entry for them: no override.
        address l1PAOOverride = superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId);
        address challengerOverride = _tryGetAddress("Challenger", chainId);

        l1PAOOverride = l1PAOOverride != standardL1PAO ? l1PAOOverride : address(0);
        challengerOverride = challengerOverride != standardChallenger ? challengerOverride : address(0);

        if (l1PAOOverride != address(0) || challengerOverride != address(0)) {
            return standardValidator.validateWithOverrides({
                _input: input,
                _allowFailure: true,
                _overrides: IOPContractsManagerStandardValidator.ValidationOverrides({
                    l1PAOMultisig: l1PAOOverride,
                    challenger: challengerOverride
                })
            });
        }
        return standardValidator.validate({_input: input, _allowFailure: true});
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
            ISystemConfigV1000 sysCfg =
                ISystemConfigV1000(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId));
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
/// @notice OPCM Interface (op-contracts/v10.0.0 OPContractsManagerV2), reduced to what upgrade needs.
interface IOPContractsManagerV1000 {
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

    function devFeatureBitmap() external view returns (bytes32);

    function upgrade(UpgradeInput memory _inp) external;

    function isPermittedUpgradeSequence(ISystemConfig _systemConfig) external view returns (bool);

    function upgradeSuperchain(SuperchainUpgradeInput memory _input) external;

    function opcmStandardValidator() external view returns (IOPContractsManagerStandardValidator);
}

/// @notice Validator interface (op-contracts/v10.0.0 StandardValidator) for validateWithOverrides usage.
interface IOPContractsManagerStandardValidator {
    struct ValidationInputDev {
        ISystemConfig sysCfg;
        bytes32 cannonPrestate;
        bytes32 cannonKonaPrestate;
        bytes32 zkPrestate;
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
    function sp1PlonkAdapterImpl() external view returns (address);
    function delayedWETHImpl() external view returns (address);
    function validateWithOverrides(
        ValidationInputDev memory _input,
        bool _allowFailure,
        ValidationOverrides memory _overrides
    ) external view returns (string memory);
}

interface ISuperchainConfig {}

interface IDisputeGameFactory {
    function gameImpls(GameType gameType) external view returns (address);
    function initBonds(GameType gameType) external view returns (uint256);
    function gameArgs(GameType gameType) external view returns (bytes memory);
}

/// @notice Read-only AnchorStateRegistry accessors. `getStartingAnchorRoot` returns a
/// `Proposal` struct, which ABI-decodes as its two fields.
interface IAnchorStateRegistryView {
    function getStartingAnchorRoot() external view returns (bytes32 root, uint256 l2SequenceNumber);
    function respectedGameType() external view returns (uint32);
    function anchorGame() external view returns (address);
    function disputeGameFinalityDelaySeconds() external view returns (uint256);
}

interface IDelayedWETHView {
    function version() external view returns (string memory);
    function ethLockbox() external view returns (address);
    function delay() external view returns (uint256);
}

interface ISystemConfig {}

/// @notice Read-only SystemConfig accessors.
interface ISystemConfigV1000 {
    function owner() external view returns (address);
    function unsafeBlockSigner() external view returns (address);
    function batcherHash() external view returns (bytes32);
    function isFeatureEnabled(bytes32) external view returns (bool);
    function delayedWETH() external view returns (address);
}

interface IOptimismPortalView {
    function anchorStateRegistry() external view returns (address);
    function ethLockbox() external view returns (address);
    function proofMaturityDelaySeconds() external view returns (uint256);
}

interface IETHLockboxView {
    function authorizedPortals(address) external view returns (bool);
}
