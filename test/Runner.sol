pragma solidity 0.8.15;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";

import {ITask} from "src/improvements/tasks/ITask.sol";

contract Runner is Script {
    using Strings for uint256;

    struct L2Chain {
        uint256 chainId;
        string name;
    }

    struct TaskConfig {
        L2Chain[] l2chains;
        string path;
        string templateName;
    }

    function _parseConfig(string memory configPath) internal view returns (TaskConfig memory) {
        string memory configContent = vm.readFile(configPath);
        bytes memory rawL2Chains = vm.parseToml(configContent, ".l2chains");
        L2Chain[] memory l2chains = abi.decode(rawL2Chains, (L2Chain[]));

        bytes memory templateNameRaw = vm.parseToml(configContent, ".templateName");
        string memory templateName = abi.decode(templateNameRaw, (string));

        return TaskConfig({templateName: templateName, l2chains: l2chains, path: configPath});
    }

    function run() public {
        string[] memory commands = new string[](1);
        commands[0] = "./test/task/mock/example/fetch-tasks.sh";

        bytes memory result = vm.ffi(commands);

        string[] memory taskPaths = vm.split(string(result), "\n");

        // Process each task
        for (uint256 i = 0; i < taskPaths.length; i++) {
            // Parse config
            TaskConfig memory config = _parseConfig(taskPaths[i]);

            // Deploy and run the template
            string memory templatePath =
                string.concat("out/", config.templateName, ".sol/", config.templateName, ".json");

            ITask task = ITask(deployCode(templatePath));
            task.run(config.path);
        }
    }

    function run(string memory dumpStatePath) public {
        run();
        vm.dumpState(dumpStatePath);
    }
}
