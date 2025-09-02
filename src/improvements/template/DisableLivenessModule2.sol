// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {ModuleManager} from "lib/safe-contracts/contracts/base/ModuleManager.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SimpleTaskBase} from "src/improvements/tasks/types/SimpleTaskBase.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

// Hardcoded interface for LivenessModule2
interface ILivenessModule2 {
    struct ModuleConfig {
        uint256 livenessResponsePeriod;
        address fallbackOwner;
    }

    function configure(ModuleConfig memory _config) external;
    function clear() external;
    function version() external view returns (string memory);
    function safeConfigs(address) external view returns (uint256 livenessResponsePeriod, address fallbackOwner);
}

interface ISafe {
    function VERSION() external view returns (string memory);
}

/// @notice Template contract for disabling the LivenessModule2 in a Gnosis Safe
contract DisableLivenessModule2 is SimpleTaskBase {
    using AccountAccessParser for *;
    using stdStorage for StdStorage;
    using EnumerableSet for EnumerableSet.AddressSet;

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
        // Storage writes for the module are handled in _setAllowedStorageAccesses
        // since the module address is not in the SimpleAddressRegistry
        return new string[](0);
    }

    /// @notice Override to add the module address to allowed storage accesses
    function _setAllowedStorageAccesses() internal override {
        super._setAllowedStorageAccesses();
        // Add the module address directly since it's not in the registry
        _allowedStorageAccesses.add(moduleToDisable);
    }

    /// @notice Sets up the template with module configuration from a TOML file
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory file = vm.readFile(_taskConfigFilePath);
        moduleToDisable = vm.parseTomlAddress(file, ".moduleToDisable");
        previousModule = vm.parseTomlAddress(file, ".previousModule");
    }

    /// @notice Builds the action for disabling the module in the Safe and clearing its configuration
    function _build(address _rootSafe) internal override {
        // First disable the module from the Safe
        ModuleManager(_rootSafe).disableModule(previousModule, moduleToDisable);

        // Then clear the module configuration
        ILivenessModule2(moduleToDisable).clear();
    }

    /// @notice Validates that the module was disabled and cleared correctly.
    function _validate(VmSafe.AccountAccess[] memory _accountAccesses, Action[] memory, address _rootSafe)
        internal
        view
        override
    {
        _validateModuleDisabled(_rootSafe);
        _validateModuleCleared(_rootSafe);
        _validateStorageWrites(_accountAccesses, _rootSafe);
    }

    function _validateModuleDisabled(address _rootSafe) internal view {
        (address[] memory modules, address nextModule) =
            ModuleManager(_rootSafe).getModulesPaginated(SENTINEL_MODULE, 100);
        if (keccak256(abi.encodePacked(ISafe(_rootSafe).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
            assertFalse(ModuleManager(_rootSafe).isModuleEnabled(moduleToDisable), "Module not disabled");
        }
        assertEq(nextModule, SENTINEL_MODULE, "Next module not correct");

        bool moduleFound;
        for (uint256 i = 0; i < modules.length; i++) {
            if (modules[i] == moduleToDisable) {
                moduleFound = true;
            }
        }
        assertFalse(moduleFound, "Module is still found in new modules list");
    }

    function _validateModuleCleared(address _rootSafe) internal view {
        ILivenessModule2 livenessModule = ILivenessModule2(moduleToDisable);
        (uint256 configuredPeriod, address configuredFallback) = livenessModule.safeConfigs(_rootSafe);
        assertEq(configuredPeriod, 0, "Liveness response period not cleared");
        assertEq(configuredFallback, address(0), "Fallback owner not cleared");
    }

    function _validateStorageWrites(VmSafe.AccountAccess[] memory _accountAccesses, address _rootSafe) internal view {
        bytes32 moduleSlot = keccak256(abi.encode(moduleToDisable, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL_MODULE, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 previousModuleSlot = keccak256(abi.encode(previousModule, MODULE_MAPPING_STORAGE_OFFSET));

        address[] memory uniqueWrites = _accountAccesses.getUniqueWrites(false);
        assertTrue(uniqueWrites.length >= 1, "should write to at least the safe");

        bool safeWriteFound;
        bool moduleClearWriteFound;
        for (uint256 i = 0; i < uniqueWrites.length; i++) {
            if (uniqueWrites[i] == _rootSafe) {
                safeWriteFound = true;
            }
            if (uniqueWrites[i] == moduleToDisable) {
                moduleClearWriteFound = true;
            }
        }
        assertTrue(safeWriteFound, "should write to the safe");
        assertTrue(moduleClearWriteFound, "should write to the module for clearing");

        _validateSafeStorageWrites(_accountAccesses, _rootSafe, moduleSlot, sentinelSlot, previousModuleSlot);
    }

    function _validateSafeStorageWrites(
        VmSafe.AccountAccess[] memory _accountAccesses,
        address _rootSafe,
        bytes32 moduleSlot,
        bytes32 sentinelSlot,
        bytes32 previousModuleSlot
    ) internal view {
        AccountAccessParser.StateDiff[] memory accountWrites = _accountAccesses.getStateDiffFor(_rootSafe, false);
        bool moduleWriteFound;

        for (uint256 i = 0; i < accountWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = accountWrites[i];
            if (keccak256(abi.encodePacked(ISafe(_rootSafe).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
                assertTrue(
                    storageAccess.slot == NONCE_STORAGE_OFFSET || storageAccess.slot == moduleSlot
                        || storageAccess.slot == sentinelSlot || storageAccess.slot == previousModuleSlot,
                    "Only nonce and module slot should be updated on safe"
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

        assertTrue(moduleWriteFound, "Module write not found");
    }

    /// @notice No code exceptions for this template
    function _getCodeExceptions() internal view override returns (address[] memory) {}
}
