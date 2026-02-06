// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";
import {Utils} from "src/libraries/Utils.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {SimpleTaskBase} from "src/tasks/types/SimpleTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice Template for swapping multiple Safe signers in a single atomic transaction.
/// @dev Uses multicall to batch multiple swapOwner operations. The framework automatically
///      converts multiple swapOwner() calls in _build() into a single multicall transaction.
contract GnosisSafeRotateMultipleSigners is SimpleTaskBase {
    using LibString for string;
    using stdToml for string;

    /// @notice The total number of owners before the task is executed.
    uint256 public totalOwnersBefore;

    /// @notice The threshold of the safe before the task is executed.
    uint256 public thresholdBefore;

    /// @notice Array of owners to remove from the safe.
    address[] public ownersToRemove;

    /// @notice Array of new owners to add to the safe.
    address[] public ownersToAdd;

    /// @notice Pre-computed array of previous owners for each owner to remove.
    /// @dev These are calculated from the initial state before any swaps occur.
    address[] public previousOwners;

    /// @notice Cache of initial owner list for validation.
    address[] internal initialOwners;

    /// @notice Additional code exceptions to add to the task.
    address[] internal additionalCodeExceptions;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        revert("safeAddressString must be set in the config file");
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "LivenessGuard";
        return storageWrites;
    }

    /// @notice Sets up the template with configuration from a TOML file.
    /// @dev Validates inputs and pre-computes all previousOwner values from initial state.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory toml = vm.readFile(_taskConfigFilePath);

        // Read arrays from TOML
        ownersToRemove = toml.readAddressArray(".ownersToRemove");
        ownersToAdd = toml.readAddressArray(".ownersToAdd");

        // Validation 1: Basic array checks
        require(ownersToRemove.length > 0, "Must specify at least one owner to remove");
        require(ownersToRemove.length == ownersToAdd.length, "Arrays must be equal length");

        // Validation 2: No duplicates within arrays
        _checkNoDuplicates(ownersToRemove);
        _checkNoDuplicates(ownersToAdd);

        // Validation 3: No overlap between remove and add arrays
        for (uint256 i = 0; i < ownersToRemove.length; i++) {
            for (uint256 j = 0; j < ownersToAdd.length; j++) {
                require(ownersToRemove[i] != ownersToAdd[j], "Cannot remove and add same owner");
            }
        }

        // Store initial state for validation
        initialOwners = IGnosisSafe(_rootSafe).getOwners();
        totalOwnersBefore = initialOwners.length;
        thresholdBefore = IGnosisSafe(_rootSafe).getThreshold();

        // Validation 4: All ownersToRemove are current owners
        for (uint256 i = 0; i < ownersToRemove.length; i++) {
            require(ownersToRemove[i] != address(0), "Cannot remove zero address");
            require(
                IGnosisSafe(_rootSafe).isOwner(ownersToRemove[i]),
                string.concat("Address not an owner: ", vm.toString(ownersToRemove[i]))
            );
        }

        // Validation 5: None of ownersToAdd are current owners
        for (uint256 i = 0; i < ownersToAdd.length; i++) {
            require(ownersToAdd[i] != address(0), "Cannot add zero address");
            require(
                !IGnosisSafe(_rootSafe).isOwner(ownersToAdd[i]),
                string.concat("Already an owner: ", vm.toString(ownersToAdd[i]))
            );
        }

        // PRE-COMPUTE all previousOwners from initial state
        // This is critical: calculate before any swaps to handle linked list correctly
        previousOwners = new address[](ownersToRemove.length);
        for (uint256 i = 0; i < ownersToRemove.length; i++) {
            previousOwners[i] = Utils.getPreviousOwner(_rootSafe, ownersToRemove[i]);
            require(
                previousOwners[i] != address(0),
                string.concat("Failed to find previous owner for: ", vm.toString(ownersToRemove[i]))
            );
        }

        // Version compatibility check
        checkSupportedVersions(_rootSafe);

        // Code exceptions: initial owners + new owners
        for (uint256 i = 0; i < initialOwners.length; i++) {
            additionalCodeExceptions.push(initialOwners[i]);
        }
        for (uint256 i = 0; i < ownersToAdd.length; i++) {
            additionalCodeExceptions.push(ownersToAdd[i]);
        }
    }

    /// @notice Builds the actions for executing the operations.
    /// @dev Framework automatically captures each swapOwner call as an Action and converts
    ///      the Action[] to a multicall transaction via MultisigTask._getMulticall3Calldata().
    ///      Handles the case where a removed owner is the previousOwner for another removed owner
    ///      by updating previousOwner references after each swap.
    function _build(address _rootSafe) internal override {
        // Create a mutable copy of previousOwners to handle dependencies
        address[] memory currentPreviousOwners = new address[](previousOwners.length);
        for (uint256 i = 0; i < previousOwners.length; i++) {
            currentPreviousOwners[i] = previousOwners[i];
        }

        // Execute swaps and update previousOwner references for remaining swaps
        for (uint256 i = 0; i < ownersToRemove.length; i++) {
            IGnosisSafe(_rootSafe).swapOwner(currentPreviousOwners[i], ownersToRemove[i], ownersToAdd[i]);

            // After swapping, if any remaining owner's previousOwner was the owner we just removed,
            // update it to point to the new owner that took its place
            for (uint256 j = i + 1; j < ownersToRemove.length; j++) {
                if (currentPreviousOwners[j] == ownersToRemove[i]) {
                    currentPreviousOwners[j] = ownersToAdd[i];
                }
            }
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address _rootSafe) internal view override {
        address[] memory finalOwners = IGnosisSafe(_rootSafe).getOwners();

        // Check 1: Total count unchanged (swap only, not add/remove)
        require(
            finalOwners.length == totalOwnersBefore,
            string.concat(
                "Total owners changed: expected ",
                vm.toString(totalOwnersBefore),
                " got ",
                vm.toString(finalOwners.length)
            )
        );

        // Check 2: Threshold unchanged
        uint256 finalThreshold = IGnosisSafe(_rootSafe).getThreshold();
        require(
            finalThreshold == thresholdBefore,
            string.concat(
                "Threshold changed: expected ", vm.toString(thresholdBefore), " got ", vm.toString(finalThreshold)
            )
        );

        // Check 3: Sufficient owners for threshold
        require(finalOwners.length >= thresholdBefore, "Not enough owners to meet threshold");

        // Check 4: All ownersToRemove are gone
        for (uint256 i = 0; i < ownersToRemove.length; i++) {
            require(
                !IGnosisSafe(_rootSafe).isOwner(ownersToRemove[i]),
                string.concat("Failed to remove owner: ", vm.toString(ownersToRemove[i]))
            );
        }

        // Check 5: All ownersToAdd are present
        for (uint256 i = 0; i < ownersToAdd.length; i++) {
            require(
                IGnosisSafe(_rootSafe).isOwner(ownersToAdd[i]),
                string.concat("Failed to add owner: ", vm.toString(ownersToAdd[i]))
            );
        }

        // Check 6: Exact owner set validation
        // Expected = (initial - removed + added)
        _validateExactOwnerSet(finalOwners);
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        // The SecurityCouncils's LivenessGuard stores the list of owner addresses in the `ownersBefore` set.
        // They are then removed in the same execution inside the `checkAfterExecution` function (this is why we don't see them in the state diff).
        // The original writes get analyzed in our `_checkStateDiff` function.
        // Therefore, we have to add the SecurityCouncil's owners addresses as code exceptions.
        return additionalCodeExceptions;
    }

    /// @notice Validates that the final owner set exactly matches the expected set.
    /// @dev Expected = (initial owners - removed owners + added owners)
    function _validateExactOwnerSet(address[] memory finalOwners) internal view {
        // For each final owner, verify it's expected
        for (uint256 i = 0; i < finalOwners.length; i++) {
            bool isExpected = _isExpectedOwner(finalOwners[i]);
            require(isExpected, string.concat("Unexpected owner in final set: ", vm.toString(finalOwners[i])));
        }
    }

    /// @notice Checks if an address is an expected owner in the final set.
    /// @dev An owner is expected if it's either in ownersToAdd, or was in initialOwners and not in ownersToRemove.
    function _isExpectedOwner(address owner) internal view returns (bool) {
        // Check if in ownersToAdd
        for (uint256 i = 0; i < ownersToAdd.length; i++) {
            if (owner == ownersToAdd[i]) return true;
        }

        // Check if was initial owner
        bool wasInitial = false;
        for (uint256 i = 0; i < initialOwners.length; i++) {
            if (owner == initialOwners[i]) {
                wasInitial = true;
                break;
            }
        }
        if (!wasInitial) return false;

        // Check not in ownersToRemove
        for (uint256 i = 0; i < ownersToRemove.length; i++) {
            if (owner == ownersToRemove[i]) return false;
        }

        return true;
    }

    /// @notice Checks for duplicate addresses in an array.
    /// @dev Reverts if any duplicates are found.
    function _checkNoDuplicates(address[] memory addrs) internal pure {
        for (uint256 i = 0; i < addrs.length; i++) {
            for (uint256 j = i + 1; j < addrs.length; j++) {
                require(addrs[i] != addrs[j], string.concat("Duplicate address: ", vm.toString(addrs[i])));
            }
        }
    }

    /// @notice Checks if the safe version is supported for swapping owners.
    /// @dev This check forces the task developer to understand the version of the safe they're using.
    ///      It acts as an additional layer of safety.
    function checkSupportedVersions(address _rootSafe) public view {
        string[] memory supportedVersions = new string[](3);
        supportedVersions[0] = "1.3.0"; // https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/base/OwnerManager.sol#L70
        supportedVersions[1] = "1.4.1"; // https://github.com/safe-global/safe-smart-account/blob/v1.4.1/contracts/base/OwnerManager.sol#L78
        supportedVersions[2] = "1.1.1"; // https://github.com/safe-global/safe-smart-account/blob/v1.1.1/contracts/base/OwnerManager.sol#L74

        string memory version = IGnosisSafe(_rootSafe).VERSION();
        for (uint256 i; i < supportedVersions.length; i++) {
            if (supportedVersions[i].eq(version)) return;
        }

        // If the version is not in the supported list of versions it may not support swapping owners. Please manually check if your safe version supports swapping owners.
        // If it does and the swapOwner function does not contain any breaking changes, please update the supported versions list above to include the new version.
        revert(string.concat("Safe version is not in the supported list of versions. Current version: ", version));
    }
}
