// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SimpleTaskBase} from "src/tasks/types/SimpleTaskBase.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {Action, TemplateConfig, TaskType, TaskPayload, SafeData} from "src/libraries/MultisigTypes.sol";

interface ISaferSafes {
    struct ModuleConfig {
        uint256 livenessResponsePeriod;
        address fallbackOwner;
    }

    function enableModule(address _module) external;
    function setGuard(address _guard) external;
    function configureTimelockGuard(uint256 _timelockDelay) external;
    function configureLivenessModule(ModuleConfig memory _moduleConfig) external;
    function version() external view returns (string memory);
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
    function disableModule(address prevModule, address module) external;
    function isModuleEnabled(address module) external view returns (bool);
    function getGuard() external view returns (address);
    function livenessSafeConfiguration(address safe) external view returns (ModuleConfig memory);
}

interface IMultisig {
    function version() external view returns (string memory);
}

contract MigrateToLiveness2 is SimpleTaskBase {
    using stdToml for string;
    using LibString for string;

    address public saferSafes;
    address public multisig;
    address public currentLivenessModule;

    uint256 public timelockDelay;
    uint256 public livenessResponsePeriod;
    address public fallbackOwner;

    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory writes = new string[](2);
        writes[0] = "targetSafe"; // Safe being modified (enableModule, etc.)
        writes[1] = "saferSafes"; // SaferSafes contract (configureLivenessModule)
        return writes;
    }

    function _getCodeExceptions() internal view override returns (address[] memory) {}

    function safeAddressString() public pure override returns (string memory) {
        return "targetSafe"; // References the custom safe from config.toml
    }

    /// @notice Find the previous module in the linked list
    /// @param moduleToFind The module to find the previous module for
    /// @return The address of the previous module in the linked list
    function _findPrevModule(address moduleToFind) internal view returns (address) {
        address SENTINEL_MODULES = address(0x1);

        (address[] memory modules,) = ISaferSafes(multisig).getModulesPaginated(SENTINEL_MODULES, 100);

        // If the module is the first in the list, previous is sentinel
        if (modules.length > 0 && modules[0] == moduleToFind) {
            return SENTINEL_MODULES;
        }

        // Otherwise, find the module and return the previous one
        for (uint256 i = 1; i < modules.length; i++) {
            if (modules[i] == moduleToFind) {
                return modules[i - 1];
            }
        }

        revert("Module not found in list");
    }

    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        saferSafes = tomlContent.readAddress(".addresses.saferSafes");
        multisig = tomlContent.readAddress(".addresses.targetSafe");
        currentLivenessModule = tomlContent.readAddress(".addresses.currentLivenessModule");

        livenessResponsePeriod = tomlContent.readUint(".livenessModule.livenessResponsePeriod");
        fallbackOwner = tomlContent.readAddress(".livenessModule.fallbackOwner");

        require(address(saferSafes).code.length > 0, "SaferSafes does not have code");
        require(address(currentLivenessModule).code.length > 0, "Current LivenessModule does not have code");
        require(livenessResponsePeriod > 0, "Liveness response period must be greater than 0");
    }

    function _build(address) internal override {
        // Remove the guard first so it doesn't interfere with subsequent operations
        ISaferSafes(multisig).setGuard(address(0));

        // Enable SaferSafes as a module on the safe
        ISaferSafes(multisig).enableModule(saferSafes);

        // Configure the liveness module on SaferSafes
        ISaferSafes.ModuleConfig memory moduleConfig =
            ISaferSafes.ModuleConfig({livenessResponsePeriod: livenessResponsePeriod, fallbackOwner: fallbackOwner});
        ISaferSafes(saferSafes).configureLivenessModule(moduleConfig);

        // Remove the old liveness module
        address prevModule = _findPrevModule(currentLivenessModule);
        ISaferSafes(multisig).disableModule(prevModule, currentLivenessModule);
    }

    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        require(
            ISaferSafes(multisig).isModuleEnabled(saferSafes), "Validation failed: SaferSafes module is not enabled"
        );

        require(
            !ISaferSafes(multisig).isModuleEnabled(currentLivenessModule),
            "Validation failed: Old liveness module is still enabled"
        );

        bytes32 guardSlot = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;
        address guardAddress;
        bytes32 value = vm.load(multisig, guardSlot);
        assembly {
            guardAddress := value
        }
        require(guardAddress == address(0), "Validation failed: Guard was not removed");

        ISaferSafes.ModuleConfig memory config = ISaferSafes(saferSafes).livenessSafeConfiguration(multisig);

        require(
            config.livenessResponsePeriod == livenessResponsePeriod,
            "Validation failed: Liveness response period mismatch"
        );

        require(config.fallbackOwner == fallbackOwner, "Validation failed: Fallback owner mismatch");
    }
}
