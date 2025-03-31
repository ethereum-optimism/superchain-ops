// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {StackedSimulator} from "src/improvements/tasks/StackedSimulator.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {IDisputeGameFactory, GameType} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";

abstract contract AfterTest {
    modifier checkAfterTest() {
        _;
        afterTest();
    }

    function afterTest() public virtual;
}

contract StackedSimulatorUnitTest is AfterTest, Test {
    using LibString for string;

    /// @notice The directory containing the test tasks.
    string internal testDirectory;

    /// @notice The counter for the number of tasks created.
    uint256 internal taskCounter;

    /// @notice The op mainnet address of the dispute game factory (block 22162525).
    /// https://github.com/ethereum-optimism/superchain-registry/blob/5f5334768fd1dab6e31132020c374e575c632074/superchain/configs/mainnet/op.toml#L62
    address internal disputeGameFactory = 0xe5965Ab5962eDc7477C8520243A95517CD252fA9;

    function setUp() public {
        vm.createSelectFork("mainnet", 22162525);
        testDirectory = "test/tasks/stacked-sim-testing";
        vm.setEnv("FETCH_TASKS_TEST_DIR", testDirectory);
        // Create a scratch directory for stacked simulation testing (added to .gitignore and deleted after tests).
        vm.createDir(testDirectory, true);
    }

    function testSimulateStackedTasks_SomeTasks() public checkAfterTest {
        StackedSimulator ss = new StackedSimulator();
        createTestTasks("eth", 3);
        ss.simulateStack("eth", "001-task-name");

        // Assert that the last tasks state change is the latest state change.
        address expectedImpl = makeAddr("001-task-name");
        assertEq(address(IDisputeGameFactory(disputeGameFactory).gameImpls(GameType.wrap(0))), expectedImpl);
    }

    function testSimulateStackedTasks_AllTasks() public checkAfterTest {
        StackedSimulator ss = new StackedSimulator();
        createTestTasks("eth", 3);
        ss.simulateStack("eth", "002-task-name");

        // Assert that the last tasks state change is the latest state change.
        address expectedImpl = makeAddr("002-task-name");
        assertEq(address(IDisputeGameFactory(disputeGameFactory).gameImpls(GameType.wrap(0))), expectedImpl);
    }

    function testGetNonTerminalTasks_NoTask() public checkAfterTest {
        StackedSimulator ss = new StackedSimulator();
        createTestTasks("eth", 3);
        StackedSimulator.TaskInfo[] memory tasks = ss.getNonTerminalTasks("eth");

        assertEq(tasks.length, 3);
        assertAscendingOrder(tasks);
    }

    function testGetNonTerminalTasks_WithTask() public checkAfterTest {
        StackedSimulator ss = new StackedSimulator();
        createTestTasks("eth", 3);
        StackedSimulator.TaskInfo[] memory tasks = ss.getNonTerminalTasks("eth", "001-task-name");

        assertEq(tasks.length, 2);
        assertEq(tasks[0].name, "000-task-name");
        assertEq(tasks[1].name, "001-task-name");
        assertAscendingOrder(tasks);
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
        vm.expectRevert("StackedSimulator: Input string must have at least 3 characters");
        ss.convertPrefixToUint("12"); // Input with less than 3 characters
    }

    function testStringConversionInvalidCharacters() public {
        StackedSimulator ss = new StackedSimulator();
        vm.expectRevert("StackedSimulator: Invalid character in string");
        ss.convertPrefixToUint("12a-task-name"); // Non-numeric character in the first three characters

        vm.expectRevert("StackedSimulator: Invalid character in string");
        ss.convertPrefixToUint("abc-task-name"); // All invalid characters in the first three characters
    }

    function testStringConversionEmptyString() public {
        StackedSimulator ss = new StackedSimulator();
        vm.expectRevert("StackedSimulator: Input string must have at least 3 characters");
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
    function createTestTasks(string memory network, uint256 amount) internal returns (string[] memory taskNames_) {
        string memory commonToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
            "templateName = \"DisputeGameUpgradeTemplate\"\n" "\n";
        bytes memory fdpCode = address(IDisputeGameFactory(disputeGameFactory).gameImpls(GameType.wrap(0))).code;

        taskNames_ = new string[](amount);
        for (uint256 i = 0; i < amount; i++) {
            string memory taskName = getNextTaskName();
            taskNames_[i] = taskName;
            vm.createDir(string.concat(testDirectory, "/", network, "/", taskName), true);
            vm.writeFile(
                string.concat(testDirectory, "/", network, "/", taskName, "/README.md"),
                "This is a test README.md file."
            );
            vm.writeFile(
                string.concat(testDirectory, "/", network, "/", taskName, "/VALIDATION.md"),
                "This is a test VALIDATION.md file."
            );

            address customImplAddr = makeAddr(taskName); // Predictable address for testing assertions.
            vm.etch(customImplAddr, fdpCode); // Etch fault dispute game code to the custom impl address.
            string memory toml = string.concat(
                commonToml,
                "implementations = [{gameType = 0, implementation = \"",
                LibString.toHexString(customImplAddr),
                "\", l2ChainId = 10}]\n"
            );
            vm.writeFile(string.concat(testDirectory, "/", network, "/", taskName, "/config.toml"), toml);
        }
    }

    function getNextTaskName() internal returns (string memory taskName_) {
        require(taskCounter <= 999, "Task counter exceeded limit");
        // Format the task name as "XXX-task-name" where XXX is a zero-padded number
        taskName_ = string(
            abi.encodePacked(
                taskCounter < 10 ? "00" : (taskCounter < 100 ? "0" : ""), LibString.toString(taskCounter), "-task-name"
            )
        );
        taskCounter++;
    }

    function afterTest() public override {
        // Delete the scratch directory
        vm.removeDir("test/tasks/stacked-sim-testing", true);
    }
}
