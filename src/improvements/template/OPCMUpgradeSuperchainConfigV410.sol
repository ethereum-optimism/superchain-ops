// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    IOPContractsManager,
    ISuperchainConfig,
    ISystemConfig,
    IProxyAdmin
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

import {OPCMTaskBase} from "src/improvements/tasks/types/OPCMTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice OPCM SuperchainConfig V4.1.0 upgrade template.
/// @dev This template is used to upgrade the SuperchainConfig contract from V3.0.0 or v4.0.0 to V4.1.0.
/// Supports: op-contracts/v4.1.0
contract OPCMUpgradeSuperchainConfigV410 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    ISuperchainConfig public SUPERCHAIN_CONFIG;
    IProxyAdmin public SUPERCHAIN_CONFIG_PROXY_ADMIN;

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "SuperchainConfig";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory tomlContent = vm.readFile(_taskConfigFilePath);

        address OPCM = tomlContent.readAddress(".addresses.OPCM");
        OPCM_TARGETS.push(OPCM);
        require(IOPContractsManager(OPCM).version().eq("3.2.0"), "Incorrect OPCM");
        vm.label(OPCM, "OPCM");

        SUPERCHAIN_CONFIG = ISuperchainConfig(tomlContent.readAddress(".addresses.SuperchainConfig"));
        require(address(SUPERCHAIN_CONFIG).code.length > 0, "Incorrect SuperchainConfig - no code at address");
        vm.label(address(SUPERCHAIN_CONFIG), "SuperchainConfig");

        SUPERCHAIN_CONFIG_PROXY_ADMIN = IProxyAdmin(tomlContent.readAddress(".addresses.SuperchainConfigProxyAdmin"));
        require(
            address(SUPERCHAIN_CONFIG_PROXY_ADMIN).code.length > 0,
            "Incorrect SuperchainConfigProxyAdmin - no code at address"
        );
        vm.label(address(SUPERCHAIN_CONFIG_PROXY_ADMIN), "SuperchainConfigProxyAdmin");
    }

    /// @notice Builds the actions for executing the operations.
    function _build(address) internal override {
        (bool success,) = OPCM_TARGETS[0].delegatecall(
            abi.encodeCall(
                IOPContractManagerV410.upgradeSuperchainConfig, (SUPERCHAIN_CONFIG, SUPERCHAIN_CONFIG_PROXY_ADMIN)
            )
        );
        require(success, "OPCMUpgradeSuperchainConfigV410: Delegatecall failed in _build.");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        require(
            EIP1967Helper.getImplementation(address(SUPERCHAIN_CONFIG))
                == IOPContractsManager(OPCM_TARGETS[0]).implementations().superchainConfigImpl,
            "OPCMUpgradeSuperchainConfigV410: Incorrect SuperchainConfig implementation after upgradeSuperchainConfig"
        );
        require(
            SUPERCHAIN_CONFIG.version().eq("2.3.0"),
            "OPCMUpgradeSuperchainConfigV410: Incorrect SuperchainConfig version after upgradeSuperchainConfig"
        );
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface IOPContractManagerV410 {
    function upgradeSuperchainConfig(ISuperchainConfig _superchainConfig, IProxyAdmin _superchainConfigProxyAdmin)
        external;
}
