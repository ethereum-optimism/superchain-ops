// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {SimpleAddressRegistry} from "src/improvements/SimpleAddressRegistry.sol";

/// This script gathers all tasks for a given network and performs a simulation run for each task.
/// This file can only simulate tasks for one network at a time (found under src/improvements/tasks/{network}).
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
        address parentMultisig;
        bool isNested;
    }

    function _parseConfig(string memory configPath) internal returns (TaskConfig memory) {
        string memory configContent = vm.readFile(configPath);
        bytes memory rawL2Chains = vm.parseToml(configContent, ".l2chains");
        L2Chain[] memory l2chains = abi.decode(rawL2Chains, (L2Chain[]));

        bytes memory templateNameRaw = vm.parseToml(configContent, ".templateName");
        string memory templateName = abi.decode(templateNameRaw, (string));

        (bool isNested, address parentMultisig) = isNestedTask(configPath);

        return TaskConfig({
            templateName: templateName,
            l2chains: l2chains,
            path: configPath,
            isNested: isNested,
            parentMultisig: parentMultisig
        });
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

            executeTask(task, config);
        }
    }

    /// @notice Executes a task based on its configuration.
    function executeTask(MultisigTask task, TaskConfig memory config) internal {
        if (config.isNested) {
            IGnosisSafe parentMultisig = IGnosisSafe(config.parentMultisig);
            address[] memory owners = parentMultisig.getOwners();
            require(
                owners.length > 0,
                string.concat(
                    "TaskRunner: No owners found for parent multisig: ",
                    Strings.toHexString(uint256(uint160(config.parentMultisig)), 20)
                )
            );
            task.signFromChildMultisig(config.path, owners[0]);
        } else {
            task.simulateRun(config.path);
        }
    }

    /// @notice Useful function to tell if a task is nested or not based on the task config.
    function isNestedTask(string memory taskConfigFilePath) public returns (bool, address parentMultisig) {
        string memory configContent = vm.readFile(taskConfigFilePath);
        bytes memory templateNameRaw = vm.parseToml(configContent, ".templateName");
        string memory templateName = abi.decode(templateNameRaw, (string));

        string memory templatePath = string.concat("out/", templateName, ".sol/", templateName, ".json");
        MultisigTask task = MultisigTask(deployCode(templatePath));
        string memory safeAddressString = task.safeAddressString();
        MultisigTask.TaskType taskType = task.taskType();

        if (taskType == MultisigTask.TaskType.SimpleTaskBase) {
            SimpleAddressRegistry _simpleAddrRegistry = new SimpleAddressRegistry(taskConfigFilePath);
            parentMultisig = _simpleAddrRegistry.get(safeAddressString);
        } else {
            SuperchainAddressRegistry _addrRegistry = new SuperchainAddressRegistry(taskConfigFilePath);
            SuperchainAddressRegistry.ChainInfo[] memory chains = _addrRegistry.getChains();

            // Try loading the address without the chain id, then try loading with it.
            try _addrRegistry.get(safeAddressString) returns (address addr) {
                parentMultisig = addr;
            } catch {
                parentMultisig = _addrRegistry.getAddress(safeAddressString, chains[0].chainId);
            }
        }

        return (task.isNestedSafe(parentMultisig), parentMultisig);
    }
}
