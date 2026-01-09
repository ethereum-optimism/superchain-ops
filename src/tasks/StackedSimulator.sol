// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {TaskManager} from "src/tasks/TaskManager.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Utils} from "src/libraries/Utils.sol";
import {TaskConfig} from "src/libraries/MultisigTypes.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {console} from "forge-std/console.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Script} from "forge-std/Script.sol";
import {Solarray} from "lib/optimism/packages/contracts-bedrock/scripts/libraries/Solarray.sol";

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

    /// @notice Simulate a task that has nested safe architecture with a child safe at depth 2, a child safe at depth 1, and a root safe.
    function simulateStack(string memory network, string memory task, address childSafeDepth2, address childSafeDepth1)
        public
    {
        require(
            childSafeDepth1 != address(0) && childSafeDepth2 != address(0),
            "StackedSimulator: Both child safes must be provided."
        );
        _simulateStack(network, task, Solarray.addresses(childSafeDepth2, childSafeDepth1));
    }

    /// @notice Simulate a task that has nested safe architecture with a child safe at depth 1 and a root safe.
    function simulateStack(string memory network, string memory task, address childSafeDepth1) public {
        require(childSafeDepth1 != address(0), "StackedSimulator: Child safe must be provided.");
        _simulateStack(network, task, Solarray.addresses(childSafeDepth1));
    }

    /// @notice Simulate a task that only has a root safe and no nested safes.
    function simulateStack(string memory network, string memory task) public {
        _simulateStack(network, task, new address[](0));
    }

    /// @notice Simulates the execution of all non-terminal tasks for a given network.
    function simulateStack(string memory network) public {
        TaskInfo[] memory tasks = getNonTerminalTasks(network);
        if (tasks.length == 0) {
            console.log("No non-terminal tasks found for network: %s", network);
            return;
        }
        _simulateStack(network, tasks[tasks.length - 1].name, new address[](0));
    }

    /// @notice Simulates a stack of tasks with a given network, task, and child safes. The child safes can be empty.
    function _simulateStack(string memory _network, string memory _task, address[] memory _targetTaskChildSafes)
        private
    {
        TaskManager taskManager = new TaskManager();
        TaskInfo[] memory tasks = getNonTerminalTasks(_network, _task);
        TaskConfig[] memory taskConfigs = new TaskConfig[](tasks.length);

        // Setting this env variable to true by default to reduce logging for stack simulations.
        // Use SIGNING_MODE_IN_PROGRESS=false to see print the full output.
        if (vm.envOr("SIGNING_MODE_IN_PROGRESS", true)) {
            vm.setEnv("SIGNING_MODE_IN_PROGRESS", "true");
        }

        for (uint256 i = 0; i < tasks.length; i++) {
            taskConfigs[i] = taskManager.parseConfig(tasks[i].path);
            bool isLastTask = i == tasks.length - 1;
            // eip712sign will sign the first occurrence of the data to sign in the terminal.
            // Because of this, we only want to print the data to sign for the last task (i.e. the task that is being signed).
            if (Utils.isFeatureEnabled("STACKED_SIGNING_MODE")) {
                // Only ever suppress printing data to sign for stacked signing.
                vm.setEnv("SUPPRESS_PRINTING_DATA_TO_SIGN", isLastTask ? "false" : "true");
            }

            if (isLastTask) {
                taskManager.executeTask(taskConfigs[i], _targetTaskChildSafes);
            } else {
                taskManager.executeTask(taskConfigs[i], new address[](0)); // Empty array because child safes are only used for the last task.
            }
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
        string[] memory nonTerminalTasksPaths = taskManager.getNonTerminalTaskPaths(network);
        tasks_ = new TaskInfo[](nonTerminalTasksPaths.length);
        for (uint256 i = 0; i < nonTerminalTasksPaths.length; i++) {
            string[] memory parts = vm.split(nonTerminalTasksPaths[i], "/");
            tasks_[i] = TaskInfo({path: nonTerminalTasksPaths[i], network: network, name: parts[parts.length - 1]});
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

    /// @notice Converts the task name prefix to a uint256 for sorting.
    /// Supports two formats:
    /// - Standard 3-digit prefix: "001-task-name" -> 1
    /// - Date-based prefix: "2025-07-21-R1-task" -> 202507210001 (YYYYMMDD + rehearsal number)
    function convertPrefixToUint(string memory taskName) public pure returns (uint256) {
        require(bytes(taskName).length > 0, "StackedSimulator: Task name must not be empty.");
        string[] memory parts = vm.split(taskName, "-");
        require(parts.length > 0, "StackedSimulator: Invalid task name, must contain at least one '-'.");
        require(!parts[0].contains("0x"), "StackedSimulator: Does not support hex strings.");

        // Handle standard 3-digit prefix format (e.g., "001-task-name")
        if (bytes(parts[0]).length == 3) {
            return vm.parseUint(parts[0]);
        }

        // Handle date-based format (e.g., "2025-07-21-R1-task")
        // Format: YYYY-MM-DD-RN-name where RN is the rehearsal number
        if (bytes(parts[0]).length == 4 && parts.length >= 4) {
            uint256 year = vm.parseUint(parts[0]);
            uint256 month = vm.parseUint(parts[1]);
            uint256 day = vm.parseUint(parts[2]);
            // Extract rehearsal number from parts[3] (e.g., "R1" -> 1)
            string memory rehearsalPart = parts[3];
            uint256 rehearsalNum = 0;
            if (bytes(rehearsalPart).length >= 2 && bytes(rehearsalPart)[0] == bytes1("R")) {
                // Extract the number after "R"
                bytes memory numBytes = new bytes(bytes(rehearsalPart).length - 1);
                for (uint256 i = 1; i < bytes(rehearsalPart).length; i++) {
                    numBytes[i - 1] = bytes(rehearsalPart)[i];
                }
                rehearsalNum = vm.parseUint(string(numBytes));
            }
            // Create a sortable number: YYYYMMDD * 10000 + rehearsal number
            return (year * 10000 + month * 100 + day) * 10000 + rehearsalNum;
        }

        revert("StackedSimulator: Invalid task name format. Valid formats are either: 1) A 3-digit prefix followed by a descriptive name (e.g., '123-deploy-contract'), or 2) A date-based format 'YYYY-MM-DD-RN' where YYYY=year, MM=month, DD=day, R=rehearsal indicator ('r' for rehearsal, 's' for standard), and N=sequence number (e.g., '2023-10-15-s1' for standard task, '2023-10-15-r1' for rehearsal).");
    }

    /// @notice Finds the index of a task in a list of tasks.
    function findTaskIndex(TaskInfo[] memory tasks, string memory task) internal pure returns (uint256) {
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].name.eq(task)) return i;
        }
        revert("StackedSimulator: Task not found in non-terminal tasks");
    }
}
