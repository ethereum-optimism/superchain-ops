// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

contract MockTarget is Test {
    using stdStorage for StdStorage;

    address public task;

    function setTask(address _task) public {
        task = _task;
    }

    function setSnapshotIdTask(uint256 id) public {
        bytes32 startSnapshotSlot =
            bytes32(uint256(stdstore.target(address(task)).sig("getPreExecutionSnapshot()").find()));
        vm.store(task, startSnapshotSlot, bytes32(id));
    }

    /// @notice Function that consumes a lot of gas through memory expansion.
    ///         Used to test that MultisigTask correctly rejects transactions that consume gas
    ///         too close to the Fusaka EIP-7825 cap of 16,777,216 gas.
    function consumeGas() public {
        // Expand memory to consume ~17M gas. Memory expansion cost grows quadratically, so we
        // need to allocate enough memory to exceed the 15M threshold in MultisigTask.sol.
        bytes memory largeData1 = new bytes(200000); // 200KB
        bytes memory largeData2 = new bytes(400000); // 400KB
        bytes memory largeData3 = new bytes(800000); // 800KB
        bytes memory largeData4 = new bytes(1600000); // 1.6MB

        // Write to storage to ensure this call is captured as an action, if this function was
        // view or pure it would get filtered out by MultisigTask.sol.
        uint256 sum;
        assembly {
            // Touch each array to prevent these from being optimized away.
            let val1 := mload(add(largeData1, 32))
            let val2 := mload(add(largeData2, 32))
            let val3 := mload(add(largeData3, 32))
            let val4 := mload(add(largeData4, 32))
            sum := add(add(add(val1, val2), val3), val4)
        }

        // Write to storage to make this a state-changing function
        task = address(uint160(sum));
    }
}
