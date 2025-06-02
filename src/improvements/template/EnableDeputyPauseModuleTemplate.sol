// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {IDeputyPauseModule} from "@eth-optimism-bedrock/interfaces/safe/IDeputyPauseModule.sol";
import {ModuleManager} from "lib/safe-contracts/contracts/base/ModuleManager.sol";

import {SimpleTaskBase} from "src/improvements/tasks/types/SimpleTaskBase.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface ISafe {
    function VERSION() external view returns (string memory);
}

/// @notice Template contract for enabling the DeputyPauseModule in a Gnosis Safe
contract EnableDeputyPauseModuleTemplate is SimpleTaskBase {
    using AccountAccessParser for *;
    using stdStorage for StdStorage;

    /// @notice Module configuration loaded from TOML
    address public newModule;

    /// @notice Constant safe address string identifier
    string _safeAddressString;

    /// @notice Constant foundation safe address string identifier
    /// Used to verify the foundation safe address in the DeputyPauseModule
    string public foundationSafeString;

    /// @notice Constant deputy pause module version
    string public deputyPauseModuleVersion;

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
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory file = vm.readFile(taskConfigFilePath);
        newModule = vm.parseTomlAddress(file, ".newModule");
        foundationSafeString = vm.parseTomlString(file, ".foundationSafeString");
        deputyPauseModuleVersion = vm.parseTomlString(file, ".deputyPauseModuleVersion");
        assertNotEq(newModule.code.length, 0, "new module must have code");
    }

    /// @notice Builds the action for enabling the module in the Safe
    function _build() internal override {
        ModuleManager(parentMultisig).enableModule(newModule);
    }

    /// @notice Validates that the module was enabled correctly.
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory) internal view override {
        (address[] memory modules, address nextModule) =
            ModuleManager(parentMultisig).getModulesPaginated(SENTINEL_MODULE, 100);
        if (keccak256(abi.encodePacked(ISafe(parentMultisig).VERSION())) == keccak256(abi.encodePacked("1.1.1"))) {
            console.log("[INFO] Old version of safe detected 1.1.1.");
            assertTrue(modules[0] == newModule, "Module not enabled"); // version 1.1.1 doesn't support isModuleEnabled.
        } else {
            assertTrue(ModuleManager(parentMultisig).isModuleEnabled(newModule), "Module not enabled");
        }
        assertEq(nextModule, SENTINEL_MODULE, "Next module not correct");

        bool moduleFound;
        for (uint256 i = 0; i < modules.length; i++) {
            if (modules[i] == newModule) {
                moduleFound = true;
            }
        }
        assertTrue(moduleFound, "Module not found in new modules list");

        IDeputyPauseModule deputyPauseModule = IDeputyPauseModule(newModule);
        assertEq(deputyPauseModule.version(), deputyPauseModuleVersion, "DeputyPauseModule version not correct");
        assertEq(
            address(deputyPauseModule.foundationSafe()),
            simpleAddrRegistry.get(foundationSafeString),
            "DeputyPauseModule foundation safe pointer not correct"
        );
        assertEq(
            address(deputyPauseModule.superchainConfig()),
            simpleAddrRegistry.get("SuperchainConfig"),
            "Superchain config address not correct"
        );

        bytes32 moduleSlot = keccak256(abi.encode(newModule, MODULE_MAPPING_STORAGE_OFFSET));
        bytes32 sentinelSlot = keccak256(abi.encode(SENTINEL_MODULE, MODULE_MAPPING_STORAGE_OFFSET));

        bool moduleWriteFound;

        address[] memory uniqueWrites = accountAccesses.getUniqueWrites(false);
        assertEq(uniqueWrites.length, 1, "should only write to foundation ops safe");
        assertEq(uniqueWrites[0], parentMultisig, "should only write to foundation ops safe address");

        AccountAccessParser.StateDiff[] memory accountWrites = accountAccesses.getStateDiffFor(parentMultisig, false);

        for (uint256 i = 0; i < accountWrites.length; i++) {
            AccountAccessParser.StateDiff memory storageAccess = accountWrites[i];
            if (keccak256(abi.encodePacked(ISafe(parentMultisig).VERSION())) != keccak256(abi.encodePacked("1.1.1"))) {
                assertTrue(
                    storageAccess.slot == NONCE_STORAGE_OFFSET || storageAccess.slot == moduleSlot
                        || storageAccess.slot == sentinelSlot,
                    "Only nonce and module slot should be updated on upgrade controller multisig"
                );
            }
            if (storageAccess.slot == moduleSlot) {
                assertEq(
                    address(uint160(uint256(storageAccess.newValue))),
                    modules.length >= 2 ? modules[1] : SENTINEL_MODULE,
                    "new module not correct"
                );

                bytes32 sentinelModuleValue = vm.load(parentMultisig, sentinelSlot);
                assertEq(
                    sentinelModuleValue, bytes32(uint256(uint160(newModule))), "sentinel does not point to new module"
                );

                moduleWriteFound = true;
            }
        }

        // module write must be found, else revert
        assertTrue(moduleWriteFound, "Module write not found");
    }

    /// @notice No code exceptions for this template
    function getCodeExceptions() internal view override returns (address[] memory) {}
}
