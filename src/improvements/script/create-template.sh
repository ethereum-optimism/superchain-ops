#!/usr/bin/env bash

create_template() {
    while true; do
        if [ -t 0 ]; then
            echo ""
            read -r -p "Enter template file name (e.g. <template_name>.sol): " filename
        else
            read -r filename
        fi
        if [[ "$filename" == *.sol ]]; then
            contract_name="${filename%.sol}"
            template_path="template/$filename"

            # Create the template file with the default Solidity code
            cat > "$template_path" << EOL
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";

/// @title ${contract_name}
/// @notice A template contract for configuring protocol parameters.
///         This file is intentionally stripped down; please add your logic where indicated.
contract ${contract_name} is MultisigTask {
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
        // Superchain-Registry's addresses.json.
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
        require(false, "TODO: Implement the logic to parse the configuration file and populate the \`taskConfig\` mapping.");
    }

    /// @notice Builds the action(s) for applying the configuration for a given chain ID.
    /// @param chainId The chain ID for which to build the configuration actions.
    function _build(uint256 chainId) internal override {
        require(false, "TODO: Implement the logic to build the configuration action(s).");
    }

    /// @notice Validates that the configuration has been applied correctly.
    /// @param chainId The chain ID to validate.
    function _validate(uint256 chainId) internal view override {
        require(false, "TODO: Implement the logic to validate that the configuration was set as expected.");
    }
}
EOL
            absolute_path=$(realpath "$template_path")
            echo -e "\n\033[32mTemplate created at:\033[0m"
            echo "$absolute_path"
            break
        else
            echo -e "\n\033[31mTemplate file cannot be empty and must end with '.sol'. Please try again.\033[0m"
        fi
    done
}

# Run this function only if someone runs this script directly,
# not when it's imported by another script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_template
fi
