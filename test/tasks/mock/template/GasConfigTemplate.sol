// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @title GasConfigTemplate
/// @notice Template contract for configuring gas limits
contract GasConfigTemplate is L2TaskBase {
    /// @notice Struct to store gas limits to be set for a specific L2 chain ID
    /// @param chainId The ID of the L2 chain
    /// @param gasLimit The gas limit to be set for the chain
    struct GasConfig {
        uint256 chainId;
        uint64 gasLimit;
    }

    /// @notice Mapping of chain IDs to their respective gas limits
    /// @dev Maps L2 chain ID to its configured gas limit
    mapping(uint256 => uint64) public gasLimits;

    /// @notice Returns the safe address string identifier
    /// @return The string "SystemConfigOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "SystemConfigOwner";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "SystemConfigProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with gas configurations from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        GasConfig[] memory gasConfig =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".gasConfigs.gasLimits"), (GasConfig[]));

        for (uint256 i = 0; i < gasConfig.length; i++) {
            gasLimits[gasConfig[i].chainId] = gasConfig[i].gasLimit;
        }
    }

    /// @notice Builds the actions for setting gas limits.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            SystemConfig systemConfig = SystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId));
            if (gasLimits[chainId] != 0) {
                // Mutative call, recorded by MultisigTask.sol for generating multisig calldata
                systemConfig.setGasLimit(gasLimits[chainId]);
            }
        }
    }

    /// @notice Validates that gas limits were set correctly for the specified chain ID
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            SystemConfig systemConfig = SystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId));
            if (gasLimits[chainId] != 0) {
                assertEq(systemConfig.gasLimit(), gasLimits[chainId], "l2 gas limit not set");
            }
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
