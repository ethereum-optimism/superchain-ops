// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {SimpleAddressRegistry} from "src/improvements/SimpleAddressRegistry.sol";
import {LibString} from "@solady/utils/LibString.sol";

/// This script gathers all tasks for a given network and performs a simulation run for each task.
/// Once all tasks are simulated, the resultant state is written to a file.
/// This state is then applied and the monorepo integration tests are run against it.
/// This file can only simulate tasks for one network at a time (found under tasks/example/{network}).
contract TaskRunner is Script {
    using Strings for uint256;
    using stdToml for string;
    using LibString for string;

    struct L2Chain {
        uint256 chainId;
        string name;
    }

    struct TaskConfig {
        L2Chain[] l2chains;
        string path;
        string templateName;
        address parentMultisig;
        bool isNested;
    }

    function _parseConfig(string memory configPath) internal returns (TaskConfig memory) {
        string memory configContent = vm.readFile(configPath);
        bytes memory rawL2Chains = vm.parseToml(configContent, ".l2chains");
        L2Chain[] memory l2chains = abi.decode(rawL2Chains, (L2Chain[]));

        bytes memory templateNameRaw = vm.parseToml(configContent, ".templateName");
        string memory templateName = abi.decode(templateNameRaw, (string));

        (bool isNested, address parentMultisig) = isNestedTask(configPath);

        return TaskConfig({
            templateName: templateName,
            l2chains: l2chains,
            path: configPath,
            isNested: isNested,
            parentMultisig: parentMultisig
        });
    }

    function run(string memory network) public {
        string[] memory commands = new string[](2);
        commands[0] = "./src/improvements/script/fetch-tasks.sh";
        commands[1] = network;

        bytes memory result = vm.ffi(commands);
        string[] memory taskPaths = vm.split(string(result), "\n");

        // Process each task
        for (uint256 i = 0; i < taskPaths.length; i++) {
            // Parse config
            TaskConfig memory config = _parseConfig(taskPaths[i]);

            // Deploy and run the template
            string memory templatePath =
                string.concat("out/", config.templateName, ".sol/", config.templateName, ".json");

            MultisigTask task = MultisigTask(deployCode(templatePath));

            executeTask(task, config);
        }
    }

    /// @notice Runs the task and dumps the state to a file.
    /// The network parameter must be equivalent to the shortname of the network.
    /// e.g. For Ethereum Mainnet: https://github.com/ethereum-lists/chains/blob/53965b4def1d2983bef638279a66fc88e408ad7c/_data/chains/eip155-1.json#L33
    function run(string memory dumpStatePath, string memory network) public {
        run(network);
        vm.dumpState(dumpStatePath);
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
        bytes memory templateNameRaw = vm.parseToml(configContent, ".templateName");
        string memory templateName = abi.decode(templateNameRaw, (string));

        string memory templatePath = string.concat("out/", templateName, ".sol/", templateName, ".json");
        MultisigTask task = MultisigTask(deployCode(templatePath));
        string memory safeAddressString = task.safeAddressString();
        MultisigTask.TaskType taskType = task.taskType();

        if (taskType == MultisigTask.TaskType.SimpleBase) {
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
