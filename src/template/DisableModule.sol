// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {ModuleManager} from "lib/safe-contracts/contracts/base/ModuleManager.sol";

import {SimpleTaskBase} from "src/tasks/types/SimpleTaskBase.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface ISafe {
    function VERSION() external view returns (string memory);
}

/// @notice Template contract for disabling a module in a Gnosis Safe
contract DisableModule is SimpleTaskBase {
    using AccountAccessParser for *;
    using stdStorage for StdStorage;

    /// @notice Module configuration loaded from TOML
    address public moduleToDisable;
    address public previousModule;

    /// @notice Safe address string identifier
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

    /// @notice Sets up the template with module configuration from a TOML file
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory file = vm.readFile(_taskConfigFilePath);
        moduleToDisable = vm.parseTomlAddress(file, ".moduleToDisable");
        previousModule = vm.parseTomlAddress(file, ".previousModule");
    }

    /// @notice Builds the action for enabling the module in the Safe
    function _build(address _rootSafe) internal override {
        ModuleManager(_rootSafe).disableModule(previousModule, moduleToDisable);
    }

    /// @notice Validates that the module was enabled correctly.
    function _validate(VmSafe.AccountAccess[] memory _accountAccesses, Action[] memory, address _rootSafe)
        internal
        view
        override
    {
        (address[] memory modules, address nextModule) =
            ModuleManager(_rootSafe).getModulesPaginated(SENTINEL_MODULE, 100);
        if (keccak256(abi.encodePacked(ISafe(_rootSafe).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
            // Older versions of the Safe do not have the isModuleEnabled function.
            // Its OK to skip this check because we still check below if the module is
            // included in the array returned by getModulesPaginated().
            assertFalse(ModuleManager(_rootSafe).isModuleEnabled(moduleToDisable), "Module not disabled");
        }
        assertEq(nextModule, SENTINEL_MODULE, "Next module not correct");

        // Ensure the module is not in the list of modules
        bool moduleFound;
        for (uint256 i = 0; i < modules.length; i++) {
            if (modules[i] == moduleToDisable) {
                moduleFound = true;
            }
        }
        assertFalse(moduleFound, "Module is still found in new modules list");

        bytes32 moduleSlot = keccak256(abi.encode(moduleToDisable, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL_MODULE, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 previousModuleSlot = keccak256(abi.encode(previousModule, MODULE_MAPPING_STORAGE_OFFSET));

        bool moduleWriteFound;

        address[] memory uniqueWrites = _accountAccesses.getUniqueWrites(false);
        assertEq(uniqueWrites.length, 1, "should only write to the safe");
        assertEq(uniqueWrites[0], _rootSafe, "should only write to the safe");

        AccountAccessParser.StateDiff[] memory accountWrites = _accountAccesses.getStateDiffFor(_rootSafe, false);

        for (uint256 i = 0; i < accountWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = accountWrites[i];
            if (keccak256(abi.encodePacked(ISafe(_rootSafe).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
                assertTrue(
                    storageAccess.slot == NONCE_STORAGE_OFFSET || storageAccess.slot == moduleSlot
                        || storageAccess.slot == sentinelSlot || storageAccess.slot == previousModuleSlot,
                    "Only nonce and module slot should be updated on upgrade controller multisig"
                );
            }
            if (storageAccess.slot == moduleSlot) {
                assertEq(address(uint160(uint256(storageAccess.newValue))), address(0), "module not disabled");

                bytes32 sentinelModuleValue = vm.load(_rootSafe, sentinelSlot);
                assertEq(
                    sentinelModuleValue,
                    bytes32(uint256(uint160(previousModule))),
                    "sentinel does not point to previous module"
                );

                moduleWriteFound = true;
            }
        }

        // module write must be found, else revert
        assertTrue(moduleWriteFound, "Module write not found");
    }

    /// @notice No code exceptions for this template
    function _getCodeExceptions() internal view override returns (address[] memory) {}
}
