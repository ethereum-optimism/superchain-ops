// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {SimpleAddressRegistry} from "src/improvements/SimpleAddressRegistry.sol";

/// This script gathers all tasks for a given network and performs a simulation run for each task.
/// This file can only simulate tasks for one network at a time (see: script/fetch-tasks.sh).
contract TaskRunner is Script {
    using Strings for uint256;
    using stdToml for string;

    struct L2Chain {
        uint256 chainId;
        string name;
    }

    struct TaskConfig {
        L2Chain[] optionalL2Chains;
        string path;
        string templateName;
        address parentMultisig;
        bool isNested;
        string optionalDependsOn;
    }

    function parseConfig(string memory configPath) public returns (TaskConfig memory) {
        string memory toml = vm.readFile(configPath);

        L2Chain[] memory optionalL2Chains;
        if (toml.keyExists(".l2chains")) {
            optionalL2Chains = abi.decode(toml.parseRaw(".l2chains"), (L2Chain[]));
        }

        string memory templateName = toml.readString(".templateName");

        string memory optionalDependsOn;
        if (toml.keyExists(".dependsOn")) {
            string memory dependsOnTask = toml.readString(".dependsOn.task");

            // Need to create a new path with the dependsOnTask. We can use the existing configPath
            // and replace the second-to-last element with the dependsOnTask.
            string[] memory pathParts = vm.split(configPath, "/");
            require(pathParts.length > 2, string.concat("TaskRunner: Invalid config path: ", configPath));

            pathParts[pathParts.length - 2] = dependsOnTask;
            string memory newPath = pathParts[0];
            for (uint256 i = 1; i < pathParts.length; i++) {
                newPath = string.concat(newPath, "/", pathParts[i]);
            }
            require(
                vm.isFile(newPath),
                string.concat("TaskRunner: Depends on task for: ", configPath, " does not exist: ", newPath)
            );
            optionalDependsOn = newPath;
        }

        (bool isNested, address parentMultisig) = isNestedTask(configPath);

        return TaskConfig({
            templateName: templateName,
            optionalL2Chains: optionalL2Chains,
            path: configPath,
            isNested: isNested,
            parentMultisig: parentMultisig,
            optionalDependsOn: optionalDependsOn
        });
    }

    function run(string memory network) public {
        string[] memory taskPaths = getNonTerminalTasks(network);

        for (uint256 i = 0; i < taskPaths.length; i++) {
            TaskConfig memory config = parseConfig(taskPaths[i]);

            // Deploy and run the template
            string memory templatePath =
                string.concat("out/", config.templateName, ".sol/", config.templateName, ".json");

            MultisigTask task = MultisigTask(deployCode(templatePath));

            executeTask(task, config);
        }
    }

    /// @notice Fetches all non-terminal tasks for a given network.
    function getNonTerminalTasks(string memory network) public returns (string[] memory taskPaths_) {
        string[] memory commands = new string[](2);
        commands[0] = "./src/improvements/script/fetch-tasks.sh";
        commands[1] = network;

        bytes memory result = vm.ffi(commands);
        taskPaths_ = vm.split(string(result), "\n");
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
        string memory templateName = configContent.readString(".templateName");

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
