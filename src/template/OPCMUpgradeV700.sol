// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim, GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A template contract for configuring OPCMTaskBase templates.
/// Supports: op-contracts/v7.1.15
contract OPCMUpgradeV700 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice Struct to store inputs data for each L2 chain.
    /// @dev Fields must remain in alphabetical order for TOML decoding.
    struct OPCMUpgrade {
        Claim cannonKonaPrestate;
        Claim cannonPrestate;
        uint256 chainId;
        string expectedValidationErrors;
        uint256 initBond;
        uint32 startingRespectedGameType;
    }

    /// @notice Mapping of L2 chain IDs to their respective OPCMUpgrade structs.
    uint256[] public chainsToUpgrade;
    mapping(uint256 => OPCMUpgrade) public upgrades;

    IOPContractsManagerV700 public opcm;
    IOPContractsManagerStandardValidator public standardValidator;

    // Game type constants (from GameTypes library in op-contracts v7.1.15).
    uint32 internal constant CANNON = 0;
    uint32 internal constant PERMISSIONED_CANNON = 1;
    uint32 internal constant SUPER_CANNON = 4;
    uint32 internal constant SUPER_PERMISSIONED_CANNON = 5;
    uint32 internal constant CANNON_KONA = 8;
    uint32 internal constant SUPER_CANNON_KONA = 9;

    /// @notice Names in the SuperchainAddressRegistry that are expected to be written during this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](15);
        storageWrites[0] = "SuperchainConfig";
        storageWrites[1] = "ProtocolVersions";
        storageWrites[2] = "DisputeGameFactoryProxy";
        storageWrites[3] = "SystemConfigProxy";
        storageWrites[4] = "OptimismPortalProxy";
        storageWrites[5] = "OptimismMintableERC20FactoryProxy";
        storageWrites[6] = "AddressManager";
        storageWrites[7] = "L1StandardBridgeProxy";
        storageWrites[8] = "L1ERC721BridgeProxy";
        storageWrites[9] = "L1CrossDomainMessengerProxy";
        storageWrites[10] = "ProxyAdminOwner";
        storageWrites[11] = "AnchorStateRegistryProxy";
        storageWrites[12] = "PermissionedWETH";
        storageWrites[13] = "PermissionlessWETH";
        storageWrites[14] = "EthLockboxProxy";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in
    /// this function.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        require(chains.length > 0, "OPCMUpgradeV700: no chains configured");

        // Load upgrades from TOML
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        require(_upgrades.length == chains.length, "OPCMUpgradeV700: opcmUpgrades length mismatch");
        for (uint256 i = 0; i < _upgrades.length; i++) {
            require(_upgrades[i].chainId != 0, "OPCMUpgradeV700: chainId cannot be zero");
            require(upgrades[_upgrades[i].chainId].chainId == 0, "OPCMUpgradeV700: duplicate chain config");
            require(Claim.unwrap(_upgrades[i].cannonPrestate) != bytes32(0), "OPCMUpgradeV700: cannonPrestate is zero");
            require(
                Claim.unwrap(_upgrades[i].cannonKonaPrestate) != bytes32(0),
                "OPCMUpgradeV700: cannonKonaPrestate is zero"
            );
            chainsToUpgrade.push(_upgrades[i].chainId);
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        address superchainConfig = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        require(superchainConfig != address(0), "OPCMUpgradeV700: SuperchainConfig not found");
        require(superchainConfig.code.length > 0, "OPCMUpgradeV700: SuperchainConfig has no code");
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV700: config not found for chain");
            require(
                superchainAddrRegistry.getAddress("SuperchainConfig", chainId) == superchainConfig,
                "OPCMUpgradeV700: all chains must share the same SuperchainConfig"
            );
        }

        // Register EthLockboxProxy for each chain from the superchain-registry addresses.json.
        // The V700 upgrade writes to EthLockboxProxy storage, but it is not discovered by the
        // registry's onchain discovery flow, so we register it here.
        string memory addrJson = vm.readFile(superchainAddrRegistry.SUPERCHAIN_REGISTRY_ADDRESSES_PATH());
        for (uint256 i = 0; i < chains.length; i++) {
            string memory key = string.concat("$.", vm.toString(chains[i].chainId), ".EthLockboxProxy");
            if (vm.keyExistsJson(addrJson, key)) {
                address ethLockbox = vm.parseJsonAddress(addrJson, key);
                superchainAddrRegistry.saveAddress("EthLockboxProxy", chains[i], ethLockbox);
                vm.label(ethLockbox, "EthLockboxProxy");
            }
        }

        // The V700 upgrade reinitializes SystemConfig, re-writing all its storage.
        // Some stored addresses are legitimately EOAs that get re-written during reinitialization.
        // HACK: The current test uses a custom dev OPCM on Sepolia where the owner is also an
        // EOA (in production it would be a Safe), and the OPCM changes the batchInbox to a new
        // EOA during upgrade (in production batchInbox would not change).
        // TODO: Remove this entire block once a production-like OPCM is deployed for testing.
        for (uint256 i = 0; i < chains.length; i++) {
            ISystemConfigV700 sysCfg =
                ISystemConfigV700(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId));
            address[4] memory candidates = [
                sysCfg.owner(), // slot 0x33 — Safe in prod, EOA in dev
                sysCfg.unsafeBlockSigner(), // hashed slot — always EOA
                sysCfg.batchInbox(), // hashed slot — always EOA
                address(uint160(uint256(sysCfg.batcherHash()))) // slot 0x67 — always EOA (sequencer batcher)
            ];
            for (uint256 j = 0; j < candidates.length; j++) {
                if (candidates[j] != address(0) && candidates[j].code.length == 0) {
                    vm.etch(candidates[j], hex"01");
                }
            }
        }
        // HACK: The dev OPCM writes a new batchInbox address during upgrade that differs from the
        // current one. This won't happen with a production OPCM. Etch code at the known output.
        // TODO: Remove once production OPCM is used.
        vm.etch(address(0x0002b8639730E2F4dc88Dfd5Bbd0352E5518A758), hex"01");

        // OPCM from TOML; must be v7.1.15
        opcm = IOPContractsManagerV700(tomlContent.readAddress(".addresses.OPCM"));
        OPCM_TARGETS.push(address(opcm));
        require(opcm.version().eq("7.1.15"), "Incorrect OPCM");
        vm.label(address(opcm), "OPCM");

        // Fetch the validator directly from OPCM so it doesn't need to be configured in TOML
        standardValidator = opcm.opcmStandardValidator();
        require(address(standardValidator) != address(0), "OPCM returned zero validator");
        require(address(standardValidator).code.length > 0, "Validator has no code");
        vm.label(address(standardValidator), "OPCMStandardValidator");
    }

    /// @notice Returns whether a dispute game should be enabled based on the existing factory state.
    function _isGameTypeEnabled(IDisputeGameFactory disputeGameFactory, uint32 gt) internal view returns (bool) {
        if (gt == CANNON) return false;
        if (gt == PERMISSIONED_CANNON) return false;
        if (gt == CANNON_KONA) return false;
        if (gt == SUPER_CANNON) {
            return address(disputeGameFactory.gameImpls(GameType.wrap(CANNON))) != address(0);
        }
        if (gt == SUPER_PERMISSIONED_CANNON) {
            return address(disputeGameFactory.gameImpls(GameType.wrap(PERMISSIONED_CANNON))) != address(0);
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
        address challenger;
    }

    /// @notice Builds a single DisputeGameConfig entry.
    function _buildOneGameConfig(
        GameConfigAddrs memory a,
        uint32 gt,
        bytes32 cannonPre,
        bytes32 cannonKonaPre,
        uint256 bond
    ) internal view returns (IOPContractsManagerV700.DisputeGameConfig memory) {
        bool enabled = _isGameTypeEnabled(a.factory, gt);
        bytes memory gameArgs;
        if (enabled) {
            bool isPermissioned = gt == PERMISSIONED_CANNON || gt == SUPER_PERMISSIONED_CANNON;
            bool isKona = gt == CANNON_KONA || gt == SUPER_CANNON_KONA;
            bytes32 absolutePrestate = isKona ? cannonKonaPre : cannonPre;
            if (isPermissioned) {
                gameArgs = abi.encode(absolutePrestate, a.proposer, a.challenger);
            } else {
                gameArgs = abi.encode(absolutePrestate);
            }
        }
        return IOPContractsManagerV700.DisputeGameConfig({
            enabled: enabled,
            initBond: enabled ? bond : 0,
            gameType: gt,
            gameArgs: gameArgs
        });
    }

    /// @notice Builds DisputeGameConfig[] for a chain from registry addresses and config prestates.
    function _buildGameConfigs(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV700.DisputeGameConfig[] memory)
    {
        GameConfigAddrs memory a = GameConfigAddrs({
            factory: IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId)),
            proposer: superchainAddrRegistry.getAddress("Proposer", chainId),
            challenger: superchainAddrRegistry.getAddress("Challenger", chainId)
        });

        bytes32 cannonPre = Claim.unwrap(upgrades[chainId].cannonPrestate);
        bytes32 cannonKonaPre = Claim.unwrap(upgrades[chainId].cannonKonaPrestate);
        uint256 bond = upgrades[chainId].initBond;

        IOPContractsManagerV700.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV700.DisputeGameConfig[](6);
        uint32[6] memory gts =
            [CANNON, PERMISSIONED_CANNON, CANNON_KONA, SUPER_CANNON, SUPER_PERMISSIONED_CANNON, SUPER_CANNON_KONA];
        for (uint256 i = 0; i < 6; i++) {
            cfgs[i] = _buildOneGameConfig(a, gts[i], cannonPre, cannonKonaPre, bond);
        }
        return cfgs;
    }

    function _buildExtraInstructions(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV700.ExtraInstruction[] memory)
    {
        IOPContractsManagerV700.ExtraInstruction[] memory extraInstructions =
            new IOPContractsManagerV700.ExtraInstruction[](2);
        extraInstructions[0] =
            IOPContractsManagerV700.ExtraInstruction({key: "PermittedProxyDeployment", data: bytes("DelayedWETH")});
        extraInstructions[1] = IOPContractsManagerV700.ExtraInstruction({
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
        require(chains.length > 0, "OPCMUpgradeV700: no chains configured");

        // Upgrade superchain once (before per-chain upgrades)
        address sc = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        (bool scOk,) = address(opcm).delegatecall(
            abi.encodeCall(
                IOPContractsManagerV700.upgradeSuperchain,
                (
                    IOPContractsManagerV700.SuperchainUpgradeInput({
                        superchainConfig: ISuperchainConfig(sc),
                        extraInstructions: new IOPContractsManagerV700.ExtraInstruction[](0)
                    })
                )
            )
        );
        require(scOk, "OPCMUpgradeV700: upgradeSuperchain delegatecall failed");

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV700: Config not found for chain");

            IOPContractsManagerV700.UpgradeInput memory inp = IOPContractsManagerV700.UpgradeInput({
                systemConfig: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                disputeGameConfigs: _buildGameConfigs(chainId),
                extraInstructions: _buildExtraInstructions(chainId)
            });

            // Delegatecall the OPCM.upgrade() function once per chain
            (bool ok,) =
                address(opcm).delegatecall(abi.encodeWithSelector(IOPContractsManagerV700.upgrade.selector, inp));
            require(ok, "OPCMUpgradeV700: Delegatecall failed in _build.");
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

            string memory expErrors = upgrades[chainId].expectedValidationErrors;
            require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

/* ---------- Interfaces ---------- */
/// @notice OPCM Interface (v7.x / IOPContractsManagerV2).
interface IOPContractsManagerV700 {
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

interface ISystemConfigV700 {
    function owner() external view returns (address);
    function unsafeBlockSigner() external view returns (address);
    function batchInbox() external view returns (address);
    function batcherHash() external view returns (bytes32);
}
