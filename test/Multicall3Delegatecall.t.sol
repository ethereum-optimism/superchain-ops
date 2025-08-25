// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {Multicall3Delegatecall} from "src/Multicall3Delegatecall.sol";

contract MockTarget {
    uint256 public value;

    function setValue(uint256 _value) external returns (uint256) {
        value = _value;
        return _value;
    }

    function checkDelegatecall() external view returns (address, address, address) {
        return (msg.sender, address(this), tx.origin);
    }
}

contract MockRevertingTarget {
    function anyFunction() external pure {
        revert("MockRevertingTarget: always reverts");
    }
}

contract Multicall3DelegatecallTest is Test {
    Multicall3Delegatecall internal multicall;
    MockTarget internal mockTarget;
    MockRevertingTarget internal mockRevertingTarget;

    function setUp() public {
        multicall = new Multicall3Delegatecall();
        mockTarget = new MockTarget();
        mockRevertingTarget = new MockRevertingTarget();
    }

    function test_aggregate3_success() public {
        // Verify initial state - storage slot 0 should be 0
        assertEq(vm.load(address(multicall), bytes32(0)), bytes32(0), "Initial storage slot 0 should be 0");

        Multicall3Delegatecall.Call3[] memory calls = new Multicall3Delegatecall.Call3[](1);
        calls[0] = Multicall3Delegatecall.Call3({
            target: address(mockTarget),
            allowFailure: false,
            callData: abi.encodeWithSignature("setValue(uint256)", 42)
        });

        Multicall3Delegatecall.Result[] memory results = multicall.aggregate3(calls);

        assertEq(results.length, 1);
        assertTrue(results[0].success);
        assertEq(results[0].returnData, abi.encode(42), "Return data should be 42");

        // Verify storage slot 0 was modified in the multicall contract (delegatecall context)
        assertEq(
            vm.load(address(multicall), bytes32(0)), bytes32(uint256(42)), "Storage slot 0 should be modified to 42"
        );
    }

    function test_aggregate3_failure() public {
        Multicall3Delegatecall.Call3[] memory calls = new Multicall3Delegatecall.Call3[](1);
        calls[0] = Multicall3Delegatecall.Call3({
            target: address(mockRevertingTarget),
            allowFailure: false,
            callData: abi.encodeWithSignature("anyFunction()")
        });

        vm.expectRevert("Multicall3: call failed");
        multicall.aggregate3(calls);
    }

    function test_aggregate3_delegatecallBehavior() public {
        Multicall3Delegatecall.Call3[] memory calls = new Multicall3Delegatecall.Call3[](1);
        calls[0] = Multicall3Delegatecall.Call3({
            target: address(mockTarget),
            allowFailure: false,
            callData: abi.encodeWithSignature("checkDelegatecall()")
        });

        Multicall3Delegatecall.Result[] memory results = multicall.aggregate3(calls);

        assertEq(results.length, 1);
        assertTrue(results[0].success);

        (address msgSender, address contractAddress, address txOrigin) =
            abi.decode(results[0].returnData, (address, address, address));

        assertEq(contractAddress, address(multicall), "Proves delegatecall behavior");
        assertEq(msgSender, address(this), "Preserves original caller");
        assertEq(txOrigin, DEFAULT_SENDER, "Uses foundry default sender");
    }
}
