// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

abstract contract ITask {
    /// @notice task name, e.g. "BIP15".
    /// @dev override this to set the task name.

    function name() external view virtual returns (string memory);

    /// @notice task description.
    /// @dev override this to set the task description.
    function description() external view virtual returns (string memory);

    /// @notice function to process the task to be called from templates.
    /// @dev use flags to determine which actions to take
    ///      this function shoudn't be overriden.
    function _processTask() internal virtual;

    /// @notice return task actions.
    /// @dev this function shoudn't be overriden.
    function getProposalActions()
        external
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory arguments);

    /// @notice return contract identifiers whose storage is modified by the task
    function getAllowedStorageAccess() external view virtual returns (address[] memory);

    /// @notice return task calldata
    function getCalldata() external virtual returns (bytes memory data);

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

    /// @notice set the task config
    function setTaskConfig(string memory taskConfigFilePath) external virtual;

    /// @notice set the L2 networks config
    function setL2NetworksConfig(string memory networkConfigFilePath, Addresses _addresses) external virtual;
}
