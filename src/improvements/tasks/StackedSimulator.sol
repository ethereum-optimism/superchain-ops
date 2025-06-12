// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {TaskManager} from "src/improvements/tasks/TaskManager.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Utils} from "src/libraries/Utils.sol";
import {console} from "forge-std/console.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {TaskConfig} from "src/libraries/MultisigTypes.sol";

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

    /// @notice Simulates the execution of all non-terminal tasks for a given network. No gas metering is used.
    function simulateStack(string memory network) public noGasMetering {
        TaskInfo[] memory tasks = getNonTerminalTasks(network);
        if (tasks.length == 0) {
            console.log("No non-terminal tasks found for network: %s", network);
            return;
        }
        simulateStack(network, tasks[tasks.length - 1].name, new address[](0));
    }

    /// The optionalOwnerAddresses array is used to specify the owner addresses for each nested task. It must be either empty or
    /// have the same length as the number of tasks. If it is empty, the first owner on the parent multisig will be used for each task.
    function simulateStack(string memory _network, string memory _task, address[] memory _optionalOwnerAddresses)
        public
    {
        TaskManager taskManager = new TaskManager();
        TaskInfo[] memory tasks = getNonTerminalTasks(_network, _task);
        TaskConfig[] memory taskConfigs = new TaskConfig[](tasks.length);
        require(
            _optionalOwnerAddresses.length == 0 || _optionalOwnerAddresses.length == tasks.length,
            "StackedSimulator: Invalid owner addresses array length. Must be empty or match the number of tasks being simulated."
        );

        // Setting this env variable to true by default to reduce logging for stack simulations.
        // Use SIGNING_MODE_IN_PROGRESS=false to see print the full output.
        if (vm.envOr("SIGNING_MODE_IN_PROGRESS", true)) {
            vm.setEnv("SIGNING_MODE_IN_PROGRESS", "true");
        }

        for (uint256 i = 0; i < tasks.length; i++) {
            // eip712sign will sign the first occurrence of the data to sign in the terminal.
            // Because of this, we only want to print the data to sign for the last task (i.e. the task that is being signed).
            bool isLastTask = i == tasks.length - 1;
            if (Utils.isFeatureEnabled("STACKED_SIGNING_MODE")) {
                // Only ever suppress printing data to sign for stacked signing.
                vm.setEnv("SUPPRESS_PRINTING_DATA_TO_SIGN", isLastTask ? "false" : "true");
            }

            taskConfigs[i] = taskManager.parseConfig(tasks[i].path);
            // If we wanted to ensure that all Tenderly links worked for each task, we would need to build a cumulative list of all state overrides
            // and append them to the next task's config.toml file. For now, we are skipping this functionality.
            address ownerAddress =
                _optionalOwnerAddresses.length == tasks.length ? _optionalOwnerAddresses[i] : address(0);
            taskManager.executeTask(taskConfigs[i], ownerAddress);
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
    function listStack(string memory network) public returns (uint256) {
        TaskInfo[] memory tasks = getNonTerminalTasks(network);
        if (tasks.length == 0) {
            console.log("No non-terminal tasks found for network: %s", network);
            return 0;
        }
        printStack(tasks, network);
        return tasks.length;
    }

    /// @notice Lists the execution order for a stack of tasks for a given network and task.
    function listStack(string memory network, string memory task) public returns (uint256) {
        TaskInfo[] memory tasks = getNonTerminalTasks(network, task);
        printStack(tasks, network);
        return tasks.length;
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
