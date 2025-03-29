// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TaskRunner} from "src/improvements/tasks/TaskRunner.sol";
import {LibString} from "@solady/utils/LibString.sol";
/// The script enables stacked simulations. Stacked simulations allow us to simulate a task
/// that depends on the state of another task that hasn't been executed yet.

contract StackedSimulator is Script {
    using LibString for string;

    /// @notice A map of tasks to their dependent tasks.
    mapping(string => string) internal dependencyMap;

    function run() public {
        console.log("StackedSimulator.run");
    }

    /// @notice Get an ordered list of dependent non-terminal tasks for a given network.
    /// Forces a single queue of tasks to exist for a given network. All tasks except the root must have a previous task.
    function getOrderedTasks(string memory network) public returns (string[] memory tasks_) {
        TaskRunner taskRunner = new TaskRunner();
        // Print a list of all tasks that will be executed in ascending order, earliest to latest.
        // e.g. Task 2 depends on task 1, task 3 depends on task 2. Therefore this would print: 1, 2, 3
        tasks_ = taskRunner.getNonTerminalTasks(network);

        uint256 n = tasks_.length;
        require(n > 0, "StackedSimulator: No tasks available");

        // Find root task (no dependencies)
        string memory rootTask;
        for (uint256 i = 0; i < n; i++) {
            TaskRunner.TaskConfig memory config = taskRunner.parseConfig(tasks_[i]);
            if (bytes(config.optionalDependsOn).length == 0) {
                rootTask = tasks_[i];
                break;
            }
        }
        require(bytes(rootTask).length > 0, "StackedSimulator: No root task found");

        // Build dependency map: task -> dependent task
        for (uint256 i = 0; i < n; i++) {
            if (tasks_[i].eq(rootTask)) {
                continue;
            }
            TaskRunner.TaskConfig memory config = taskRunner.parseConfig(tasks_[i]);
            if (bytes(config.optionalDependsOn).length > 0) {
                dependencyMap[config.optionalDependsOn] = tasks_[i];
            }
        }

        // Build ordered list
        string[] memory ordered = new string[](n);
        ordered[0] = rootTask;

        for (uint256 i = 1; i < n; i++) {
            ordered[i] = dependencyMap[ordered[i - 1]];
        }

        tasks_ = ordered;
    }
}
