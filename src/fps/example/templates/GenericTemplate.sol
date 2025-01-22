pragma solidity 0.8.15;

import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

abstract contract GenericTemplate is MultisigTask {
    /// @notice Runs the proposal with the given task and network configuration file paths. Sets the address registry, initializes the proposal and processes the proposal.
    /// @param taskConfigFilePath The path to the task configuration file.
    /// @param networkConfigFilePath The path to the network configuration file.
    function run(string memory taskConfigFilePath, string memory networkConfigFilePath) public {
        Addresses _addresses = new Addresses(networkConfigFilePath);

        _templateSetup(taskConfigFilePath, networkConfigFilePath, _addresses);

        _init(taskConfigFilePath, networkConfigFilePath, _addresses);

        _processTask();
    }

    /// @notice abstract function to be implemented by the inheriting contract to setup the template
    function _templateSetup(string memory taskConfigFilePath, string memory networkConfigFilePath, Addresses)
        internal
        virtual;
}
