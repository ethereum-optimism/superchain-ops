// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import { TaskRunner } from "src/improvements/tasks/TaskRunner.sol";

/// The script enables stacked simulations. Stacked simulations allow us to simulate a task
/// that depends on the state of another task that hasn't been executed yet.
contract StackedSimulator is Script {

    function run() public {
        console.log("StackedSimulator.run");
        TaskRunner taskRunner = new TaskRunner();
        // taskRunner.run("eth");
    }


    /// @notice Get all dependent non-terminal tasks for a given task.
    function getDependentTasks(string memory network) public returns (string[] memory tasks_) {
        TaskRunner taskRunner = new TaskRunner();
        // Print a list of all tasks that will be executed in ascending order, earliest to latest.
        // e.g. Task 2 depends on task 1, task 3 depends on task 2. Therefore this would print: 1, 2, 3
        tasks_ = taskRunner.getNonTerminalTasks(network);
        for (uint256 i = 0; i < tasks_.length; i++) {
            console.log(tasks_[i]);
            TaskRunner.TaskConfig memory config = taskRunner.parseConfig(tasks_[i]);
            console.log(config.optionalDependsOn);
        }
        // Enforce all tasks must have a dependsOn except for one (the first task).
    }

}
