pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/improvements/AddressRegistry.sol";

/// @title SetGasConfigTemplate
/// @notice Template contract for configuring the protocol
contract SetGasConfigTemplate is MultisigTask {
    /// @notice Struct to store gas configurations for specific chain
    /// @param chainId The chain ID for the configuration
    /// @param overhead The new overhead value
    /// @param scalar The new scalar value
    struct GasConfig {
        uint256 chainId;
        uint256 overhead;
        bytes32 scalar;
    }

    /// @notice Mapping of chain IDs to their respective gas limits
    /// @dev Maps L2 chain ID to its configured gas limit
    mapping(uint256 => GasConfig) public gasLimits;

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
        GasConfig[] memory gasConfig =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".gasConfigs"), (GasConfig[]));

        for (uint256 i = 0; i < gasConfig.length; i++) {
            require(
                gasLimits[gasConfig[i].chainId].overhead == 0 && uint256(gasLimits[gasConfig[i].chainId].scalar) == 0,
                "chain already configured"
            );
            gasLimits[gasConfig[i].chainId] = gasConfig[i];
        }
    }

    /// @notice Builds the actions for setting gas limits for a specific L2 chain ID
    /// @param chainId The ID of the L2 chain to configure
    function _build(uint256 chainId) internal override {
        /// View only, filtered out by MultisigTask.sol
        SystemConfig systemConfig = SystemConfig(addresses.getAddress("SystemConfigProxy", chainId));

        /// Mutative call, recorded by MultisigTask.sol for generating multisig calldata
        systemConfig.setGasConfig(gasLimits[chainId].overhead, uint256(gasLimits[chainId].scalar));
    }

    /// @notice Validates that gas limits were set correctly for the specified chain ID
    /// @param chainId The ID of the L2 chain to validate
    function _validate(uint256 chainId) internal view override {
        SystemConfig systemConfig = SystemConfig(addresses.getAddress("SystemConfigProxy", chainId));

        assertEq(systemConfig.overhead(), gasLimits[chainId].overhead, "l2 overhead not set correctly");
        assertEq(systemConfig.scalar(), uint256(gasLimits[chainId].scalar), "l2 scalar not set correctly");
    }
}
