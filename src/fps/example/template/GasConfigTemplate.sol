pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";

import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

/// @title GasConfigTemplate
/// @notice Template contract for configuring gas limits
contract GasConfigTemplate is MultisigTask {
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
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "SystemConfigProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with gas configurations from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        GasConfig[] memory gasConfig =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".gasConfigs.gasLimits"), (GasConfig[]));

        for (uint256 i = 0; i < gasConfig.length; i++) {
            gasLimits[gasConfig[i].chainId] = gasConfig[i].gasLimit;
        }
    }

    /// @notice Builds the actions for setting gas limits for a specific L2 chain ID
    /// @param chainId The ID of the L2 chain to configure
    function _build(uint256 chainId) internal override {
        /// View only, filtered out by Proposal.sol
        SystemConfig systemConfig = SystemConfig(addresses.getAddress("SystemConfigProxy", chainId));

        if (gasLimits[chainId] != 0) {
            /// Mutative call, recorded by Proposal.sol for generating multisig calldata
            systemConfig.setGasLimit(gasLimits[chainId]);
        }
    }

    /// @notice Validates that gas limits were set correctly for the specified chain ID
    /// @param chainId The ID of the L2 chain to validate
    function _validate(uint256 chainId) internal view override {
        SystemConfig systemConfig = SystemConfig(addresses.getAddress("SystemConfigProxy", chainId));

        if (gasLimits[chainId] != 0) {
            assertEq(systemConfig.gasLimit(), gasLimits[chainId], "l2 gas limit not set");
        }
    }
}
