// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Test.sol";

import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {AddressRegistry} from "src/fps/AddressRegistry.sol";
import {MockMultisigTask} from "test/mock/MockMultisigTask.sol";

contract MultisigTaskUnitTest is Test {
    AddressRegistry public addresses;
    MultisigTask public task;

    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    string constant MAINNET_CONFIG = "./src/fps/example/task-03/mainnetConfig.toml";

    function setUp() public {
        vm.createSelectFork("mainnet");

        // Instantiate the Addresses contract
        addresses = new AddressRegistry(MAINNET_CONFIG);

        // Instantiate the Mock MultisigTask contract
        task = MultisigTask(new MockMultisigTask());
    }

    function test_run() public {
        vm.expectRevert("No actions found");
        task.getTaskActions();

        task.run(MAINNET_CONFIG);

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = task.getTaskActions();

        // check that the task targets are correct
        assertEq(targets.length, 1, "Wrong targets length");
        assertEq(
            targets[0], addresses.getAddress("ProxyAdmin", getChain("optimism").chainId), "Wrong target at index 0"
        );

        // check that the task values are correct
        assertEq(values.length, 1, "Wrong values length");
        assertEq(values[0], 0, "Wrong value at index 0");

        // check that the task calldatas are correct
        assertEq(calldatas.length, 1, "Wrong calldatas length");
        assertEq(
            calldatas[0],
            abi.encodeWithSignature(
                "upgrade(address,address)",
                addresses.getAddress("L1ERC721BridgeProxy", getChain("optimism").chainId),
                MockMultisigTask(address(task)).newImplementation()
            ),
            "Wrong calldata at index 0"
        );
    }

    function test_simulate_fails_tx_already_executed() public {
        test_run();

        vm.expectRevert("GS025");
        task.simulate();

        /// validations should pass after a successful run
        task.validate();
    }

    function test_getCalldata() public {
        test_run();

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = task.getTaskActions();

        Call3Value[] memory calls = new Call3Value[](targets.length);

        for (uint256 i; i < calls.length; i++) {
            calls[i] = Call3Value({target: targets[i], allowFailure: false, value: values[i], callData: calldatas[i]});
        }

        bytes memory expectedData = abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);

        bytes memory data = task.getCalldata();

        assertEq(data, expectedData, "Wrong aggregate calldata");
    }
}
