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

/// @notice Template contract for disabling LivenessModule2 from a Gnosis Safe
/// @dev This template implements the two-step removal process:
///      1. Safe disables module configuration using LivenessModule2.disableModule()
///      2. Safe removes module at Safe level using ModuleManager.disableModule()
contract DisableLivenessModule2Template is SimpleTaskBase {
    using AccountAccessParser for *;
    using stdStorage for StdStorage;

    /// @notice LivenessModule2 singleton address loaded from TOML
    address public livenessModule2;


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
        
        assertNotEq(livenessModule2.code.length, 0, "LivenessModule2 must have code");
    }

    /// @notice Helper function to find the previous module in the Safe's module list
    /// @param _safe The Safe to query
    /// @param _module The module to find the previous of
    /// @return The previous module address (or SENTINEL_MODULE if first)
    function _findPreviousModule(address _safe, address _module) internal view returns (address) {
        (address[] memory modules,) = ModuleManager(_safe).getModulesPaginated(SENTINEL_MODULE, 100);
        
        address previous = SENTINEL_MODULE;
        for (uint256 i = 0; i < modules.length; i++) {
            if (modules[i] == _module) {
                return previous;
            }
            previous = modules[i];
        }
        
        revert("Module not found in Safe's module list");
    }

    /// @notice Builds the actions for the two-step LivenessModule2 removal
    /// @dev Step 1: Disable module configuration
    /// @dev Step 2: Remove module from Safe level
    function _build(address rootSafe) internal override {
        // Step 1: Disable the module configuration
        ILivenessModule2(livenessModule2).disableModule();
        
        // Step 2: Remove the module from Safe level
        address previousModule = _findPreviousModule(rootSafe, livenessModule2);
        ModuleManager(rootSafe).disableModule(previousModule, livenessModule2);
    }

    /// @notice Validates that LivenessModule2 was disabled correctly
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory, address rootSafe)
        internal
        view
        override
    {
        // Validate module is no longer enabled at Safe level
        bool isEnabled = ModuleManager(rootSafe).isModuleEnabled(livenessModule2);
        assertEq(isEnabled, false, "LivenessModule2 should not be enabled at Safe level");

        // Validate module is not in the modules list
        (address[] memory modules,) = ModuleManager(rootSafe).getModulesPaginated(SENTINEL_MODULE, 100);
        
        bool moduleFound = false;
        for (uint256 i = 0; i < modules.length; i++) {
            if (modules[i] == livenessModule2) {
                moduleFound = true;
                break;
            }
        }
        assertEq(moduleFound, false, "LivenessModule2 should not be found in modules list");

        // Validate module configuration is cleared
        (uint256 configChallengePeriod, address configFallbackOwner) = ILivenessModule2(livenessModule2).viewConfiguration(rootSafe);
        assertEq(configChallengePeriod, 0, "Challenge period should be cleared");
        assertEq(configFallbackOwner, address(0), "Fallback owner should be cleared");

        // Validate no active challenge
        uint256 challengeEndTime = ILivenessModule2(livenessModule2).isChallenged(rootSafe);
        assertEq(challengeEndTime, 0, "Should not have an active challenge");

        // Validate account accesses
        bytes32 moduleSlot = keccak256(abi.encode(livenessModule2, MODULE_MAPPING_STORAGE_OFFSET));

        bool moduleConfigClearFound = false;
        bool moduleRemovalFound = false;

        address[] memory uniqueWrites = accountAccesses.getUniqueWrites(false);
        
        // Should write to both Safe and LivenessModule2
        assertTrue(uniqueWrites.length >= 1, "should write to at least the safe");
        
        // Check writes to LivenessModule2 for configuration clearing
        AccountAccessParser.StateDiff[] memory moduleWrites = accountAccesses.getStateDiffFor(livenessModule2, false);
        
        for (uint256 i = 0; i < moduleWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = moduleWrites[i];
            // The configuration clear should set values to zero
            if (storageAccess.newValue == bytes32(0) && storageAccess.previousValue != bytes32(0)) {
                moduleConfigClearFound = true;
            }
        }
        
        // Check writes to the Safe for module removal
        AccountAccessParser.StateDiff[] memory safeWrites = accountAccesses.getStateDiffFor(rootSafe, false);
        
        for (uint256 i = 0; i < safeWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = safeWrites[i];
            if (keccak256(abi.encodePacked(ISafe(rootSafe).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
                assertTrue(
                    storageAccess.slot == NONCE_STORAGE_OFFSET || storageAccess.slot == moduleSlot,
                    "Only nonce and module slot should be updated on safe"
                );
            }
            if (storageAccess.slot == moduleSlot) {
                // Module removal should clear the storage slot or update the linked list
                moduleRemovalFound = true;
            }
        }

        // Module configuration clearing must be found
        assertTrue(moduleConfigClearFound, "Module configuration clear write not found");
        assertTrue(moduleRemovalFound, "Module removal write not found");
    }

    /// @notice No code exceptions for this template
    function _getCodeExceptions() internal view override returns (address[] memory) {}
}