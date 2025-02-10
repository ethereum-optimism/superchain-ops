pragma solidity 0.8.15;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/improvements/AddressRegistry.sol";

/// @title SafeOwnerThresholdTemplate
/// @notice Template contract for managing Safe owners and threshold
contract SafeOwnerThresholdTemplate is MultisigTask {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Struct to store Safe configuration for owner management
    /// @param addressesToAdd Array of owner addresses to add
    /// @param addressesToRemove Array of owner addresses to remove
    /// @param newThreshold New threshold value (0 to keep current threshold)
    /// @param safeAddress Address of the Safe to configure
    struct SafeConfig {
        address[] addressesToAdd;
        address[] addressesToRemove;
        uint256 newThreshold;
        /// address of the safe to be configured
        address safeAddress;
    }

    struct L2Chain {
        uint256 chainId;
        string name;
    }

    /// @notice Safe configuration for the current task
    SafeConfig public safeConfig;

    /// @notice Returns the safe address string identifier
    /// @return The string "SystemConfigOwner"
    function safeAddressString() public pure override returns (string memory) {
        /// this value is overridden and not used in this template
        return "SystemConfigOwner";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](0);
        return storageWrites;
    }

    /// @notice Sets up the template with Safe configuration from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file for the task
    function _templateSetup(string memory taskConfigFilePath) internal override {
        string memory configContent = vm.readFile(taskConfigFilePath);
        SafeConfig memory config = abi.decode(vm.parseToml(configContent, ".safeConfig"), (SafeConfig));

        require(
            config.addressesToAdd.length >= 1 || config.addressesToRemove.length >= 1 || config.newThreshold >= 1,
            "Config file must modify safe"
        );
        require(config.safeAddress != address(0), "Safe address must be set");

        safeConfig = config;

        uint256 newOwnerCount = IGnosisSafe(safeConfig.safeAddress).getOwners().length
            + safeConfig.addressesToAdd.length - safeConfig.addressesToRemove.length;
        require(newOwnerCount >= 1 && newOwnerCount >= config.newThreshold, "Safe new threshold must be in range");

        /// We can't reliably count on the safe address being in the AddressRegistry,
        /// because child safes, which own the parent safes will not be in the AddressRegistry,
        /// so a task developer specifies this in their task config toml file,
        /// and we add it to the allowedStorageAccesses.
        _allowedStorageAccesses.add(safeConfig.safeAddress);

        bytes memory rawL2Chains = vm.parseToml(configContent, ".l2chains");
        L2Chain[] memory l2chains = abi.decode(rawL2Chains, (L2Chain[]));
        require(l2chains.length == 1, "Only one chain is supported for this Safe task");
    }

    /// @notice Builds the actions for managing Safe owners and threshold
    /// param chainId. The chain ID (unused in this template)
    function _build(uint256) internal override {
        // Get the minimum length between add and remove arrays
        uint256 minLength = Math.min(safeConfig.addressesToAdd.length, safeConfig.addressesToRemove.length);

        // First handle swaps for the amount of intersecting owners
        for (uint256 i = 0; i < minLength; i++) {
            address prevOwner = _getPreviousOwner(safeConfig.addressesToRemove[i]);
            IGnosisSafe(multisig).swapOwner(prevOwner, safeConfig.addressesToRemove[i], safeConfig.addressesToAdd[i]);
        }

        // Remove any remaining owners
        for (uint256 i = minLength; i < safeConfig.addressesToRemove.length; i++) {
            address[] memory owners = IGnosisSafe(multisig).getOwners();
            uint256 currentThreshold = IGnosisSafe(multisig).getThreshold();

            // if we are removing an owner and decreasing the threshold and we
            // do not have a target threshold, set it to the current threshold
            // so that we can remember this threshold when we set the new
            // threshold at the end.
            if (currentThreshold == owners.length && safeConfig.newThreshold == 0) {
                safeConfig.newThreshold = currentThreshold;
            }

            currentThreshold = currentThreshold == owners.length ? currentThreshold - 1 : currentThreshold;

            address prevOwner = _getPreviousOwner(safeConfig.addressesToRemove[i]);
            IGnosisSafe(multisig).removeOwner(prevOwner, safeConfig.addressesToRemove[i], currentThreshold);
        }

        {
            uint256 currentThreshold = IGnosisSafe(multisig).getThreshold();

            // Add any remaining owners
            for (uint256 i = minLength; i < safeConfig.addressesToAdd.length; i++) {
                IGnosisSafe(multisig).addOwnerWithThreshold(safeConfig.addressesToAdd[i], currentThreshold);
            }
        }

        // If threshold needs to be updated
        if (safeConfig.newThreshold != 0) {
            // This call should never revert because we have already validated
            // the new threshold after adding and removing all of the owners.
            IGnosisSafe(multisig).changeThreshold(safeConfig.newThreshold);
        }
    }

    /// @notice Validates the Safe configuration
    /// param The chain ID (unused in this template)
    function _validate(uint256) internal view override {
        // check that all expected owners were added
        for (uint256 i = 0; i < safeConfig.addressesToAdd.length; i++) {
            assertTrue(IGnosisSafe(multisig).isOwner(safeConfig.addressesToAdd[i]), "Owner not added");
        }

        // check that all expected owners were removed
        for (uint256 i = 0; i < safeConfig.addressesToRemove.length; i++) {
            assertFalse(IGnosisSafe(multisig).isOwner(safeConfig.addressesToRemove[i]), "Owner not removed");
        }

        /// check that if the threshold was updated, it was updated correctly
        if (safeConfig.newThreshold != 0) {
            assertEq(IGnosisSafe(multisig).getThreshold(), safeConfig.newThreshold, "Threshold not set correctly");
        }
    }

    /// @notice Helper function to get the previous owner in the linked list
    /// for this template's safe
    /// @param owner The owner to find the previous owner for
    /// @return The address of the previous owner in the linked list
    function _getPreviousOwner(address owner) private view returns (address) {
        address[] memory owners = IGnosisSafe(multisig).getOwners();
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i + 1] == owner) {
                return owners[i];
            }
        }
        revert("Owner not found");
    }
}
