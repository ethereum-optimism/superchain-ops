// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {ModuleManager} from "lib/safe-contracts/contracts/base/ModuleManager.sol";
import {GuardManager} from "lib/safe-contracts/contracts/base/GuardManager.sol";
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

interface ITimelockGuard {
    struct GuardConfig {
        uint256 timelockDelay;
    }

    function configureTimelockGuard(uint256 _timelockDelay) external;
    function version() external view returns (string memory);
    function safeConfigs(address) external view returns (uint256 timelockDelay);
}

interface ISafe {
    function VERSION() external view returns (string memory);
}

interface IGnosisSafe {
    function getOwners() external view returns (address[] memory);
}

/// @notice Template contract for transitioning from old liveness setup to LivenessModule2
/// This template performs the following operations:
/// 1. Disables the current liveness module
/// 2. Deactivates the LivenessGuard by calling setGuard with address(0)
/// 3. Enables the new LivenessModule2
/// 4. Configures the new LivenessModule2
contract MigrateToSaferSafe is SimpleTaskBase {
    using AccountAccessParser for *;
    using stdStorage for StdStorage;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Module configuration loaded from TOML
    address public currentLivenessModule;
    address public previousModule;
    address public newLivenessModule;
    address public newTimelockGuard;
    uint256 public livenessResponsePeriod;
    uint256 public timelockDelay;
    address public fallbackOwner;
    address public currentGuard;
    string public timelockGuardVersion;

    /// @notice Safe address string identifier
    string _safeAddressString;

    /// @notice The safe address (stored during setup)
    address public safeAddress;

    /// @notice Constant liveness module version
    string public livenessModuleVersion;

    /// @notice Gnosis Safe Sentinel Module address
    address internal constant SENTINEL_MODULE = address(0x1);

    /// @notice Gnosis Safe Module Mapping Storage Offset
    uint256 public constant MODULE_MAPPING_STORAGE_OFFSET = 1;

    /// @notice Gnosis Safe Module Nonce Storage Offset
    bytes32 public constant NONCE_STORAGE_OFFSET = bytes32(uint256(5));

    /// @notice Gnosis Safe Guard Storage Offset
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @notice Returns the safe address string identifier
    function safeAddressString() public view override returns (string memory) {
        return _safeAddressString;
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        // Storage writes for the modules are handled in _setAllowedStorageAccesses
        // since the module addresses are not in the SimpleAddressRegistry
        return new string[](0);
    }

    /// @notice Override to add the module addresses to allowed storage accesses
    function _setAllowedStorageAccesses() internal override {
        super._setAllowedStorageAccesses();
        // Add the module addresses directly since they're not in the registry
        _allowedStorageAccesses.add(currentLivenessModule);
        _allowedStorageAccesses.add(newLivenessModule);
        _allowedStorageAccesses.add(newTimelockGuard);
        // Add the current guard address if it exists
        if (currentGuard != address(0)) {
            _allowedStorageAccesses.add(currentGuard);
        }
    }

    /// @notice Sets up the template with module configuration from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);

        // Store the safe address for use in other functions
        safeAddress = rootSafe;

        string memory file = vm.readFile(taskConfigFilePath);

        currentLivenessModule = vm.parseTomlAddress(file, ".currentLivenessModule");
        previousModule = vm.parseTomlAddress(file, ".previousModule");
        newLivenessModule = vm.parseTomlAddress(file, ".newLivenessModule");
        newTimelockGuard = vm.parseTomlAddress(file, ".newTimelockGuard");
        livenessResponsePeriod = vm.parseTomlUint(file, ".livenessResponsePeriod");
        fallbackOwner = vm.parseTomlAddress(file, ".fallbackOwner");
        livenessModuleVersion = vm.parseTomlString(file, ".livenessModuleVersion");
        timelockDelay = vm.parseTomlUint(file, ".timelockDelay");
        timelockGuardVersion = vm.parseTomlString(file, ".timelockGuardVersion");


        // Current guard is required
        currentGuard = vm.parseTomlAddress(file, ".currentGuard");
        assertNotEq(currentGuard, address(0), "currentGuard is required and cannot be address(0)");

        assertNotEq(newLivenessModule.code.length, 0, "new module must have code");
    }

    /// @notice Builds the actions for the complete transition
    function _build(address rootSafe) internal override {
        // Step 1: Disable the current liveness module
        ModuleManager(rootSafe).disableModule(previousModule, currentLivenessModule);

        // Step 2: Enable the new LivenessModule2
        ModuleManager(rootSafe).enableModule(newLivenessModule);

        // Step 3: Configure the new LivenessModule2
        ILivenessModule2.ModuleConfig memory livenessConfig = ILivenessModule2.ModuleConfig({
            livenessResponsePeriod: livenessResponsePeriod,
            fallbackOwner: fallbackOwner
        });
        ILivenessModule2(newLivenessModule).configure(livenessConfig);

        // Step 4: Enable the new TimelockGuard
        GuardManager(rootSafe).setGuard(newTimelockGuard);

        // Step 5: Configure the new TimelockGuard
        ITimelockGuard(newTimelockGuard).configureTimelockGuard(timelockDelay);
    }

    /// @notice Validates that the complete transition was successful
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory, address rootSafe)
        internal
        view
        override
    {
        _validateCurrentModuleDisabled(rootSafe);
        _validateTimelockGuardEnabled(rootSafe);
        _validateTimelockGuardConfigured(rootSafe);
        _validateNewModuleEnabled(rootSafe);
        _validateNewModuleConfiguration(rootSafe);
        _validateStorageWrites(accountAccesses, rootSafe);
    }

    function _validateCurrentModuleDisabled(address rootSafe) internal view {
        (address[] memory modules,) = ModuleManager(rootSafe).getModulesPaginated(SENTINEL_MODULE, 100);

        if (keccak256(abi.encodePacked(ISafe(rootSafe).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
            assertFalse(ModuleManager(rootSafe).isModuleEnabled(currentLivenessModule), "Current module not disabled");
        } else {
            bool moduleFound;
            for (uint256 i = 0; i < modules.length; i++) {
                if (modules[i] == currentLivenessModule) {
                    moduleFound = true;
                }
            }
            assertFalse(moduleFound, "Current module is still found in modules list");
        }
    }

    function _validateTimelockGuardEnabled(address rootSafe) internal view {
        bytes32 guardSlot = GUARD_STORAGE_SLOT;
        bytes32 guardValue = vm.load(rootSafe, guardSlot);
        address guardAddress = address(uint160(uint256(guardValue)));
        assertEq(guardAddress, address(0), "Guard not disabled");
    }

    function _validateNewModuleEnabled(address rootSafe) internal view {
        (address[] memory modules, address nextModule) =
            ModuleManager(rootSafe).getModulesPaginated(SENTINEL_MODULE, 100);

        if (keccak256(abi.encodePacked(ISafe(rootSafe).VERSION())) == keccak256(abi.encodePacked("1.1.1"))) {
            console.log("[INFO] Old version of safe detected 1.1.1.");

            bool moduleFound;
            for (uint256 i = 0; i < modules.length; i++) {
                if (modules[i] == newLivenessModule) {
                    moduleFound = true;
                }
            }
            assertTrue(moduleFound, "New module not found in modules list");
        } else {
            assertTrue(ModuleManager(rootSafe).isModuleEnabled(newLivenessModule), "New module not enabled");
        }
        assertEq(nextModule, SENTINEL_MODULE, "Next module not correct");
    }

    function _validateTimelockGuardConfigured(address rootSafe) internal view {
      bytes32 guardSlot = GUARD_STORAGE_SLOT;
      bytes32 guardValue = vm.load(rootSafe, guardSlot);
      address guardAddress = address(uint160(uint256(guardValue)));
      assertEq(guardAddress, newTimelockGuard, "Guard not correct");
      assertEq(ITimelockGuard(guardAddress).safeConfigs(rootSafe).timelockDelay, timelockDelay, "Timelock delay not correct");
    }

    function _validateNewModuleConfiguration(address rootSafe) internal view {
        ILivenessModule2 livenessModule = ILivenessModule2(newLivenessModule);
        assertEq(livenessModule.version(), livenessModuleVersion, "LivenessModule2 version not correct");

        (uint256 configuredPeriod, address configuredFallback) = livenessModule.safeConfigs(rootSafe);
        assertEq(configuredPeriod, livenessResponsePeriod, "Liveness response period not configured correctly");
        assertEq(configuredFallback, fallbackOwner, "Fallback owner not configured correctly");
    }

    function _validateStorageWrites(VmSafe.AccountAccess[] memory accountAccesses, address rootSafe) internal view {
        bytes32 currentModuleSlot = keccak256(abi.encode(currentLivenessModule, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 newModuleSlot = keccak256(abi.encode(newLivenessModule, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL_MODULE, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 previousModuleSlot = keccak256(abi.encode(previousModule, MODULE_MAPPING_STORAGE_OFFSET));

        address[] memory uniqueWrites = accountAccesses.getUniqueWrites(false);
        assertTrue(uniqueWrites.length >= 2, "should write to at least the safe and modules");

        bool safeWriteFound;
        bool currentModuleClearWriteFound;
        bool newModuleConfigWriteFound;
        for (uint256 i = 0; i < uniqueWrites.length; i++) {
            if (uniqueWrites[i] == rootSafe) {
                safeWriteFound = true;
            }
            if (uniqueWrites[i] == currentLivenessModule) {
                currentModuleClearWriteFound = true;
            }
            if (uniqueWrites[i] == newLivenessModule) {
                newModuleConfigWriteFound = true;
            }
        }
        assertTrue(safeWriteFound, "should write to the safe");
        assertTrue(newModuleConfigWriteFound, "should write to the new module for configuration");

        _validateSafeStorageWrites(
            accountAccesses, rootSafe, currentModuleSlot, newModuleSlot, sentinelSlot, previousModuleSlot
        );
    }

    function _validateSafeStorageWrites(
        VmSafe.AccountAccess[] memory accountAccesses,
        address rootSafe,
        bytes32 currentModuleSlot,
        bytes32 newModuleSlot,
        bytes32 sentinelSlot,
        bytes32 previousModuleSlot
    ) internal view {
        AccountAccessParser.StateDiff[] memory accountWrites = accountAccesses.getStateDiffFor(rootSafe, false);
        bool currentModuleDisableFound;
        bool newModuleEnableFound;
        bool guardChangeFound;

        for (uint256 i = 0; i < accountWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = accountWrites[i];

            if (keccak256(abi.encodePacked(ISafe(rootSafe).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
                assertTrue(
                    storageAccess.slot == NONCE_STORAGE_OFFSET || storageAccess.slot == currentModuleSlot
                        || storageAccess.slot == newModuleSlot || storageAccess.slot == sentinelSlot
                        || storageAccess.slot == previousModuleSlot || storageAccess.slot == GUARD_STORAGE_SLOT,
                    "Only nonce, module slots, and guard slot should be updated on safe"
                );
            }

            // Validate current module disabled
            if (storageAccess.slot == currentModuleSlot) {
                assertEq(address(uint160(uint256(storageAccess.newValue))), address(0), "current module not disabled");
                currentModuleDisableFound = true;
            }

            // Validate new module enabled
            if (storageAccess.slot == newModuleSlot) {
                (address[] memory modules,) = ModuleManager(rootSafe).getModulesPaginated(SENTINEL_MODULE, 100);
                assertEq(
                    address(uint160(uint256(storageAccess.newValue))),
                    modules.length >= 2 ? modules[1] : SENTINEL_MODULE,
                    "new module not correct"
                );

                bytes32 sentinelModuleValue = vm.load(rootSafe, sentinelSlot);
                assertEq(
                    sentinelModuleValue, bytes32(uint256(uint160(newLivenessModule))), "sentinel does not point to new module"
                );

                newModuleEnableFound = true;
            }

            // Validate guard changed
            if (storageAccess.slot == GUARD_STORAGE_SLOT) {
                assertEq(address(uint160(uint256(storageAccess.newValue))), newTimelockGuard, "guard not changed");
                guardChangeFound = true;
            }
        }

        assertTrue(currentModuleDisableFound, "Current module disable write not found");
        assertTrue(newModuleEnableFound, "New module enable write not found");
        assertTrue(guardChangeFound, "Guard change write not found");
    }

    /// @notice Returns code exceptions for addresses that may not have code
    function _getCodeExceptions() internal view override returns (address[] memory) {
        // The LivenessGuard stores owner addresses which may be EOAs without code
        // Get the owners dynamically from the safe
        address[] memory owners = IGnosisSafe(safeAddress).getOwners();
        return owners;
    }
}
