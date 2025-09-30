// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {SimpleTaskBase} from "src/tasks/types/SimpleTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A template to help users onboard to SuperchainOps.
contract WelcomeToSuperchainOps is SimpleTaskBase {
    using LibString for string;
    using SafeERC20 for IERC20;
    using stdToml for string;

    /// @notice The name of the user.
    string public name;

    /// @notice The address of the TargetContract contract.
    ITargetContract public targetContract;

    /// @notice Additional code exceptions to add to the task.
    address[] internal additionalCodeExceptions;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "SecurityCouncil";
    }

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "TargetContract";
        storageWrites[1] = "LivenessGuard";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {
        return new string[](0);
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);

        string memory toml = vm.readFile(_taskConfigFilePath);
        name = abi.decode(vm.parseToml(toml, ".name"), (string));
        targetContract = ITargetContract(payable(simpleAddrRegistry.get("TargetContract")));

        address[] memory owners = IGnosisSafe(_rootSafe).getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            additionalCodeExceptions.push(owners[i]);
        }
    }

    /// @notice Builds the template. Actions to perform on the target contract.
    function _build(address) internal override {
        targetContract.setName(name);
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        string memory welcomeMessage = targetContract.welcome();
        require(welcomeMessage.eq(string.concat("Welcome to SuperchainOps, ", name)), "Welcome message does not match");
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        // The SecurityCouncils's LivenessGuard stores the list of owner addresses in the `ownersBefore` set.
        // They are then removed in the same execution inside the `checkAfterExecution` function (this is why we don't see them in the state diff).
        // The original writes get analyzed in our `_checkStateDiff` function.
        // Therefore, we have to add the SecurityCouncil's owners addresses as code exceptions.
        return additionalCodeExceptions;
    }
}

interface ITargetContract {
    function setName(string memory _name) external;
    function welcome() external view returns (string memory);
}
