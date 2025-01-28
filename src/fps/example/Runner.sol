pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {ITask} from "src/fps/task/ITask.sol";

contract Runner is Script {
    string public network;

    struct TasksStatus {
        string contractName;
        string name;
        string path;
        uint256 status;
    }

    function run() public {
        string memory runnerConfigFileContents = vm.readFile("src/fps/example/runnerConfig.toml");
        TasksStatus[] memory tasksStatuses =
            abi.decode(vm.parseToml(runnerConfigFileContents, ".tasks"), (TasksStatus[]));
        if (block.chainid == 1) {
            network = "mainnet";
        } else if (block.chainid == 11155111) {
            network = "testnet";
        } else {
            revert("Unsupported network");
        }
        for (uint256 i = 0; i < tasksStatuses.length; i++) {
            TasksStatus memory taskStatus = tasksStatuses[i];
            if (taskStatus.status >= 1 && taskStatus.status <= 3) {
                string memory taskConfigFilePath = string.concat(taskStatus.path, "/", network, "Config.toml");
                ITask(deployCode(taskStatus.contractName)).run(taskConfigFilePath);
            }
        }
    }

    function run(string memory dumpStatePath) public {
        run();
        vm.dumpState(dumpStatePath);
    }
}
