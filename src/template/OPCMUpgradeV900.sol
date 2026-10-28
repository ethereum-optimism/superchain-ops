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
    /// @dev Fields must remain in alphabetical order for TOML decoding.
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

    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    uint256[] public chainsToUpgrade;
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice Chains whose portal has no ETHLockbox wired, for which the OPCM may deploy one.
    mapping(uint256 => bool) public permitEthLockboxDeployment;

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
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        require(_upgrades.length == chains.length, "OPCMUpgradeV900: opcmUpgrades length mismatch");
        for (uint256 i = 0; i < _upgrades.length; i++) {
            require(_upgrades[i].chainId != 0, "OPCMUpgradeV900: chainId cannot be zero");
            require(upgrades[_upgrades[i].chainId].chainId == 0, "OPCMUpgradeV900: duplicate chain config");
            require(
                Claim.unwrap(_upgrades[i].cannonKonaPrestate) != bytes32(0),
                "OPCMUpgradeV900: cannonKonaPrestate is zero"
            );
            // Base game types (0/1/8) are always disabled and ZK requires a dev-feature-enabled
            // OPCM, so only the two super game types can ever satisfy the OPCM's
            // enabled-respected-game-type check.
            require(
                _upgrades[i].startingRespectedGameType == SUPER_PERMISSIONED
                    || _upgrades[i].startingRespectedGameType == SUPER_CANNON_KONA,
                "OPCMUpgradeV900: startingRespectedGameType must be a super game type (5 or 9)"
            );
            chainsToUpgrade.push(_upgrades[i].chainId);
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        // Optional: chains (e.g. netchef devnets) whose portal has no ETHLockbox. The OPCM reverts
        // when it would deploy one without the `PermittedProxyDeployment=ETHLockbox` instruction.
        if (tomlContent.keyExists(".permitEthLockboxDeployment")) {
            uint256[] memory lockboxChainIds = tomlContent.readUintArray(".permitEthLockboxDeployment");
            for (uint256 i = 0; i < lockboxChainIds.length; i++) {
                uint256 chainId = lockboxChainIds[i];
                require(
                    upgrades[chainId].chainId != 0, "OPCMUpgradeV900: permitEthLockboxDeployment chain not configured"
                );
                require(
                    IOptimismPortalV900(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId)).ethLockbox()
                        == address(0),
                    "OPCMUpgradeV900: permitEthLockboxDeployment chain already has an ETHLockbox"
                );
                permitEthLockboxDeployment[chainId] = true;
            }
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

        // Register EthLockboxProxy for each chain. The upgrade writes to EthLockboxProxy storage.
        // Onchain discovery already registers it via `portal.ethLockbox()` for chains whose
        // portal has a wired lockbox; `saveAddress` reverts on duplicate keys, so only fall
        // back to the superchain-registry addresses.json when discovery found nothing.
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
    /// override pins the respected game type to an enabled game config; the anchor root is
    /// carried forward from the AnchorStateRegistry (v9 rejects the `startingAnchorRoot`
    /// override). Chains arriving from v8 normally already have an ETHLockbox; the proxy
    /// deployment is only permitted for chains listed in `permitEthLockboxDeployment`.
    function _buildExtraInstructions(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV900.ExtraInstruction[] memory)
    {
        IOPContractsManagerV900.ExtraInstruction[] memory extraInstructions =
            new IOPContractsManagerV900.ExtraInstruction[](permitEthLockboxDeployment[chainId] ? 2 : 1);
        extraInstructions[0] = IOPContractsManagerV900.ExtraInstruction({
            key: "overrides.cfg.startingRespectedGameType",
            data: abi.encode(upgrades[chainId].startingRespectedGameType)
        });
        if (permitEthLockboxDeployment[chainId]) {
            extraInstructions[1] =
                IOPContractsManagerV900.ExtraInstruction({key: "PermittedProxyDeployment", data: bytes("ETHLockbox")});
        }
        return extraInstructions;
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

            // The upgrade re-initializes the AnchorStateRegistry; assert the respected game
            // type override landed and the anchor root was carried forward, not cleared.
            IAnchorStateRegistryView asr =
                IAnchorStateRegistryView(superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId));
            require(
                asr.respectedGameType() == upgrades[chainId].startingRespectedGameType,
                "OPCMUpgradeV900: startingRespectedGameType not applied"
            );
            (bytes32 anchorRoot,) = asr.getStartingAnchorRoot();
            require(anchorRoot != bytes32(0), "OPCMUpgradeV900: anchor root was cleared");

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

interface IOptimismPortalV900 {
    function ethLockbox() external view returns (address);
}

interface IDisputeGameFactory {
    function gameImpls(GameType gameType) external view returns (address);
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

/// @notice Read-only SystemConfig accessors used to populate `_getCodeExceptions`.
interface ISystemConfigV900 {
    function owner() external view returns (address);
    function unsafeBlockSigner() external view returns (address);
    function batcherHash() external view returns (bytes32);
}
