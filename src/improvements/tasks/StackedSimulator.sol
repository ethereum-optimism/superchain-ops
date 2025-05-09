// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {TaskManager} from "src/improvements/tasks/TaskManager.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {console} from "forge-std/console.sol";
import {VmSafe} from "forge-std/Vm.sol";

/// This script enables stacked simulations. Stacked simulations allow us to simulate a task
/// that depends on the state of another task that hasn't been executed yet.
/// Only non-terminal tasks are executed as part of the stacked simulation.
contract StackedSimulator is Script {
    using LibString for string;
    using AccountAccessParser for VmSafe.AccountAccess[];

    struct TaskInfo {
        string path;
        string network;
        string name;
    }

    /// @notice Simulates the execution of all non-terminal tasks for a given network.
    function simulateStack(string memory network) public {
        TaskInfo[] memory tasks = getNonTerminalTasks(network);
        if (tasks.length == 0) {
            console.log("No non-terminal tasks found for network: %s", network);
            return;
        }
        simulateStack(network, tasks[tasks.length - 1].name, address(0));
    }

    /// @notice Simulates the execution of a task and all tasks that must be executed before it.
    function simulateStack(string memory network, string memory task, address optionalOwnerAddress) public {
        TaskManager taskManager = new TaskManager();
        TaskInfo[] memory tasks = getNonTerminalTasks(network, task);
        TaskManager.TaskConfig[] memory taskConfigs = new TaskManager.TaskConfig[](tasks.length);

        for (uint256 i = 0; i < tasks.length; i++) {
            taskConfigs[i] = taskManager.parseConfig(tasks[i].path);
        }

        simulateTasks(taskConfigs, optionalOwnerAddress);
    }

    /// @notice Simulates the execution of a single task.
    function simulateTask(string memory taskPath, address optionalOwnerAddress) public {
        TaskManager taskManager = new TaskManager();
        TaskManager.TaskConfig[] memory taskConfigs = new TaskManager.TaskConfig[](1);
        taskConfigs[0] = taskManager.parseConfig(taskPath);
        simulateTasks(taskConfigs, optionalOwnerAddress);
    }

    /// @notice Given a list of task configs, simulates the execution of each task.
    function simulateTasks(TaskManager.TaskConfig[] memory taskConfigs, address optionalOwnerAddress) public {
        TaskManager taskManager = new TaskManager();
        // Setting this env variable to reduce logging for stack simulations.
        vm.setEnv("SIGNING_MODE_IN_PROGRESS", "true");

        for (uint256 i = 0; i < taskConfigs.length; i++) {
            // If we wanted to ensure that all Tenderly links worked for each task, we would need to build a cumulative list of all state overrides
            // and append them to the next task's config.toml file. For now, we are skipping this functionality.
            taskManager.executeTask(taskConfigs[i], optionalOwnerAddress);
        }
    }

    /// @notice Returns an ordered list of non-terminal tasks that must be executed for a given task.
    function getNonTerminalTasks(string memory network, string memory task) public returns (TaskInfo[] memory tasks_) {
        TaskInfo[] memory allTasks = getNonTerminalTasks(network);
        uint256 targetIndex = findTaskIndex(allTasks, task);
        tasks_ = new TaskInfo[](targetIndex + 1);
        for (uint256 i = 0; i <= targetIndex; i++) {
            tasks_[i] = allTasks[i];
        }
    }

    /// @notice Returns an ordered list of non-terminal tasks for a given network.
    function getNonTerminalTasks(string memory network) public returns (TaskInfo[] memory tasks_) {
        TaskManager taskManager = new TaskManager();
        string[] memory nonTerminalTasks = taskManager.getNonTerminalTasks(network);
        tasks_ = new TaskInfo[](nonTerminalTasks.length);
        for (uint256 i = 0; i < nonTerminalTasks.length; i++) {
            string[] memory parts = vm.split(nonTerminalTasks[i], "/");
            tasks_[i] = TaskInfo({path: nonTerminalTasks[i], network: network, name: parts[parts.length - 1]});
        }

        // Sort the taskNames in ascending order based on the uint value of their first three characters.
        tasks_ = sortTasksByPrefix(tasks_);
    }

    /// @notice Lists the execution order for a stack of tasks for a given network.
    function listStack(string memory network) public {
        TaskInfo[] memory tasks = getNonTerminalTasks(network);
        if (tasks.length == 0) {
            console.log("No non-terminal tasks found for network: %s", network);
            return;
        }
        printStack(tasks, network);
    }

    /// @notice Lists the execution order for a stack of tasks for a given network and task.
    function listStack(string memory network, string memory task) public {
        TaskInfo[] memory tasks = getNonTerminalTasks(network, task);
        printStack(tasks, network);
    }

    function printStack(TaskInfo[] memory tasks, string memory network) public pure {
        console.log("StackedSimulator");
        console.log("Non-terminal tasks will be executed in the order they are listed below:\n");
        console.log("  Network: %s", network);
        for (uint256 i = 0; i < tasks.length; i++) {
            console.log("    %s: %s", i + 1, tasks[i].name);
        }
        console.log("\n");
    }

    /// @notice Sorts the task names in ascending order based on the uint value of their first three characters.
    function sortTasksByPrefix(TaskInfo[] memory tasks_) public pure returns (TaskInfo[] memory sortedTasks_) {
        sortedTasks_ = new TaskInfo[](tasks_.length);
        if (tasks_.length == 0) return sortedTasks_;
        for (uint256 i = 0; i < tasks_.length - 1; i++) {
            for (uint256 j = i + 1; j < tasks_.length; j++) {
                uint256 uintValueI = convertPrefixToUint(tasks_[i].name);
                uint256 uintValueJ = convertPrefixToUint(tasks_[j].name);

                if (uintValueI > uintValueJ) {
                    TaskInfo memory temp = tasks_[i];
                    tasks_[i] = tasks_[j];
                    tasks_[j] = temp;
                }
            }
        }
        sortedTasks_ = tasks_;
    }

    /// @notice Converts the first three characters of a task name string to a uint256.
    function convertPrefixToUint(string memory taskName) public pure returns (uint256) {
        require(bytes(taskName).length > 0, "StackedSimulator: Task name must not be empty.");
        string[] memory parts = vm.split(taskName, "-");
        require(parts.length > 0, "StackedSimulator: Invalid task name, must contain at least one '-'.");
        require(!parts[0].contains("0x"), "StackedSimulator: Does not support hex strings.");
        require(bytes(parts[0]).length == 3, "StackedSimulator: Prefix must have 3 characters.");
        return vm.parseUint(parts[0]);
    }

    /// @notice Finds the index of a task in a list of tasks.
    function findTaskIndex(TaskInfo[] memory tasks, string memory task) internal pure returns (uint256) {
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].name.eq(task)) return i;
        }
        revert("StackedSimulator: Task not found in non-terminal tasks");
    }

    /// @notice This function is used to remove a directory. The reason we use a try catch
    /// is because sometimes the directory may not exist and this leads to flaky tests.
    function removeDir(string memory dirName) internal {
        try vm.removeDir(dirName, true) {} catch {}
    }
}
