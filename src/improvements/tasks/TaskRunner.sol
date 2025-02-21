// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";

contract TaskRunner is Script {
    using Strings for uint256;

    struct L2Chain {
        uint256 chainId;
        string name;
    }

    struct TaskConfig {
        L2Chain[] l2chains;
        string path;
        string templateName;
    }

    function _parseConfig(string memory configPath) internal view returns (TaskConfig memory) {
        string memory configContent = vm.readFile(configPath);
        bytes memory rawL2Chains = vm.parseToml(configContent, ".l2chains");
        L2Chain[] memory l2chains = abi.decode(rawL2Chains, (L2Chain[]));

        bytes memory templateNameRaw = vm.parseToml(configContent, ".templateName");
        string memory templateName = abi.decode(templateNameRaw, (string));

        return TaskConfig({templateName: templateName, l2chains: l2chains, path: configPath});
    }

    function run(string memory network) public {
        string[] memory commands = new string[](2);
        commands[0] = "./src/improvements/script/fetch-tasks.sh";
        commands[1] = network;

        bytes memory result = vm.ffi(commands);

        string[] memory taskPaths = vm.split(string(result), "\n");

        // Process each task
        for (uint256 i = 0; i < taskPaths.length; i++) {
            // Parse config
            TaskConfig memory config = _parseConfig(taskPaths[i]);

            // Deploy and run the template
            string memory templatePath =
                string.concat("out/", config.templateName, ".sol/", config.templateName, ".json");

            MultisigTask task = MultisigTask(deployCode(templatePath));
            task.simulateRun(config.path);
        }
    }

    function run(string memory dumpStatePath, string memory network) public {
        run(network);
        vm.dumpState(dumpStatePath);
    }

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
