// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {ILivenessModule2} from "@eth-optimism-bedrock/interfaces/safe/ILivenessModule2.sol";
import {ModuleManager} from "lib/safe-contracts/contracts/base/ModuleManager.sol";

import {SimpleTaskBase} from "src/improvements/tasks/types/SimpleTaskBase.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface ISafe {
    function VERSION() external view returns (string memory);
}

/// @notice Template contract for enabling and configuring LivenessModule2 in a Gnosis Safe
/// @dev This template implements the two-step installation process:
///      1. Safe enables module at Safe level using ModuleManager.enableModule()
///      2. Safe configures module parameters using LivenessModule2.enableModule()
contract EnableLivenessModule2Template is SimpleTaskBase {
    using AccountAccessParser for *;
    using stdStorage for StdStorage;

    /// @notice LivenessModule2 singleton address loaded from TOML
    address public livenessModule2;

    /// @notice Challenge period in seconds loaded from TOML
    uint256 public challengePeriod;

    /// @notice Fallback owner address string identifier loaded from TOML
    string public fallbackOwnerString;


    /// @notice Constant safe address string identifier
    string _safeAddressString;

    /// @notice Gnosis Safe Sentinel Module address
    address internal constant SENTINEL_MODULE = address(0x1);

    /// @notice Gnosis Safe Module Mapping Storage Offset
    uint256 public constant MODULE_MAPPING_STORAGE_OFFSET = 1;

    /// @notice Gnosis Safe Module Nonce Storage Offset
    bytes32 public constant NONCE_STORAGE_OFFSET = bytes32(uint256(5));

    /// @notice Returns the safe address string identifier
    function safeAddressString() public view override returns (string memory) {
        return _safeAddressString;
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        // The only storage write is the safe address string, which is handled in
        // MultisigTask._taskSetup().
        return new string[](0);
    }

    /// @notice Sets up the template with LivenessModule2 configuration from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory file = vm.readFile(taskConfigFilePath);
        
        livenessModule2 = vm.parseTomlAddress(file, ".livenessModule2");
        challengePeriod = vm.parseTomlUint(file, ".challengePeriod");
        fallbackOwnerString = vm.parseTomlString(file, ".fallbackOwnerString");
        
        assertNotEq(livenessModule2.code.length, 0, "LivenessModule2 must have code");
        assertTrue(challengePeriod > 0, "Challenge period must be greater than 0");
        assertTrue(bytes(fallbackOwnerString).length > 0, "Fallback owner string must not be empty");
    }

    /// @notice Builds the actions for the two-step LivenessModule2 installation
    /// @dev Step 1: Enable module at Safe level
    /// @dev Step 2: Configure module parameters
    function _build(address rootSafe) internal override {
        // Step 1: Enable the module at Safe level
        ModuleManager(rootSafe).enableModule(livenessModule2);
        
        // Step 2: Configure the module parameters
        address fallbackOwner = simpleAddrRegistry.get(fallbackOwnerString);
        ILivenessModule2(livenessModule2).enableModule(challengePeriod, fallbackOwner);
    }

    /// @notice Validates that LivenessModule2 was enabled and configured correctly
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory, address rootSafe)
        internal
        view
        override
    {
        // Validate module is enabled at Safe level
        (address[] memory modules, address nextModule) =
            ModuleManager(rootSafe).getModulesPaginated(SENTINEL_MODULE, 100);
        
        if (keccak256(abi.encodePacked(ISafe(rootSafe).VERSION())) == keccak256(abi.encodePacked("1.1.1"))) {
            console.log("[INFO] Old version of safe detected 1.1.1.");
            assertTrue(modules[0] == livenessModule2, "LivenessModule2 not enabled at Safe level");
        } else {
            assertTrue(ModuleManager(rootSafe).isModuleEnabled(livenessModule2), "LivenessModule2 not enabled at Safe level");
        }
        assertEq(nextModule, SENTINEL_MODULE, "Next module not correct");

        bool moduleFound;
        for (uint256 i = 0; i < modules.length; i++) {
            if (modules[i] == livenessModule2) {
                moduleFound = true;
            }
        }
        assertTrue(moduleFound, "LivenessModule2 not found in modules list");


        // Validate module configuration
        address fallbackOwner = simpleAddrRegistry.get(fallbackOwnerString);
        (uint256 configChallengePeriod, address configFallbackOwner) = module.viewConfiguration(rootSafe);
        assertEq(configChallengePeriod, challengePeriod, "Challenge period not configured correctly");
        assertEq(configFallbackOwner, fallbackOwner, "Fallback owner not configured correctly");

        // Validate no active challenge
        uint256 challengeEndTime = module.isChallenged(rootSafe);
        assertEq(challengeEndTime, 0, "Should not have an active challenge");

        // Validate account accesses
        bytes32 moduleSlot = keccak256(abi.encode(livenessModule2, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL_MODULE, MODULE_MAPPING_STORAGE_OFFSET));

        bool moduleWriteFound;
        bool moduleConfigWriteFound;

        address[] memory uniqueWrites = accountAccesses.getUniqueWrites(false);
        
        // Should write to both Safe and LivenessModule2
        assertTrue(uniqueWrites.length >= 1, "should write to at least the safe");
        
        // Check writes to the Safe
        AccountAccessParser.StateDiff[] memory safeWrites = accountAccesses.getStateDiffFor(rootSafe, false);
        
        for (uint256 i = 0; i < safeWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = safeWrites[i];
            if (keccak256(abi.encodePacked(ISafe(rootSafe).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
                assertTrue(
                    storageAccess.slot == NONCE_STORAGE_OFFSET || storageAccess.slot == moduleSlot
                        || storageAccess.slot == sentinelSlot,
                    "Only nonce and module slot should be updated on safe"
                );
            }
            if (storageAccess.slot == moduleSlot) {
                assertEq(
                    address(uint160(uint256(storageAccess.newValue))),
                    modules.length >= 2 ? modules[1] : SENTINEL_MODULE,
                    "new module not correct"
                );

                bytes32 sentinelModuleValue = vm.load(rootSafe, sentinelSlot);
                assertEq(
                    sentinelModuleValue, bytes32(uint256(uint160(livenessModule2))), "sentinel does not point to LivenessModule2"
                );

                moduleWriteFound = true;
            }
        }

        // Check writes to LivenessModule2 for configuration
        AccountAccessParser.StateDiff[] memory moduleWrites = accountAccesses.getStateDiffFor(livenessModule2, false);
        
        for (uint256 i = 0; i < moduleWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = moduleWrites[i];
            // The configuration write should contain the challenge period and fallback owner
            if (storageAccess.newValue != bytes32(0)) {
                moduleConfigWriteFound = true;
            }
        }

        // Module installation write must be found
        assertTrue(moduleWriteFound, "Module installation write not found");
        assertTrue(moduleConfigWriteFound, "Module configuration write not found");
    }

    /// @notice No code exceptions for this template
    function _getCodeExceptions() internal view override returns (address[] memory) {}
}