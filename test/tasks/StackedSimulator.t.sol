// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {StackedSimulator} from "src/improvements/tasks/StackedSimulator.sol";

contract StackedSimulatorUnitTest is Test {
    function setUp() public {
        vm.createSelectFork("sepolia");
        vm.setEnv("FETCH_TASKS_TEST_MODE", "true");
    }

    function testGetDependencyTree() public {
        StackedSimulator stackedSimulator = new StackedSimulator();
        string[] memory tasks = stackedSimulator.getDependentTasks("sep");
        assertEq(tasks.length, 4);
    }
    
}
