// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {SimpleTaskBase} from "src/improvements/tasks/types/SimpleTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A template contract for removing an owner from a Gnosis Safe.
/// More info can be found here: https://docs.safe.global/reference-smart-account/owners/removeOwner
contract GnosisSafeRemoveOwner is SimpleTaskBase {
    using LibString for string;
    using SafeERC20 for IERC20;
    using stdToml for string;

    /// @notice The total number of owners before the task is executed.
    uint256 public totalOwnersBefore;

    /// @notice The owner to remove from the safe.
    address public ownerToRemove;

    /// @notice The threshold of the safe before the task is executed.
    uint256 public thresholdBefore;

    /// @notice Owner that pointed to the owner to be replaced in the linked list
    address public previousOwner;

    /// @notice The address of the first owner in the linked list of owners.
    address internal constant SENTINEL_OWNERS = address(0x1);

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

    /// @notice Sets up the template with the new owner from a TOML file.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory toml = vm.readFile(_taskConfigFilePath);

        totalOwnersBefore = IGnosisSafe(_rootSafe).getOwners().length;
        ownerToRemove = toml.readAddress(".ownerToRemove");
        require(ownerToRemove != address(0), "ownerToRemove must be set in the config file.");
        require(IGnosisSafe(_rootSafe).isOwner(ownerToRemove), "ownerToRemove must be an owner of the safe.");

        thresholdBefore = IGnosisSafe(_rootSafe).getThreshold();
        // Don't want to accidentally brick the safe. Gnosis Safe already enforces this but keeping this check for safety.
        require(totalOwnersBefore - 1 >= thresholdBefore, "Safe after removal must have at least threshold owners.");

        previousOwner = getPreviousOwner(_rootSafe);
        require(previousOwner != address(0), "previousOwner must be set in the config file.");
        checkSupportedVersions(_rootSafe);
    }

    /// @notice Builds the actions for executing the operations.
    function _build(address _rootSafe) internal override {
        IGnosisSafe(_rootSafe).removeOwner(previousOwner, ownerToRemove, thresholdBefore);
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address _rootSafe) internal view override {
        require(!IGnosisSafe(_rootSafe).isOwner(ownerToRemove), "Owner not removed");
        require(IGnosisSafe(_rootSafe).getOwners().length == totalOwnersBefore - 1, "Total owners not decreased");
        require(IGnosisSafe(_rootSafe).getThreshold() == thresholdBefore, "Threshold must be the same");
        require(
            IGnosisSafe(_rootSafe).getOwners().length >= thresholdBefore, "Must have enough owners to cover threshold"
        );
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        // The SecurityCouncils's LivenessGuard stores the list of owner addresses in the `ownersBefore` set.
        // They are then removed in the same execution inside the `checkAfterExecution` function (this is why we don't see them in the state diff).
        // The original writes get analyzed in our `_checkStateDiff` function.
        // Therefore, we have to add the SecurityCouncil's owners addresses as code exceptions.
        address[] memory owners = IGnosisSafe(root).getOwners();
        address[] memory codeExceptions = new address[](owners.length + 1);
        for (uint256 i = 0; i < owners.length; i++) {
            codeExceptions[i] = owners[i];
        }
        // We must add the owner to be removed as a code exception. It's not available in the getOwners() invocation because it was removed at this point.
        codeExceptions[codeExceptions.length - 1] = ownerToRemove;
        return codeExceptions;
    }

    /// @notice Returns the owner that pointed to the owner to be removed in the linked list.
    /// Taken from: https://github.com/ethereum-optimism/optimism/blob/7c59c8c262d4495bf6d982c67cfbd2804b7db1a7/packages/contracts-bedrock/test/safe-tools/SafeTestTools.sol#L213
    function getPreviousOwner(address _rootSafe) public view returns (address) {
        address[] memory owners = IGnosisSafe(_rootSafe).getOwners();
        for (uint256 i; i < owners.length; i++) {
            if (owners[i] != ownerToRemove) continue;
            if (i == 0) {
                return SENTINEL_OWNERS;
            }
            return owners[i - 1];
        }
        revert(string.concat("Owner ", vm.toString(ownerToRemove), " not found in the safe: ", vm.toString(_rootSafe)));
    }

    /// @notice Checks if the safe version is supported for removing owners.
    /// This check is added to force the task developer to understand the version of the safe they're using. It's meant to act as an additional layer of safety.
    function checkSupportedVersions(address _rootSafe) public view {
        string[] memory supportedVersions = new string[](3);
        supportedVersions[0] = "1.3.0"; // https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/base/OwnerManager.sol#L70
        supportedVersions[1] = "1.4.1"; // https://github.com/safe-global/safe-smart-account/blob/v1.4.1/contracts/base/OwnerManager.sol#L78
        supportedVersions[2] = "1.1.1"; // https://github.com/safe-global/safe-smart-account/blob/v1.1.1/contracts/base/OwnerManager.sol#L74
        string memory version = IGnosisSafe(_rootSafe).VERSION();
        for (uint256 i; i < supportedVersions.length; i++) {
            if (supportedVersions[i].eq(version)) return;
        }
        // If the version is not in the supported list of versions it may not support removing owners. Please manually check if your safe version supports removing owners.
        // If it does and the removeOwner function does not contain any breaking changes, please update the supported versions list above to include the new version.
        revert(string.concat("Safe must version is not in the supported list of versions. Current version: ", version));
    }
}
