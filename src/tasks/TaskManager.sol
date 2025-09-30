// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Script} from "forge-std/Script.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Solarray} from "lib/optimism/packages/contracts-bedrock/scripts/libraries/Solarray.sol";

import {MultisigTask} from "src/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {SimpleAddressRegistry} from "src/SimpleAddressRegistry.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {StdStyle} from "forge-std/StdStyle.sol";
import {console} from "forge-std/console.sol";
import {TaskType, TaskConfig, L2Chain} from "src/libraries/MultisigTypes.sol";
import {Utils} from "src/libraries/Utils.sol";

/// This script provides a collection of functions that can be used to manage tasks.
/// This file can only simulate tasks for one network at a time (see: script/fetch-tasks.sh).
contract TaskManager is Script {
    using Strings for uint256;
    using stdToml for string;
    using LibString for string;
    using AccountAccessParser for VmSafe.AccountAccess[];
    using StdStyle for string;

    /// @notice Parses the config.toml file for a given task and returns a TaskConfig struct.
    function parseConfig(string memory basePath) public returns (TaskConfig memory) {
        string memory configPath = string.concat(basePath, "/", "config.toml");
        string memory toml = vm.readFile(configPath);

        L2Chain[] memory optionalL2Chains;
        if (toml.keyExists(".l2chains")) {
            optionalL2Chains = abi.decode(toml.parseRaw(".l2chains"), (L2Chain[]));
        }

        string memory templateName = toml.readString(".templateName");

        (bool isNested, address rootSafe, MultisigTask task) = isNestedTask(configPath);

        return TaskConfig({
            templateName: templateName,
            optionalL2Chains: optionalL2Chains,
            basePath: basePath,
            configPath: configPath,
            isNested: isNested,
            rootSafe: rootSafe,
            task: address(task)
        });
    }

    /// @notice Fetches all non-terminal tasks for a given network.
    function getNonTerminalTaskPaths(string memory network) public returns (string[] memory taskPaths_) {
        string[] memory commands = new string[](2);
        commands[0] = "./src/script/fetch-tasks.sh";
        commands[1] = network;

        bytes memory result = vm.ffi(commands);
        if (result.length == 0) return new string[](0);

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
    }

    function executeTask(TaskConfig memory config, address[] memory _childSafes)
        public
        returns (VmSafe.AccountAccess[] memory accesses_, bytes32 normalizedHash_, bytes memory dataToSign_)
    {
        // Deploy and run the template
        string memory templatePath = string.concat("out/", config.templateName, ".sol/", config.templateName, ".json");
        MultisigTask task = getMultisigTask(templatePath, config.task);

        string memory formattedRootSafe = vm.toString(config.rootSafe).green().bold();

        setTenderlyGasEnv(config.basePath);

        string[] memory parts = vm.split(config.basePath, "/");
        string memory taskName = parts[parts.length - 1];

        (accesses_, normalizedHash_, dataToSign_) = execute(config, task, _childSafes, taskName, formattedRootSafe);
        require(
            checkNormalizedHash(normalizedHash_, config),
            string.concat(
                "TaskManager: Normalized hash for task: ",
                taskName,
                " does not match. Got: ",
                vm.toString(normalizedHash_)
            )
        );
        require(
            checkDataToSign(dataToSign_, config),
            string.concat(
                "TaskManager: Data to sign for task: ",
                taskName,
                " does not match Domain and Message hashes in VALIDATION.md. Got: ",
                vm.toString(dataToSign_)
            )
        );
    }

    /// @notice Executes a task based on its configuration.
    function execute(
        TaskConfig memory _config,
        MultisigTask _task,
        address[] memory _childSafes,
        string memory _taskName,
        string memory _formattedParentMultisig
    ) private returns (VmSafe.AccountAccess[] memory accesses_, bytes32 normalizedHash_, bytes memory dataToSign_) {
        string memory line =
            unicode"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        if (_config.isNested) {
            if (_childSafes.length == 0) {
                _childSafes = setupDefaultChildSafes(_childSafes, _config.rootSafe);
            }
            address leafChildSafe = _childSafes[0];
            // forgefmt: disable-start
            console.log(string.concat("SIMULATING NESTED TASK (", _taskName, ") ON NESTED SAFE: ", vm.toString(leafChildSafe), " FOR ROOT SAFE: ", _formattedParentMultisig));
            // forgefmt: disable-end
            console.log(line.green().bold());
            console.log("");
            address[] memory allSafes = Solarray.extend(_childSafes, Solarray.addresses(address(_config.rootSafe)));
            Utils.validateSafesOrder(allSafes);
            (accesses_,, normalizedHash_, dataToSign_,) = _task.simulate(_config.configPath, _childSafes);
        } else {
            // forgefmt: disable-start
            console.log(string.concat("SIMULATING SINGLE TASK: ", _taskName, " FOR ROOT SAFE: ", _formattedParentMultisig));
            console.log(line.green().bold());
            console.log("");
            // forgefmt: disable-end
            require(
                _childSafes.length == 0, "TaskManager: child safes provided but not expected for a single safe task."
            );

            (accesses_,, normalizedHash_, dataToSign_,) = _task.simulate(_config.configPath, new address[](0));
        }
    }

    /// @notice Generic logic to check for the existence of target bytes in the VALIDATION markdown file.
    /// @return 'false' when VALIDATION file is empty or does not contain the target bytes. 'true' when VALIDATION file does not exist or contains the target bytes.
    function checkValidationFile(bytes memory _target, TaskConfig memory _config, string memory customMessage)
        public
        view
        returns (bool)
    {
        string memory validationFilePath = string.concat(_config.basePath, "/VALIDATION.md");
        // If no VALIDATION file exists then we assume this is intentional and skip the check e.g. test tasks.
        if (!vm.isFile(validationFilePath)) return true;

        string memory targetStr = vm.toString(_target);
        string memory validations = vm.readFile(validationFilePath);
        string[] memory lines = vm.split(validations, "\n");
        for (uint256 i = 0; i < lines.length; i++) {
            if (lines[i].contains(targetStr)) {
                return true;
            }
        }
        console.log(string.concat(vm.toUppercase("[ERROR]").red().bold(), " ", customMessage, " ", targetStr));
        return false;
    }

    /// @notice Cross check most recent normalized hash with normalized hash stored in VALIDATION markdown file.
    /// @return 'false' when VALIDATION file is empty or contains the wrong hash. 'true' when VALIDATION file does not exist or contains the correct hash.
    function checkNormalizedHash(bytes32 _normalizedHash, TaskConfig memory _config) public view returns (bool) {
        bytes memory normalizedHashBytes = abi.encodePacked(_normalizedHash);
        return checkValidationFile(
            normalizedHashBytes,
            _config,
            "Normalized hash does not match. Please check that you've added it to the VALIDATION markdown file."
        );
    }

    /// @notice Cross check most recent data to sign with the domain and message hashes stored in VALIDATION markdown file.
    /// @return 'false' when VALIDATION file is empty or contains the wrong data to sign. 'true' when VALIDATION file does not exist or contains the correct data to sign.
    function checkDataToSign(bytes memory _dataToSign, TaskConfig memory _config) public view returns (bool) {
        string memory message = "Please check that you've added it to the VALIDATION markdown file.";
        (bytes32 domainSeparator, bytes32 messageHash) =
            GnosisSafeHashes.getDomainAndMessageHashFromEncodedTransactionData(_dataToSign);
        bytes memory domainHashBytes = abi.encodePacked(domainSeparator);
        bytes memory messageHashBytes = abi.encodePacked(messageHash);
        bool containsDomainHash =
            checkValidationFile(domainHashBytes, _config, string.concat("Domain hash does not match. ", message));
        bool containsMessageHash =
            checkValidationFile(messageHashBytes, _config, string.concat("Message hash does not match. ", message));
        return containsDomainHash && containsMessageHash;
    }

    /// @notice Requires that a signer is an owner on a safe.
    function requireSignerOnSafe(address signer, string memory taskPath) public {
        TaskConfig memory config = parseConfig(taskPath);
        requireSignerOnSafe(signer, config.rootSafe);
    }

    /// @notice Requires that a signer is an owner on a safe.
    function requireSignerOnSafe(address signer, address safe) public view {
        address[] memory owners = IGnosisSafe(safe).getOwners();
        require(
            Utils.contains(owners, signer),
            string.concat(
                "TaskManager: signer ", vm.toString(signer), " is not an owner on the safe: ", vm.toString(safe)
            )
        );
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
    function isNestedTask(string memory taskConfigFilePath)
        public
        returns (bool, address rootSafe, MultisigTask task)
    {
        string memory configContent = vm.readFile(taskConfigFilePath);
        string memory templateName = configContent.readString(".templateName");

        string memory templatePath = string.concat("out/", templateName, ".sol/", templateName, ".json");
        task = MultisigTask(deployCode(templatePath));
        string memory safeAddressString = task.loadSafeAddressString(task, taskConfigFilePath);
        TaskType taskType = task.taskType();

        if (taskType == TaskType.SimpleTaskBase) {
            SimpleAddressRegistry _simpleAddrRegistry = new SimpleAddressRegistry(taskConfigFilePath);
            rootSafe = _simpleAddrRegistry.get(safeAddressString);
        } else {
            SuperchainAddressRegistry _addrRegistry = new SuperchainAddressRegistry(taskConfigFilePath);
            SuperchainAddressRegistry.ChainInfo[] memory chains = _addrRegistry.getChains();

            // Try loading the address without the chain id, then try loading with it.
            try _addrRegistry.get(safeAddressString) returns (address addr) {
                rootSafe = addr;
            } catch {
                rootSafe = _addrRegistry.getAddress(safeAddressString, chains[0].chainId);
            }
        }
        return (isNestedSafe(rootSafe), rootSafe, task);
    }

    /// @notice Returns a cached MultisigTask instance for a given template path or deploys a new one.
    function getMultisigTask(string memory templatePath, address optionalTask) internal returns (MultisigTask task) {
        if (optionalTask == address(0)) {
            task = MultisigTask(deployCode(templatePath));
        } else {
            task = MultisigTask(optionalTask);
        }
    }

    /// @notice Helper function to determine if the given safe is a nested multisig.
    function isNestedSafe(address safe) public view returns (bool) {
        // Assume safe is nested unless there is an EOA owner
        bool nested = true;

        address[] memory owners = IGnosisSafe(safe).getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i].code.length == 0) {
                nested = false;
            }
        }
        return nested;
    }

    /// @notice Helper function to determine if the given safe is a nested-nested multisig (e.g. Base safe architecture).
    /// This function will return the first owner that is a nested safe.
    function isNestedNestedSafe(address safe) public view returns (bool, address) {
        address[] memory owners = IGnosisSafe(safe).getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            if (isNestedSafe(owners[i])) {
                return (true, owners[i]);
            }
        }
        return (false, address(0));
    }

    /// @notice Returns the root safe address for a given task config file path.
    function getRootSafe(string memory taskConfigFilePath) public returns (address) {
        (, address rootSafe,) = isNestedTask(taskConfigFilePath);
        return rootSafe;
    }

    /// @notice If a task is nested but the user hasn't provided any child safes, then we need to setup the default child safes so the simulation can run.
    function setupDefaultChildSafes(address[] memory _childSafes, address _rootSafe)
        internal
        view
        returns (address[] memory)
    {
        // If the root safe has a nested-nested safe setup, then we need to setup the default child safes so the simulation can run.
        (bool isNestedNested, address depth1ChildSafe) = isNestedNestedSafe(_rootSafe);
        if (isNestedNested) {
            _childSafes = new address[](2);
            address depth2ChildSafe = IGnosisSafe(depth1ChildSafe).getOwners()[0];
            _childSafes[0] = depth2ChildSafe; // See MultisigTypes.sol for an explanation of the ordering.
            _childSafes[1] = depth1ChildSafe;
        } else {
            _childSafes = new address[](1);
            depth1ChildSafe = IGnosisSafe(_rootSafe).getOwners()[0];
            _childSafes[0] = depth1ChildSafe;
        }
        require(_childSafes.length <= 2, "TaskManager: currently only supports 2 levels of nesting.");
        return _childSafes;
    }
}
