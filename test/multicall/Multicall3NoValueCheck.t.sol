// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Multicall3NoValueCheck} from "src/Multicall3NoValueCheck.sol";
import {MockCallee} from "test/multicall/mocks/MockCallee.sol";
import {EtherSink} from "test/multicall/mocks/EtherSink.sol";

contract Multicall3NoValueCheckTest is Test {
    Multicall3NoValueCheck multicall;
    MockCallee callee;
    EtherSink etherSink;

    /// @notice Setups up the testing suite
    function setUp() public {
        multicall = new Multicall3NoValueCheck();
        callee = new MockCallee();
        etherSink = new EtherSink();
    }

    /// >>>>>>>>>>>>>>>>>  AGGREGATE3VALUE TESTS  <<<<<<<<<<<<<<<<<<< ///

    function testAggregate3Value() public {
        Multicall3NoValueCheck.Call3Value[] memory calls = new Multicall3NoValueCheck.Call3Value[](3);
        calls[0] = Multicall3NoValueCheck.Call3Value(
            address(callee), false, 0, abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        calls[1] =
            Multicall3NoValueCheck.Call3Value(address(callee), true, 0, abi.encodeWithSignature("thisMethodReverts()"));
        calls[2] = Multicall3NoValueCheck.Call3Value(
            address(callee), false, 1, abi.encodeWithSignature("sendBackValue(address)", address(etherSink))
        );
        uint256 balanceBefore = address(this).balance;
        (bool success, bytes memory data) = address(multicall).delegatecall(
            abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls)
        );
        require(success, "Delegate call failed");
        uint256 balanceAfter = address(this).balance;
        assertEq(balanceBefore, balanceAfter + 1);
        Multicall3NoValueCheck.Result[] memory returnData = abi.decode(data, (Multicall3NoValueCheck.Result[]));
        assertTrue(returnData[0].success);
        assertEq(keccak256(returnData[0].returnData), keccak256(abi.encodePacked(blockhash(block.number))));
        assertTrue(!returnData[1].success);
        assertTrue(returnData[2].success);
    }

    function testAggregate3ValueUnsuccessful() public {
        // Only delegate calls to multicall contract are allowed
        Multicall3NoValueCheck.Call3Value[] memory calls = new Multicall3NoValueCheck.Call3Value[](3);
        calls[0] = Multicall3NoValueCheck.Call3Value(
            address(callee), false, 0, abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        calls[1] =
            Multicall3NoValueCheck.Call3Value(address(callee), true, 0, abi.encodeWithSignature("thisMethodReverts()"));
        calls[2] = Multicall3NoValueCheck.Call3Value(
            address(callee), false, 1, abi.encodeWithSignature("sendBackValue(address)", address(etherSink))
        );
        vm.expectRevert(bytes("Multicall3: only delegate call allowed"));
        multicall.aggregate3Value(calls);

        // Should fail if insufficient balance
        calls[0] = Multicall3NoValueCheck.Call3Value(
            address(callee), false, 0, abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        calls[1] =
            Multicall3NoValueCheck.Call3Value(address(callee), true, 0, abi.encodeWithSignature("thisMethodReverts()"));
        calls[2] = Multicall3NoValueCheck.Call3Value(
            address(callee), false, 1, abi.encodeWithSignature("sendBackValue(address)", address(etherSink))
        );
        vm.deal(address(this), 0);
        (bool success, bytes memory returnData) = address(multicall).delegatecall(
            abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls)
        );
        assertFalse(success, "Delegate call should fail");
        bytes memory expectedRevertData =
            hex"08c379a0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000174d756c746963616c6c333a2063616c6c206661696c65640000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        assertEq(returnData, expectedRevertData);

        // Should fail if one of the calls reverts and allowFailure is false
        calls[0] = Multicall3NoValueCheck.Call3Value(
            address(callee), false, 0, abi.encodeWithSignature("getBlockHash(uint256)", block.number)
        );
        calls[1] =
            Multicall3NoValueCheck.Call3Value(address(callee), false, 0, abi.encodeWithSignature("thisMethodReverts()"));
        calls[2] = Multicall3NoValueCheck.Call3Value(
            address(callee), false, 1, abi.encodeWithSignature("sendBackValue(address)", address(etherSink))
        );
        (success, returnData) = address(multicall).delegatecall(
            abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls)
        );
        assertFalse(success, "Delegate call should fail");
        assertEq(returnData, expectedRevertData);
    }
}
