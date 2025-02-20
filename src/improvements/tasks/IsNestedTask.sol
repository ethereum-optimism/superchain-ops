// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";
import {Script} from "forge-std/Script.sol";

/// @title IsNestedTask
/// @notice Template contract for checking if a task is nested
contract IsNestedTask is Script {
    /// @notice Returns Useful function to tell if a task is nested or not based on the task config
    function isNestedTask(string memory taskConfigFilePath) public returns (bool) {
        string memory configContent = vm.readFile(taskConfigFilePath);
        bytes memory templateNameRaw = vm.parseToml(configContent, ".templateName");
        string memory templateName = abi.decode(templateNameRaw, (string));

        string memory templatePath = string.concat("out/", templateName, ".sol/", templateName, ".json");
        MultisigTask task = MultisigTask(deployCode(templatePath));
        string memory safeAddressString = task.safeAddressString();

        AddressRegistry _addrRegistry = new AddressRegistry(taskConfigFilePath);
        AddressRegistry.ChainInfo[] memory chains = _addrRegistry.getChains();
        require(chains.length > 0, "MultisigTask: no chains found");
        address parentMultisig = _addrRegistry.getAddress(safeAddressString, chains[0].chainId);
        return task.isNestedSafe(parentMultisig);
    }
}
