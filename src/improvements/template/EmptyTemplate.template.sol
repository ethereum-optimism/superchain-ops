// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";

/// @title EmptyTemplate
/// @notice A template contract for configuring protocol parameters.
///         This file is intentionally stripped down; please add your logic where indicated.
contract EmptyTemplate is MultisigTask {
    /// @notice TODO: Define the struct fields for your task configuration.
    struct TaskConfig {
        // TODO: Add members this template needs
        // (e.g., chainId, gas, implementation, gameType, etc.)
    }

    /// @notice TODO: Update the mapping key/value types as needed.
    mapping(uint256 => TaskConfig) public taskConfig;

    /// @notice Returns the safe address string identifier.
    /// @return A string identifier.
    function safeAddressString() public pure override returns (string memory) {
        require(false, "TODO: Return the actual safe address string identifier as defined in Superchain-Registry's addresses.json.");
        /// Superchain-Registry's addresses.json.
        // return "ProxyAdminOwner";
    }

    /// @notice Specifies the storage write permissions required for this task.
    /// @return An array of strings representing the storage permissions.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        require(false, "TODO: Populate this array with actual storage permission identifiers.");
        // string[] memory storageWrites = new string[](1);
        // return storageWrites;
    }

    /// @notice Sets up the template using configuration data from a file.
    /// @param taskConfigFilePath The path to the configuration file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        require(false, "TODO: Implement the logic to parse the configuration file and populate the `taskConfig` mapping.");
    }

    /// @notice Implement one of _buildPerChain() or _buildSingle()
    function _buildPerChain(uint256 chainId) internal override {
        // Delete this function if _buildSingle() is implemented.
        require(false, "TODO: Implement logic that executes per chain.");
    }
    function _buildSingle() internal override {
        // Delete this function if _buildPerChain() is implemented.
        require(false, "TODO: Normally implemented as part of OPCM templates. Executes logic for all chains.");
    }

    /// @notice Validates that the configuration has been applied correctly.
    /// @param chainId The chain ID to validate.
    function _validate(uint256 chainId) internal view override {
        require(false, "TODO: Implement the logic to validate that the configuration was set as expected.");
    }
}
