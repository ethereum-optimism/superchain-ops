// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {SimpleAddressRegistry} from "src/improvements/SimpleAddressRegistry.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {StdStyle} from "forge-std/StdStyle.sol";
import {console} from "forge-std/console.sol";

/// This script provides a collection of functions that can be used to manage tasks.
/// This file can only simulate tasks for one network at a time (see: script/fetch-tasks.sh).
contract TaskManager is Script {
    using Strings for uint256;
    using stdToml for string;
    using LibString for string;
    using AccountAccessParser for VmSafe.AccountAccess[];
    using StdStyle for string;

    struct L2Chain {
        uint256 chainId;
        string name;
    }

    struct TaskConfig {
        L2Chain[] optionalL2Chains;
        string basePath;
        string configPath;
        string templateName;
        address parentMultisig;
        bool isNested;
    }

    mapping(address => bool) public processedStateOverride;

    function parseConfig(string memory basePath) public returns (TaskConfig memory) {
        string memory configPath = string.concat(basePath, "/", "config.toml");
        string memory toml = vm.readFile(configPath);

        L2Chain[] memory optionalL2Chains;
        if (toml.keyExists(".l2chains")) {
            optionalL2Chains = abi.decode(toml.parseRaw(".l2chains"), (L2Chain[]));
        }

        string memory templateName = toml.readString(".templateName");

        (bool isNested, address parentMultisig) = isNestedTask(configPath);

        return TaskConfig({
            templateName: templateName,
            optionalL2Chains: optionalL2Chains,
            basePath: basePath,
            configPath: configPath,
            isNested: isNested,
            parentMultisig: parentMultisig
        });
    }

    /// @notice Fetches all non-terminal tasks for a given network.
    function getNonTerminalTasks(string memory network) public returns (string[] memory taskPaths_) {
        string[] memory commands = new string[](2);
        commands[0] = "./src/improvements/script/fetch-tasks.sh";
        commands[1] = network;

        bytes memory result = vm.ffi(commands);
        require(result.length > 0, "TaskManager: No non-terminal tasks found");
        string[] memory taskConfigFilePaths = vm.split(string(result), "\n");
        taskPaths_ = new string[](taskConfigFilePaths.length);

        for (uint256 i = 0; i < taskConfigFilePaths.length; i++) {
            string[] memory parts = vm.split(taskConfigFilePaths[i], "/");
            string memory baseTaskPath;
            for (uint256 j = 0; j < parts.length - 1; j++) {
                baseTaskPath = string.concat(baseTaskPath, parts[j], "/");
            }
            taskPaths_[i] = baseTaskPath;
        }

        // Remove last slash from each task path.
        for (uint256 i = 0; i < taskPaths_.length; i++) {
            if (taskPaths_[i].endsWith("/")) {
                taskPaths_[i] = LibString.slice(taskPaths_[i], 0, bytes(taskPaths_[i]).length - 1);
            }
        }

        // Ensure task is well-formed.
        for (uint256 i = 0; i < taskPaths_.length; i++) {
            validateTask(taskPaths_[i]);
        }
    }

    /// @notice Basic sanity checks to ensure the task is well-formed.
    function validateTask(string memory taskPath) public view {
        require(
            vm.isFile(string.concat(taskPath, "/", "config.toml")),
            string.concat("TaskManager: config.toml file does not exist: ", taskPath)
        );
        require(
            vm.isFile(string.concat(taskPath, "/", "README.md")),
            string.concat("TaskManager: README.md file does not exist: ", taskPath)
        );
        require(
            vm.isFile(string.concat(taskPath, "/", "VALIDATION.md")),
            string.concat("TaskManager: VALIDATION.md file does not exist: ", taskPath)
        );
    }

    /// @notice Executes a task based on its configuration.
    function executeTask(TaskConfig memory config, address optionalOwnerAddress)
        public
        returns (VmSafe.AccountAccess[] memory accesses)
    {
        // Deploy and run the template
        string memory templatePath = string.concat("out/", config.templateName, ".sol/", config.templateName, ".json");
        MultisigTask task = MultisigTask(deployCode(templatePath));
        string memory formattedParentMultisig = vm.toString(config.parentMultisig).green().bold();

        setTenderlyGasEnv(config.basePath);

        string[] memory parts = vm.split(config.basePath, "/");
        string memory taskName = parts[parts.length - 1];

        string memory line =
            unicode"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        if (config.isNested) {
            IGnosisSafe parentMultisig = IGnosisSafe(config.parentMultisig);
            address[] memory owners = parentMultisig.getOwners();
            require(
                owners.length > 0,
                string.concat(
                    "TaskManager: No owners found for parent multisig: ",
                    Strings.toHexString(uint256(uint160(config.parentMultisig)), 20)
                )
            );

            address ownerAddress = optionalOwnerAddress != address(0) ? optionalOwnerAddress : owners[0];
            // forgefmt: disable-start
            console.log(string.concat("SIMULATING NESTED TASK (", taskName, ") FOR OWNER: ", vm.toString(ownerAddress), " ON ", formattedParentMultisig));
            // forgefmt: disable-end
            console.log(line.green().bold());
            console.log("");
            require(
                contains(owners, ownerAddress),
                string.concat(
                    "TaskManager: ownerAddress must be an owner of the parent multisig: ",
                    vm.toString(config.parentMultisig)
                )
            );
            (accesses,) = task.signFromChildMultisig(config.configPath, ownerAddress);
        } else {
            // forgefmt: disable-start
            console.log(string.concat("SIMULATING SINGLE TASK: ", taskName, " ON ", formattedParentMultisig));
            console.log(line.green().bold());
            console.log("");
            // forgefmt: disable-end
            (accesses,) = task.simulateRun(config.configPath);
        }
    }

    /// @notice Sets the TENDERLY_GAS environment variable for the task if it exists.
    function setTenderlyGasEnv(string memory basePath) public {
        string memory envFile = string.concat(basePath, "/", ".env");
        if (vm.isFile(envFile)) {
            string memory envContent = vm.readFile(envFile);
            string[] memory lines = vm.split(envContent, "\n");

            for (uint256 i = 0; i < lines.length; i++) {
                if (lines[i].contains("TENDERLY_GAS=")) {
                    string[] memory keyValue = vm.split(lines[i], "=");
                    if (keyValue.length == 2) {
                        vm.setEnv("TENDERLY_GAS", keyValue[1]);
                        return;
                    }
                }
            }
        }
        // If no TENDERLY_GAS is found, set it as empty.
        vm.setEnv("TENDERLY_GAS", "");
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

    function contains(address[] memory list, address addr) public pure returns (bool) {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == addr) return true;
        }
        return false;
    }
}
