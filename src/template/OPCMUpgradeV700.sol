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
/// Supports: op-contracts/v7.0.0
contract OPCMUpgradeV700 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice Struct to store inputs data for each L2 chain.
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

    IOPCM public opcm;
    IOPContractsManagerStandardValidator public standardValidator;

    /// @notice Names in the SuperchainAddressRegistry that are expected to be written during this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](13);
        storageWrites[0] = "SuperchainConfig";
        storageWrites[1] = "ProtocolVersions";
        storageWrites[2] = "DisputeGameFactoryProxy";
        storageWrites[3] = "SystemConfigProxy";
        storageWrites[4] = "OptimismPortalProxy";
        storageWrites[5] = "OptimismMintableERC20FactoryProxy";
        storageWrites[6] = "AddressManager";
        storageWrites[7] = "L1StandardBridgeProxy";
        storageWrites[8] = "L1ERC721BridgeProxy";
        storageWrites[9] = "ProxyAdminOwner";
        storageWrites[10] = "AnchorStateRegistryProxy";
        storageWrites[11] = "PermissionedWETH";
        storageWrites[12] = "PermissionlessWETH";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // Load upgrades from TOML
        OPCMUpgrade[] memory _upgrades = abi.decode(tomlContent.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < _upgrades.length; i++) {
            chainsToUpgrade.push(_upgrades[i].chainId);
            upgrades[_upgrades[i].chainId] = _upgrades[i];
        }

        // OPCM from TOML; must be v7.0.0
        opcm = IOPCM(tomlContent.readAddress(".addresses.OPCM"));
        OPCM_TARGETS.push(address(opcm));
        require(IOPContractsManagerV700(address(opcm)).version().eq("7.1.15"), "Incorrect OPCM");
        vm.label(address(opcm), "OPCM");

        // Fetch the validator directly from OPCM so it doesn't need to be configured in TOML
        standardValidator = opcm.opcmStandardValidator();
        require(address(standardValidator) != address(0), "OPCM returned zero validator");
        require(address(standardValidator).code.length > 0, "Validator has no code");
        vm.label(address(standardValidator), "OPCMStandardValidator");
    }

    /// @notice Returns whether a super dispute game should be enabled based on the existing factory state.
    function _isGameTypeEnabled(IDisputeGameFactory disputeGameFactory, uint32 gt) internal view returns (bool) {
        if (gt == 0) return false;
        if (gt == 1) return false;
        if (gt == 8) return false;
        if (gt == 4) {
            return address(disputeGameFactory.gameImpls(GameType.wrap(0))) != address(0);
        }
        if (gt == 5) {
            return address(disputeGameFactory.gameImpls(GameType.wrap(1))) != address(0);
        }
        if (gt == 9) {
            return address(disputeGameFactory.gameImpls(GameType.wrap(8))) != address(0);
        }
        return false;
    }

    /// @notice Addresses needed to build game configs for a single chain.
    struct GameConfigAddrs {
        IDisputeGameFactory factory;
        address mips;
        address asr;
        address permissionlessWETH;
        address permissionedWETH;
        address proposer;
        address challenger;
    }

    /// @notice SUPER_PERMISSIONED_CANNON still uses the legacy ABI-encoded args shape.
    function _encodeSuperPermissionedGameArgs(bytes32 prestate, address proposer, address challenger)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(prestate, proposer, challenger);
    }

    /// @notice Builds a single DisputeGameConfig entry.
    function _buildOneGameConfig(
        GameConfigAddrs memory a,
        uint256 chainId,
        uint32 gt,
        bytes32 cannonPre,
        bytes32 cannonKonaPre,
        uint256 bond
    ) internal view returns (IOPContractsManagerV700.DisputeGameConfig memory) {
        bool enabled = _isGameTypeEnabled(a.factory, gt);
        bytes memory gameArgs;
        if (enabled) {
            bool isPermissioned = gt == 1 || gt == 5;
            bool isKona = gt == 8 || gt == 9;
            // if (gt == 5) {
            //     gameArgs =
            //         _encodeSuperPermissionedGameArgs(isKona ? cannonKonaPre : cannonPre, a.proposer, a.challenger);
            // } 
            // else {
                gameArgs = LibGameArgs.encode(
                    LibGameArgs.GameArgs({
                        absolutePrestate: isKona ? cannonKonaPre : cannonPre,
                        vm: a.mips,
                        anchorStateRegistry: a.asr,
                        weth: isPermissioned ? a.permissionedWETH : a.permissionlessWETH,
                        l2ChainId: chainId,
                        proposer: isPermissioned ? a.proposer : address(0),
                        challenger: isPermissioned ? a.challenger : address(0)
                    })
                );
            // }
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
            mips: superchainAddrRegistry.getAddress("MIPS", chainId),
            asr: superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId),
            permissionlessWETH: superchainAddrRegistry.getAddress("PermissionlessWETH", chainId),
            permissionedWETH: superchainAddrRegistry.getAddress("PermissionedWETH", chainId),
            proposer: superchainAddrRegistry.getAddress("Proposer", chainId),
            challenger: superchainAddrRegistry.getAddress("Challenger", chainId)
        });

        bytes32 cannonPre = Claim.unwrap(upgrades[chainId].cannonPrestate);
        bytes32 cannonKonaPre = Claim.unwrap(upgrades[chainId].cannonKonaPrestate);
        uint256 bond = upgrades[chainId].initBond;

        IOPContractsManagerV700.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV700.DisputeGameConfig[](6);
        uint32[6] memory gts = [uint32(0), 1, 8, 4, 5, 9];
        for (uint256 i = 0; i < 6; i++) {
            cfgs[i] = _buildOneGameConfig(a, chainId, gts[i], cannonPre, cannonKonaPre, bond);
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
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

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

/// @notice Interface to retrieve the standard validator from OPCM.
interface IOPCM {
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

error InvalidGameArgsLength();

/// @title LibGameArgs
/// @notice Library for encoding and decoding dispute game arguments.
library LibGameArgs {
    uint256 public constant PERMISSIONLESS_ARGS_LENGTH = 124;
    uint256 public constant PERMISSIONED_ARGS_LENGTH = 164;

    struct GameArgs {
        bytes32 absolutePrestate;
        address vm;
        address anchorStateRegistry;
        address weth;
        uint256 l2ChainId;
        address proposer;
        address challenger;
    }

    function encode(GameArgs memory _args) internal pure returns (bytes memory) {
        if (_args.proposer == address(0) && _args.challenger == address(0)) {
            return abi.encodePacked(
                _args.absolutePrestate, _args.vm, _args.anchorStateRegistry, _args.weth, _args.l2ChainId
            );
        } else {
            return abi.encodePacked(
                _args.absolutePrestate,
                _args.vm,
                _args.anchorStateRegistry,
                _args.weth,
                _args.l2ChainId,
                _args.proposer,
                _args.challenger
            );
        }
    }

    function decode(bytes memory _gameArgs) internal pure returns (GameArgs memory) {
        uint256 len = _gameArgs.length;
        if (len != PERMISSIONED_ARGS_LENGTH && len != PERMISSIONLESS_ARGS_LENGTH) {
            revert InvalidGameArgsLength();
        }

        bytes32 absolutePrestate;
        address vm_;
        address asr;
        address weth;
        uint256 l2ChainId;
        address proposer;
        address challenger;

        assembly {
            let d := add(_gameArgs, 32)
            absolutePrestate := mload(d)
            vm_ := shr(96, mload(add(d, 32)))
            asr := shr(96, mload(add(d, 52)))
            weth := shr(96, mload(add(d, 72)))
            l2ChainId := mload(add(d, 92))
        }

        if (len == PERMISSIONED_ARGS_LENGTH) {
            assembly {
                let d := add(_gameArgs, 32)
                proposer := shr(96, mload(add(d, 124)))
                challenger := shr(96, mload(add(d, 144)))
            }
        }
        return GameArgs({
            absolutePrestate: absolutePrestate,
            vm: vm_,
            anchorStateRegistry: asr,
            weth: weth,
            l2ChainId: l2ChainId,
            proposer: proposer,
            challenger: challenger
        });
    }

    function isValidPermissionlessArgs(bytes memory _args) internal pure returns (bool) {
        return _args.length == PERMISSIONLESS_ARGS_LENGTH;
    }

    function isValidPermissionedArgs(bytes memory _args) internal pure returns (bool) {
        return _args.length == PERMISSIONED_ARGS_LENGTH;
    }
}
