// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";

/// @title EmptyTemplate
/// @notice A template contract for configuring protocol parameters.
///         This file is intentionally stripped down; please add your logic where indicated.
contract EmptyTemplate is MultisigTask {
    /// @notice TODO: Define the struct fields for your task configuration.
    /// (e.g., chainId, gas, implementation, gameType, etc.)
    struct ExampleTaskConfig {
        uint256 chainId;
    }

    /// @notice TODO: Update the mapping key/value types as needed.
    mapping(uint256 => ExampleTaskConfig) public exampleTaskConfig;

    /// @notice Returns the safe address string identifier.
    /// @return A string identifier.
    function safeAddressString() public pure override returns (string memory) {
        require(
            false,
            "TODO: Return the actual safe address string identifier as defined in Superchain-Registry's addresses.json."
        );
        /// Superchain-Registry's addresses.json.
        return "ProxyAdminOwner"; // TODO: This is an example. Change according to your task.
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        require(false, "TODO: Populate this array with actual storage permission identifiers.");
        string[] memory storageWrites = new string[](1);
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal pure override {
        require(
            false,
            "TODO: Implement the logic to parse the configuration file and populate the `exampleTaskConfig` mapping."
        );
        taskConfigFilePath;
    }

    /// @notice Builds the actions for a specific L2 chain ID
    /// @param chainId The ID of the L2 chain to configure
    function _buildPerChain(uint256 chainId) internal pure override {
        // Delete this function if _buildSingle() is implemented.
        require(false, "TODO: Implement logic that executes per chain.");
        chainId;
    }
    /// @notice Builds the task action for all l2chains in the task.
    /// @dev Normally implemented as part of OPCM templates.

    function _buildSingle() internal pure override {
        // Delete this function if _buildPerChain() is implemented.
        require(false, "TODO: Normally implemented as part of OPCM templates. Executes logic for all chains.");
    }

    /// @notice Validates that implementations were set correctly for the specified chain ID
    /// @param chainId The ID of the L2 chain to validate
    function _validate(uint256 chainId) internal pure override {
        require(false, "TODO: Implement the logic to validate that the configuration was set as expected.");
        chainId;
    }
}
