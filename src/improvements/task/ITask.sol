// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {AddressRegistry as Addresses} from "src/improvements/AddressRegistry.sol";

abstract contract ITask {
    /// @notice return task actions.
    /// @dev this function shoudn't be overriden.
    function getTaskActions()
        external
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory arguments);

    /// @notice return contract identifiers whose storage is modified by the task
    function getAllowedStorageAccess() external view virtual returns (address[] memory);

    /// @notice return task calldata
    function getCalldata() external virtual returns (bytes memory data);

    /// @notice runs all task steps
    /// 1. builds, simulates, validates and then prints the task
    function run(string memory taskConfigFilePath) external virtual;

    /// @notice build the task actions
    /// @dev contract calls must be perfomed in plain solidity.
    ///      overriden requires using buildModifier modifier to leverage
    ///      foundry snapshot and state diff recording to populate the actions array.
    function build() external virtual;

    /// @notice actually simulates the task.
    ///         e.g. schedule and execute on Timelock Controller,
    ///         proposes, votes and execute on Governor Bravo, etc.
    function simulate() external virtual;

    /// @notice execute post-task checks.
    ///          e.g. read state variables of the changed contracts to make
    ///          sure the state transitions happened correctly, or read
    ///          states that are expected to have changed during the simulate step.
    function validate() external virtual;

    /// @notice print task description, actions and calldata
    function print() external virtual;
}
