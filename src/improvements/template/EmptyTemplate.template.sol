// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";

/// @notice A template contract for configuring protocol parameters.
///         This file is intentionally stripped down; please add your logic where indicated.
///         Please make sure to address all TODOs and remove the require() statements.
contract EmptyTemplate is MultisigTask {
    /// @notice TODO: Define the struct fields for your task configuration.
    /// (e.g., chainId, gas, implementation, gameType, etc.)
    struct ExampleTaskConfig {
        uint256 chainId;
    }

    /// @notice TODO: Update the mapping key/value types as needed.
    mapping(uint256 => ExampleTaskConfig) public exampleTaskConfig;

    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        require(
            false,
            "TODO: Return the actual safe address string identifier as defined in Superchain-Registry's addresses.json."
        );
        // See superchain-registry's 'addresses.json' for allowed safe address strings.
        return "ProxyAdminOwner"; // TODO: This is an example. Change according to your task.
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        require(false, "TODO: Populate this array with actual storage permission identifiers.");
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "SystemConfigProxy"; // TODO: This is an example. Change according to your task.
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal pure override {
        require(
            false,
            "TODO: Implement the logic to parse the configuration file and populate the `exampleTaskConfig` mapping."
        );
        taskConfigFilePath;
    }

    /// @notice Write the calls that you want to execute for each l2chain in the task.
    /// These can be written as standard Solidity calls and then get parsed as calldata.
    function _buildPerChain(uint256 chainId) internal pure override {
        // Delete this function if _buildSingle() is implemented.
        require(false, "TODO: Implement logic that executes per chain.");
        chainId;
    }
    /// @notice Write the calls that you want to execute one time.
    /// These can be written as standard Solidity calls and then get parsed as calldata.

    function _buildSingle() internal pure override {
        // Delete this function if _buildPerChain() is implemented.
        require(false, "TODO: Normally implemented as part of OPCM templates. Executes logic for all chains.");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(uint256 chainId) internal pure override {
        require(false, "TODO: Implement the logic to validate that the configuration was set as expected.");
        chainId;
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal pure override returns (address[] memory) {
        require(
            false, "TODO: Implement the logic to return a list of addresses that should not be checked for code length."
        );
        address[] memory codeExceptions = new address[](1);
        codeExceptions[0] = address(0);
        return codeExceptions;
    }
}
