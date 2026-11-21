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
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";
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

    /// @notice Review helper: simulates every non-terminal task for a network and, for each nested task in the
    /// stack, simulates it once on every child safe of its root safe, all in a single forge process.
    /// @dev Replaces running `simulate-stack <network> <task> <child-safe>` once per (task, child safe) pair. Every
    /// fork read is fetched once and reused from memory, so N child-safe runs cost about one cold run.
    /// Simulation only: refuses to run in stacked signing mode because it prints more than one data-to-sign.
    function simulateStackAllChildSafes(string memory network) public {
        TaskInfo[] memory tasks = getNonTerminalTasks(network);
        if (tasks.length == 0) {
            console.log("No non-terminal tasks found for network: %s", network);
            return;
        }
        simulateStackAllChildSafes(network, tasks[tasks.length - 1].name);
    }

    /// @notice Same as `simulateStackAllChildSafes(string)` but stops at (and includes) `task`.
    function simulateStackAllChildSafes(string memory network, string memory task) public {
        require(
            !Utils.isFeatureEnabled("STACKED_SIGNING_MODE"),
            "StackedSimulator: simulateStackAllChildSafes is simulation-only and cannot be used for signing."
        );
        _simulateStackImpl(network, task, new address[](0), true);
    }

    /// @notice Simulates a stack of tasks with a given network, task, and child safes. The child safes can be empty.
    function _simulateStack(string memory _network, string memory _task, address[] memory _targetTaskChildSafes)
        private
    {
        _simulateStackImpl(_network, _task, _targetTaskChildSafes, false);
    }

    /// @notice Shared implementation. When `_allChildSafes` is true, every nested task is additionally simulated on
    /// each of its child safes (state is snapshotted before and reverted after each child-safe run), and the stack is
    /// then advanced exactly as a normal stacked simulation would (default child safe).
    function _simulateStackImpl(
        string memory _network,
        string memory _task,
        address[] memory _targetTaskChildSafes,
        bool _allChildSafes
    ) private {
        TaskManager taskManager = new TaskManager();
        TaskInfo[] memory tasks = getNonTerminalTasks(_network, _task);
        TaskConfig[] memory taskConfigs = new TaskConfig[](tasks.length);

        // Print the execution order here so callers don't need a separate `listStack` forge process.
        printStack(tasks, _network);

        string memory summary;
        uint256 failures;

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

            if (_allChildSafes) {
                (string memory taskSummary, uint256 taskFailures) =
                    _simulateOnAllChildSafes(taskManager, taskConfigs[i], tasks[i].name);
                summary = string.concat(summary, taskSummary);
                failures += taskFailures;
                // The last task has nothing stacked on top of it, so there is no need to advance the state.
                if (isLastTask) break;
            }

            if (isLastTask) {
                taskManager.executeTask(taskConfigs[i], _targetTaskChildSafes);
            } else {
                taskManager.executeTask(taskConfigs[i], new address[](0)); // Empty array because child safes are only used for the last task.
            }
        }

        if (_allChildSafes) {
            console.log("\n========== StackedSimulator: all-child-safes summary ==========");
            console.log(summary);
            require(failures == 0, "StackedSimulator: one or more child-safe simulations failed (see summary above).");
        }
    }

    /// @notice Simulates `_config` once per child-safe path of its root safe, reverting the fork state after each
    /// run so the runs are independent and the stack can then be advanced normally. Non-nested tasks run once on the
    /// root safe. Returns a human-readable summary and the number of failed runs.
    function _simulateOnAllChildSafes(TaskManager _taskManager, TaskConfig memory _config, string memory _taskName)
        private
        returns (string memory summary_, uint256 failures_)
    {
        address[][] memory paths = _config.isNested ? getChildSafePaths(_config.rootSafe) : new address[][](1);
        if (!_config.isNested) paths[0] = new address[](0);

        // A nested task must have at least one child-safe path; never report success without simulating anything.
        if (paths.length == 0) {
            return (
                string.concat(
                    "\n[FAIL] ",
                    _taskName,
                    " | no child safes found for nested root safe ",
                    vm.toString(_config.rootSafe)
                ),
                1
            );
        }

        for (uint256 j = 0; j < paths.length; j++) {
            string memory label = string.concat(_taskName, " | ", _formatSafePath(paths[j], _config.rootSafe));
            uint256 snapshot = vm.snapshotState();
            try _taskManager.executeTask(_config, paths[j]) returns (
                VmSafe.AccountAccess[] memory, bytes[] memory dataToSign_
            ) {
                summary_ = string.concat(summary_, "\n[PASS] ", label);
                address leaf = paths[j].length > 0 ? paths[j][0] : _config.rootSafe;
                bytes32 leafDomain = IGnosisSafe(leaf).domainSeparator();
                for (uint256 k = 0; k < dataToSign_.length; k++) {
                    (bytes32 domainHash, bytes32 messageHash) =
                        GnosisSafeHashes.getDomainAndMessageHashFromEncodedTransactionData(dataToSign_[k]);
                    summary_ = string.concat(
                        summary_,
                        "\n         domain: ",
                        vm.toString(domainHash),
                        "  message: ",
                        vm.toString(messageHash),
                        domainHash == leafDomain ? "  <- simulated safe" : ""
                    );
                }
            } catch Error(string memory reason) {
                failures_++;
                summary_ = string.concat(summary_, "\n[FAIL] ", label, "\n         ", reason);
            } catch (bytes memory) {
                failures_++;
                summary_ = string.concat(summary_, "\n[FAIL] ", label, "\n         (reverted without a reason)");
            }
            require(vm.revertToStateAndDelete(snapshot), "StackedSimulator: failed to revert child-safe snapshot.");
        }
    }

    /// @notice Returns every child-safe path that can approve a transaction on `_rootSafe`, in the ordering expected
    /// by `TaskManager.executeTask` (leaf first). A depth-1 owner whose owners are all Safes is treated as nested and
    /// expanded into one path per depth-2 Safe owner; otherwise it is a leaf. EOA (and EIP-7702-delegated EOA) owners
    /// are skipped because they sign the root safe directly.
    function getChildSafePaths(address _rootSafe) public view returns (address[][] memory paths_) {
        address[] memory owners = IGnosisSafe(_rootSafe).getOwners();
        uint256 count;
        for (uint256 i = 0; i < owners.length; i++) {
            if (!_isSafe(owners[i])) continue;
            count += _hasOnlySafeOwners(owners[i]) ? _countSafes(IGnosisSafe(owners[i]).getOwners()) : 1;
        }
        paths_ = new address[][](count);
        uint256 idx;
        for (uint256 i = 0; i < owners.length; i++) {
            if (!_isSafe(owners[i])) continue;
            if (_hasOnlySafeOwners(owners[i])) {
                address[] memory depth2Owners = IGnosisSafe(owners[i]).getOwners();
                for (uint256 k = 0; k < depth2Owners.length; k++) {
                    if (!_isSafe(depth2Owners[k])) continue;
                    paths_[idx++] = Solarray.addresses(depth2Owners[k], owners[i]);
                }
            } else {
                paths_[idx++] = Solarray.addresses(owners[i]);
            }
        }
    }

    /// @notice True if `_account` looks like a Safe: it has contract code that is not an EIP-7702 delegation
    /// designator (`0xef0100 ++ address`, which belongs to an EOA signer) and it answers `getOwners()`.
    function _isSafe(address _account) internal view returns (bool) {
        bytes memory code = _account.code;
        if (code.length == 0) return false;
        if (code.length == 23 && code[0] == 0xef && code[1] == 0x01 && code[2] == 0x00) return false;
        (bool ok, bytes memory ret) = _account.staticcall(abi.encodeCall(IGnosisSafe.getOwners, ()));
        return ok && ret.length >= 64;
    }

    function _hasOnlySafeOwners(address _safe) internal view returns (bool) {
        address[] memory owners = IGnosisSafe(_safe).getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            if (!_isSafe(owners[i])) return false;
        }
        return owners.length > 0;
    }

    function _countSafes(address[] memory _accounts) internal view returns (uint256 count_) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (_isSafe(_accounts[i])) count_++;
        }
    }

    function _formatSafePath(address[] memory _path, address _rootSafe) internal pure returns (string memory out_) {
        if (_path.length == 0) return string.concat("root safe ", vm.toString(_rootSafe));
        out_ = "child safes ";
        for (uint256 i = 0; i < _path.length; i++) {
            out_ = string.concat(out_, vm.toString(_path[i]), " -> ");
        }
        out_ = string.concat(out_, "root ", vm.toString(_rootSafe));
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
            // Validate date components
            require(year <= 2100, "StackedSimulator: Year must be <= 2100");
            require(month >= 1 && month <= 12, "StackedSimulator: Month must be between 1 and 12");
            require(day >= 1 && day <= 31, "StackedSimulator: Day must be between 1 and 31");
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
            } else {
                revert(
                    "StackedSimulator: Date-based format requires 'R' prefix in fourth component (e.g., YYYY-MM-DD-RN)"
                );
            }
            // Create a sortable number: YYYYMMDD * 10000 + rehearsal number
            return (year * 10000 + month * 100 + day) * 10000 + rehearsalNum;
        }

        revert(
            "StackedSimulator: Invalid task name format. Valid formats are either: 1) A 3-digit prefix followed by a descriptive name (e.g., '123-deploy-contract'), or 2) A date-based format 'YYYY-MM-DD-RN' where YYYY=year, MM=month, DD=day, R=rehearsal indicator (must be 'R'), and N=sequence number (e.g., '2025-01-08-R1')."
        );
    }

    /// @notice Finds the index of a task in a list of tasks.
    function findTaskIndex(TaskInfo[] memory tasks, string memory task) internal pure returns (uint256) {
        for (uint256 i = 0; i < tasks.length; i++) {
            if (tasks[i].name.eq(task)) return i;
        }
        revert("StackedSimulator: Task not found in non-terminal tasks");
    }
}
