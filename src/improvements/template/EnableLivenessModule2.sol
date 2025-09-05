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

/// @notice Template contract for enabling the LivenessModule2 in a Gnosis Safe
contract EnableLivenessModule2 is SimpleTaskBase {
    using AccountAccessParser for *;
    using stdStorage for StdStorage;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Module configuration loaded from TOML
    address public newModule;
    uint256 public livenessResponsePeriod;
    address public fallbackOwner;

    /// @notice Safe address string identifier
    string _safeAddressString;

    /// @notice Constant liveness module version
    string public livenessModuleVersion;

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
        _allowedStorageAccesses.add(newModule);
    }

    /// @notice Sets up the template with module configuration from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory file = vm.readFile(taskConfigFilePath);
        newModule = vm.parseTomlAddress(file, ".newModule");
        livenessResponsePeriod = vm.parseTomlUint(file, ".livenessResponsePeriod");
        fallbackOwner = vm.parseTomlAddress(file, ".fallbackOwner");
        livenessModuleVersion = vm.parseTomlString(file, ".livenessModuleVersion");
        assertNotEq(newModule.code.length, 0, "new module must have code");
    }

    /// @notice Builds the action for enabling the module in the Safe and configuring it
    function _build(address rootSafe) internal override {
        // First enable the module
        ModuleManager(rootSafe).enableModule(newModule);

        // Then configure the module
        ILivenessModule2.ModuleConfig memory config = ILivenessModule2.ModuleConfig({
            livenessResponsePeriod: livenessResponsePeriod,
            fallbackOwner: fallbackOwner
        });
        ILivenessModule2(newModule).configure(config);
    }

    /// @notice Validates that the module was enabled and configured correctly.
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory, address rootSafe)
        internal
        view
        override
    {
        _validateModuleEnabled(rootSafe);
        _validateModuleConfiguration(rootSafe);
        _validateStorageWrites(accountAccesses, rootSafe);
    }

    function _validateModuleEnabled(address rootSafe) internal view {
        (address[] memory modules, address nextModule) =
            ModuleManager(rootSafe).getModulesPaginated(SENTINEL_MODULE, 100);

        if (keccak256(abi.encodePacked(ISafe(rootSafe).VERSION())) == keccak256(abi.encodePacked("1.1.1"))) {
            console.log("[INFO] Old version of safe detected 1.1.1.");

            bool moduleFound;
            for (uint256 i = 0; i < modules.length; i++) {
                if (modules[i] == newModule) {
                    moduleFound = true;
                }
            }
            assertTrue(moduleFound, "New module not found in modules list");
        } else {
            assertTrue(ModuleManager(rootSafe).isModuleEnabled(newModule), "New module not enabled");
        }
        assertEq(nextModule, SENTINEL_MODULE, "Next module not correct");
    }

    function _validateModuleConfiguration(address rootSafe) internal view {
        ILivenessModule2 livenessModule = ILivenessModule2(newModule);
        assertEq(livenessModule.version(), livenessModuleVersion, "LivenessModule2 version not correct");

        (uint256 configuredPeriod, address configuredFallback) = livenessModule.safeConfigs(rootSafe);
        assertEq(configuredPeriod, livenessResponsePeriod, "Liveness response period not configured correctly");
        assertEq(configuredFallback, fallbackOwner, "Fallback owner not configured correctly");
    }

    function _validateStorageWrites(VmSafe.AccountAccess[] memory accountAccesses, address rootSafe) internal view {
        bytes32 moduleSlot = keccak256(abi.encode(newModule, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL_MODULE, MODULE_MAPPING_STORAGE_OFFSET));

        address[] memory uniqueWrites = accountAccesses.getUniqueWrites(false);
        assertTrue(uniqueWrites.length >= 1, "should write to at least the safe");

        bool safeWriteFound;
        bool moduleConfigWriteFound;
        for (uint256 i = 0; i < uniqueWrites.length; i++) {
            if (uniqueWrites[i] == rootSafe) {
                safeWriteFound = true;
            }
            if (uniqueWrites[i] == newModule) {
                moduleConfigWriteFound = true;
            }
        }
        assertTrue(safeWriteFound, "should write to the safe");
        assertTrue(moduleConfigWriteFound, "should write to the module for configuration");

        _validateSafeStorageWrites(accountAccesses, rootSafe, moduleSlot, sentinelSlot);
    }

    function _validateSafeStorageWrites(
        VmSafe.AccountAccess[] memory accountAccesses,
        address rootSafe,
        bytes32 moduleSlot,
        bytes32 sentinelSlot
    ) internal view {
        AccountAccessParser.StateDiff[] memory accountWrites = accountAccesses.getStateDiffFor(rootSafe, false);
        bool moduleWriteFound;

        for (uint256 i = 0; i < accountWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = accountWrites[i];
            if (keccak256(abi.encodePacked(ISafe(rootSafe).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
                assertTrue(
                    storageAccess.slot == NONCE_STORAGE_OFFSET || storageAccess.slot == moduleSlot
                        || storageAccess.slot == sentinelSlot,
                    "Only nonce and module slot should be updated on safe"
                );
            }
            if (storageAccess.slot == moduleSlot) {
                (address[] memory modules,) = ModuleManager(rootSafe).getModulesPaginated(SENTINEL_MODULE, 100);
                assertEq(
                    address(uint160(uint256(storageAccess.newValue))),
                    modules.length >= 2 ? modules[1] : SENTINEL_MODULE,
                    "new module not correct"
                );

                bytes32 sentinelModuleValue = vm.load(rootSafe, sentinelSlot);
                assertEq(
                    sentinelModuleValue, bytes32(uint256(uint160(newModule))), "sentinel does not point to new module"
                );

                moduleWriteFound = true;
            }
        }

        assertTrue(moduleWriteFound, "Module write not found");
    }

    /// @notice No code exceptions for this template
    function _getCodeExceptions() internal view override returns (address[] memory) {}
}
