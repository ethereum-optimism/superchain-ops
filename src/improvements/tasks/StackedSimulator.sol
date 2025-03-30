// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TaskRunner} from "src/improvements/tasks/TaskRunner.sol";
import {LibString} from "@solady/utils/LibString.sol";

/// This script enables stacked simulations. Stacked simulations allow us to simulate a task
/// that depends on the state of another task that hasn't been executed yet.
/// Only non-terminal tasks are executed as part of the stacked simulation.
contract StackedSimulator is Script {
    using LibString for string;

    struct TaskInfo {
        string path;
        string network;
        string name;
    }

    function run() public {
        console.log("StackedSimulator.run");
    }

    function simulateStack(string memory network) public {
        TaskInfo[] memory tasks = getNonTerminalTasks(network);
        simulateStack(network, tasks[tasks.length - 1].name);
    }

    /// @notice Simulates the execution of a task and all tasks that must be executed before it.
    function simulateStack(string memory network, string memory task) public {
        TaskRunner taskRunner = new TaskRunner();
        TaskInfo[] memory tasks = getNonTerminalTasks(network, task);
        TaskRunner.TaskConfig[] memory taskConfigs = new TaskRunner.TaskConfig[](tasks.length);

        for (uint256 i = 0; i < tasks.length; i++) {
            taskConfigs[i] = taskRunner.parseConfig(string.concat(tasks[i].path, "config.toml"));
        }

        for (uint256 i = 0; i < taskConfigs.length; i++) {
            taskRunner.executeTask(taskConfigs[i]);
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
        TaskRunner taskRunner = new TaskRunner();
        string[] memory nonTerminalTasks = taskRunner.getNonTerminalTasks(network);
        tasks_ = new TaskInfo[](nonTerminalTasks.length);
        for (uint256 i = 0; i < nonTerminalTasks.length; i++) {
            string[] memory parts = vm.split(nonTerminalTasks[i], "/");
            tasks_[i] = TaskInfo({path: nonTerminalTasks[i], network: network, name: parts[parts.length - 2]});
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
        uint256 PREFIX_LENGTH = 3;
        bytes memory inputBytes = bytes(taskName);
        require(inputBytes.length >= PREFIX_LENGTH, "StackedSimulator: Input string must have at least 3 characters");

        uint256 result = 0;
        for (uint256 i = 0; i < PREFIX_LENGTH; i++) {
            // Convert the current character from its byte representation to a uint256.
            // First, cast the byte to uint8 to get its ASCII value.
            uint256 c = uint256(uint8(inputBytes[i]));

            // Check that the ASCII value corresponds to a valid digit ('0' to '9').
            // https://www.ascii-code.com/48
            // https://www.ascii-code.com/57
            require(c >= 48 && c <= 57, "StackedSimulator: Invalid character in string");

            // Multiply the current result by 10 to shift digits left (base-10 place value),
            // then add the numeric value of the current character (c - 48 converts ASCII to digit).
            uint256 digit = c - 48;
            result = result * 10 + digit;
        }
        return result;
    }

    /// @notice Finds the index of a task in a list of tasks.
    function findTaskIndex(TaskInfo[] memory tasks, string memory task) internal pure returns (uint256) {
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].name.eq(task)) return i;
        }
        revert("StackedSimulator: Task not found in non-terminal tasks");
    }
}
