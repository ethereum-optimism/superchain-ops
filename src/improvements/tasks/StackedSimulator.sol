// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {TaskRunner} from "src/improvements/tasks/TaskRunner.sol";
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

    function simulateStack(string memory network) public {
        TaskInfo[] memory tasks = getNonTerminalTasks(network);
        simulateStack(network, tasks[tasks.length - 1].name);
    }

    /// @notice Simulates the execution of a task and all tasks that must be executed before it.
    /// This function copies the necessary files to a local directory that is not tracked by git.
    /// It does this because as part of stacked simulations, we need to modify the task config.toml files
    /// and we don't want to commit those changes to the repo.
    function simulateStack(string memory network, string memory task) public {
        TaskRunner taskRunner = new TaskRunner();
        TaskInfo[] memory tasks = getNonTerminalTasks(network, task);
        TaskRunner.TaskConfig[] memory taskConfigs = new TaskRunner.TaskConfig[](tasks.length);

        // This is a gitignored directory.
        string memory testDirectory = "test/tasks/stacked-sim-local";
        // Duplicate each task config so that we're not modifying the original task config.toml files.
        for (uint256 i = 0; i < tasks.length; i++) {
            taskConfigs[i] = taskRunner.parseConfig(tasks[i].path);
            string memory basePath = string.concat(testDirectory, "/", network, "/", tasks[i].name);
            vm.createDir(basePath, true);
            require(vm.isFile(taskConfigs[i].configPath), "StackedSimulator: config.toml file does not exist");
            string memory configPath = string.concat(basePath, "/", "config.toml");
            vm.copyFile(taskConfigs[i].configPath, configPath);

            string memory envPath = string.concat(taskConfigs[i].basePath, "/", ".env");
            if (vm.isFile(envPath)) {
                vm.copyFile(envPath, string.concat(basePath, "/", ".env"));
            }

            taskConfigs[i].basePath = basePath;
            taskConfigs[i].configPath = configPath;
        }

        AccountAccessParser.DecodedStateDiff[] memory nextTaskStateDiffs;
        for (uint256 i = 0; i < taskConfigs.length; i++) {
            console.log("StackedSimulator: Running task %s.", taskConfigs[i].templateName);
            console.log("StackedSimulator: Number of state overrides: %s.", nextTaskStateDiffs.length);
            taskRunner.appendStateOverrides(taskConfigs[i].configPath, nextTaskStateDiffs);
            VmSafe.AccountAccess[] memory accesses = taskRunner.executeTask(taskConfigs[i]);
            console.log("StackedSimulator: Number of accesses: %s.", accesses.length);
            (, nextTaskStateDiffs) = accesses.decode(true);
        }
        // Clean up after.
        // removeDir(testDirectory);
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
        TaskRunner taskRunner = new TaskRunner();
        string[] memory nonTerminalTasks = taskRunner.getNonTerminalTasks(network);
        tasks_ = new TaskInfo[](nonTerminalTasks.length);
        for (uint256 i = 0; i < nonTerminalTasks.length; i++) {
            string[] memory parts = vm.split(nonTerminalTasks[i], "/");
            tasks_[i] = TaskInfo({path: nonTerminalTasks[i], network: network, name: parts[parts.length - 1]});
        }

        // Sort the taskNames in ascending order based on the uint value of their first three characters.
        tasks_ = sortTasksByPrefix(tasks_);
    }

    /// @notice Sorts the task names in ascending order based on the uint value of their first three characters.
    function sortTasksByPrefix(TaskInfo[] memory tasks_) public pure returns (TaskInfo[] memory sortedTasks_) {
        require(tasks_.length > 0, "StackedSimulator: Input array must not be empty");
        sortedTasks_ = new TaskInfo[](tasks_.length);
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
