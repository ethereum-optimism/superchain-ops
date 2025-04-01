// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {StackedSimulator} from "src/improvements/tasks/StackedSimulator.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {IDisputeGameFactory, GameType} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {SimpleStorage} from "test/tasks/mock/template/StackSimulationTestTemplate.sol";

contract StackedSimulatorUnitTest is Test {
    using LibString for string;

    /// @notice The directory containing the test tasks.
    string internal testDirectory;

    /// @notice The op mainnet address of the dispute game factory (block 22162525).
    /// https://github.com/ethereum-optimism/superchain-registry/blob/5f5334768fd1dab6e31132020c374e575c632074/superchain/configs/mainnet/op.toml#L62
    address internal disputeGameFactory = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;

    /// @notice Invoked before each test case is run.
    function setUp() public {
        testDirectory = "test/tasks/stacked-sim-testing";
        vm.createSelectFork("mainnet", 22162525);
        vm.setEnv("FETCH_TASKS_TEST_DIR", testDirectory);
    }

    function testSimulateStackedTasks_SomeTasks() public {
        StackedSimulator ss = new StackedSimulator();
        createTestTasks("eth_000", 3, 0);
        ss.simulateStack("eth_000", "001-task-name");

        // Assert that the last tasks state change is the latest state change.
        address expectedImpl = makeAddr("001-task-name");
        assertEq(address(IDisputeGameFactory(disputeGameFactory).gameImpls(GameType.wrap(0))), expectedImpl);
    }

    function testSimulateStackedTasks_AllTasks() public {
        StackedSimulator ss = new StackedSimulator();
        createTestTasks("eth_001", 3, 100);
        ss.simulateStack("eth_001", "101-task-name");

        // Assert that the last tasks state change is the latest state change.
        address expectedImpl = makeAddr("101-task-name");
        assertEq(address(IDisputeGameFactory(disputeGameFactory).gameImpls(GameType.wrap(0))), expectedImpl);
    }

    function testGetNonTerminalTasks_NoTask() public {
        StackedSimulator ss = new StackedSimulator();
        createTestTasks("eth_002", 3, 200);
        StackedSimulator.TaskInfo[] memory tasks = ss.getNonTerminalTasks("eth_002");

        assertEq(tasks.length, 3);
        assertAscendingOrder(tasks);
    }

    function testGetNonTerminalTasks_WithTask() public {
        StackedSimulator ss = new StackedSimulator();
        createTestTasks("eth_003", 3, 300);
        StackedSimulator.TaskInfo[] memory tasks = ss.getNonTerminalTasks("eth_003", "301-task-name");

        assertEq(tasks.length, 2);
        assertEq(tasks[0].name, "300-task-name");
        assertEq(tasks[1].name, "301-task-name");
        assertAscendingOrder(tasks);
    }

    /// #############################################################
    /// ########## END-TO-END STACKED SIMULATION TEST ###############
    /// #############################################################
    /// The tests using SimpleStorage ensure that laters tasks in the stack
    /// need the state changes from previous tasks in the stack to succeed.
    function testSimulateStackedTasks_SimpleStorageFails() public {
        SimpleStorage simpleStorage = new SimpleStorage();
        createSimpleStorageTask("eth_004", address(simpleStorage), 100, 0, 1);
        // The old value is now 1, so the second task will fail.
        createSimpleStorageTask("eth_004", address(simpleStorage), 101, 0, 2);

        StackedSimulator ss = new StackedSimulator();
        vm.expectRevert("SimpleStorage: oldValue != x");
        ss.simulateStack("eth_004", "101-task-name");
    }

    function testSimulateStackedTasks_SimpleStoragePasses() public {
        SimpleStorage simpleStorage = new SimpleStorage();
        createSimpleStorageTask("eth_005", address(simpleStorage), 100, 0, 1);
        createSimpleStorageTask("eth_005", address(simpleStorage), 101, 1, 2);

        StackedSimulator ss = new StackedSimulator();
        ss.simulateStack("eth_005", "101-task-name");

        assertEq(simpleStorage.x(), 2);
    }

    function testGetNonTerminalTasks_NoTasks() public {
        StackedSimulator ss = new StackedSimulator();
        vm.expectRevert("TaskRunner: No non-terminal tasks found");
        ss.getNonTerminalTasks("fake-network");
    }

    function testStringConversionValidInput() public {
        StackedSimulator ss = new StackedSimulator();
        uint256 result = ss.convertPrefixToUint("123-task-name");
        assertEq(result, 123, "Expected 123 for input '123-task-name'");

        result = ss.convertPrefixToUint("001-task-name");
        assertEq(result, 1, "Expected 1 for input '001-task-name'");

        result = ss.convertPrefixToUint("999-task-name");
        assertEq(result, 999, "Expected 999 for input '999-task-name'");
    }

    function testStringConversionLeadingZeros() public {
        StackedSimulator ss = new StackedSimulator();
        uint256 result = ss.convertPrefixToUint("000-task-name");
        assertEq(result, 0, "Expected 0 for input '000-task-name'");

        result = ss.convertPrefixToUint("007-task-name");
        assertEq(result, 7, "Expected 7 for input '007-task-name'");
    }

    function testStringConversionShortString() public {
        StackedSimulator ss = new StackedSimulator();
        vm.expectRevert("StackedSimulator: Prefix must have 3 characters.");
        ss.convertPrefixToUint("12"); // Input with less than 3 characters
    }

    function testStringConversionInvalidCharacters() public {
        StackedSimulator ss = new StackedSimulator();
        vm.expectRevert(
            "vm.parseUint: failed parsing \"12a\" as type `uint256`: missing hex prefix (\"0x\") for hex string"
        );
        ss.convertPrefixToUint("12a-task-name"); // Non-numeric character in the first three characters

        vm.expectRevert(
            "vm.parseUint: failed parsing \"abc\" as type `uint256`: missing hex prefix (\"0x\") for hex string"
        );
        ss.convertPrefixToUint("abc-task-name"); // All invalid characters in the first three characters

        vm.expectRevert("StackedSimulator: Does not support hex strings.");
        ss.convertPrefixToUint("0x1-task-name"); // Hex string
    }

    function testStringConversionEmptyString() public {
        StackedSimulator ss = new StackedSimulator();
        vm.expectRevert("StackedSimulator: Prefix must have 3 characters.");
        ss.convertPrefixToUint(""); // Empty string
    }

    function testSortTasksAlreadySorted() public {
        StackedSimulator ss = new StackedSimulator();
        StackedSimulator.TaskInfo[] memory input = new StackedSimulator.TaskInfo[](3);
        input[0] = StackedSimulator.TaskInfo({path: "001-task-a", network: "eth", name: "001-task-a"});
        input[1] = StackedSimulator.TaskInfo({path: "002-task-b", network: "eth", name: "002-task-b"});
        input[2] = StackedSimulator.TaskInfo({path: "003-task-c", network: "eth", name: "003-task-c"});

        StackedSimulator.TaskInfo[] memory sorted = ss.sortTasksByPrefix(input);
        assertAscendingOrder(sorted);
    }

    function testSortTasksReverseSorted() public {
        StackedSimulator ss = new StackedSimulator();
        StackedSimulator.TaskInfo[] memory input = new StackedSimulator.TaskInfo[](3);
        input[0] = StackedSimulator.TaskInfo({path: "003-task-a", network: "eth", name: "003-task-a"});
        input[1] = StackedSimulator.TaskInfo({path: "002-task-b", network: "eth", name: "002-task-b"});
        input[2] = StackedSimulator.TaskInfo({path: "001-task-c", network: "eth", name: "001-task-c"});

        StackedSimulator.TaskInfo[] memory sorted = ss.sortTasksByPrefix(input);
        assertAscendingOrder(sorted);
    }

    function testSortTasksMixedOrder() public {
        StackedSimulator ss = new StackedSimulator();
        StackedSimulator.TaskInfo[] memory input = new StackedSimulator.TaskInfo[](4);
        input[0] = StackedSimulator.TaskInfo({path: "030-task-a", network: "eth", name: "030-task-a"});
        input[1] = StackedSimulator.TaskInfo({path: "005-task-b", network: "eth", name: "005-task-b"});
        input[2] = StackedSimulator.TaskInfo({path: "100-task-c", network: "eth", name: "100-task-c"});
        input[3] = StackedSimulator.TaskInfo({path: "001-task-d", network: "eth", name: "001-task-d"});

        StackedSimulator.TaskInfo[] memory sorted = ss.sortTasksByPrefix(input);
        assertAscendingOrder(sorted);
    }

    function testSortTasksDuplicatePrefixes() public {
        StackedSimulator ss = new StackedSimulator();
        StackedSimulator.TaskInfo[] memory input = new StackedSimulator.TaskInfo[](3);
        input[0] = StackedSimulator.TaskInfo({path: "005-task-a", network: "eth", name: "005-task-a"});
        input[1] = StackedSimulator.TaskInfo({path: "005-task-b", network: "eth", name: "005-task-b"});
        input[2] = StackedSimulator.TaskInfo({path: "005-task-c", network: "eth", name: "005-task-c"});

        StackedSimulator.TaskInfo[] memory sorted = ss.sortTasksByPrefix(input);
        assertAscendingOrder(sorted);
    }

    function testSortTasksSingleElement() public {
        StackedSimulator ss = new StackedSimulator();
        StackedSimulator.TaskInfo[] memory input = new StackedSimulator.TaskInfo[](1);
        input[0] = StackedSimulator.TaskInfo({path: "999-task", network: "eth", name: "999-task"});

        StackedSimulator.TaskInfo[] memory sorted = ss.sortTasksByPrefix(input);
        assertEq(sorted.length, 1);
        assertAscendingOrder(sorted);
    }

    function testSortTasksEmptyArray() public {
        StackedSimulator ss = new StackedSimulator();
        StackedSimulator.TaskInfo[] memory input = new StackedSimulator.TaskInfo[](0);
        vm.expectRevert("StackedSimulator: Input array must not be empty");
        ss.sortTasksByPrefix(input);
    }

    function testSortTasksLargeNumbers() public {
        StackedSimulator ss = new StackedSimulator();
        StackedSimulator.TaskInfo[] memory input = new StackedSimulator.TaskInfo[](3);
        input[0] = StackedSimulator.TaskInfo({path: "999-task", network: "eth", name: "999-task"});
        input[1] = StackedSimulator.TaskInfo({path: "500-task", network: "eth", name: "500-task"});
        input[2] = StackedSimulator.TaskInfo({path: "750-task", network: "eth", name: "750-task"});

        StackedSimulator.TaskInfo[] memory sorted = ss.sortTasksByPrefix(input);
        assertAscendingOrder(sorted);
    }

    function assertAscendingOrder(StackedSimulator.TaskInfo[] memory input) internal {
        StackedSimulator ss = new StackedSimulator();
        for (uint256 i = 0; i < input.length - 1; i++) {
            uint256 uintValueI = ss.convertPrefixToUint(input[i].name);
            uint256 uintValueJ = ss.convertPrefixToUint(input[i + 1].name);
            assertTrue(uintValueI <= uintValueJ);
        }
    }

    /// @notice Creates a set of tasks that can be used to test the StackedSimulator.
    /// These tasks use the DisputeGameUpgradeTemplate. For each task, a different implementation is created.
    /// This helps asserting that the StackedSimulator is correctly simulating the tasks in the correct order.
    function createTestTasks(string memory network, uint256 amount, uint256 startTaskIndex)
        internal
        returns (string[] memory taskNames_)
    {
        string memory commonToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
            "templateName = \"DisputeGameUpgradeTemplate\"\n" "\n";
        bytes memory fdpCode = address(IDisputeGameFactory(disputeGameFactory).gameImpls(GameType.wrap(0))).code;

        taskNames_ = new string[](amount);
        for (uint256 i = 0; i < amount; i++) {
            string memory taskName = getNextTaskName(startTaskIndex + i);
            string memory taskDir = string.concat(testDirectory, "/", network, "/", taskName);
            taskNames_[i] = taskName;
            vm.createDir(taskDir, true);
            vm.writeFile(string.concat(taskDir, "/README.md"), "This is a test README.md file.");
            vm.writeFile(string.concat(taskDir, "/VALIDATION.md"), "This is a test VALIDATION.md file.");

            address customImplAddr = makeAddr(taskName); // Predictable address for testing assertions.
            vm.etch(customImplAddr, fdpCode); // Etch fault dispute game code to the custom impl address.
            string memory toml = string.concat(
                commonToml,
                "implementations = [{gameType = 0, implementation = \"",
                LibString.toHexString(customImplAddr),
                "\", l2ChainId = 10}]\n"
            );
            vm.writeFile(string.concat(taskDir, "/config.toml"), toml);
        }
    }

    function createSimpleStorageTask(
        string memory network,
        address simpleStorage,
        uint256 startTaskIndex,
        uint256 oldValue,
        uint256 newValue
    ) internal {
        string memory taskName = getNextTaskName(startTaskIndex);
        string memory taskDir = string.concat(testDirectory, "/", network, "/", taskName);
        vm.createDir(taskDir, true);
        vm.writeFile(string.concat(taskDir, "/README.md"), "This is a test README.md file.");
        vm.writeFile(string.concat(taskDir, "/VALIDATION.md"), "This is a test VALIDATION.md file.");
        string memory commonToml = "templateName = \"StackSimulationTestTemplate\"\n" "\n";
        string memory toml = string.concat(
            commonToml,
            "oldValue = ",
            LibString.toString(oldValue),
            "\n",
            "newValue = ",
            LibString.toString(newValue),
            "\n\n",
            "[addresses]\n",
            "SimpleStorage = \"",
            LibString.toHexString(simpleStorage),
            "\"\n",
            "SimpleStorageOwner = \"0x847B5c174615B1B7fDF770882256e2D3E95b9D92\"\n" // Example safe, it doesn't matter for this test.
        );
        vm.writeFile(string.concat(taskDir, "/config.toml"), toml);
    }

    function getNextTaskName(uint256 startTaskIndex) internal pure returns (string memory taskName_) {
        require(startTaskIndex <= 999, "Task counter exceeded limit");
        // Format the task name as "XXX-task-name" where XXX is a zero-padded number
        taskName_ = string(
            abi.encodePacked(
                startTaskIndex < 10 ? "00" : (startTaskIndex < 100 ? "0" : ""),
                LibString.toString(startTaskIndex),
                "-task-name"
            )
        );
    }
}
