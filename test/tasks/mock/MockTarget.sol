// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

contract MockTarget is Test {
    address public task;
    bytes32 public START_SNAPSHOT_SLOT = bytes32(uint256(44));

    function setTask(address _task) public {
        task = _task;
    }

    function setSnapshotIdTask(uint256 id) public {
        vm.store(task, START_SNAPSHOT_SLOT, bytes32(id));
    }

    function foobar() public {
        // This function is when creating dummy/noop actions for testing.
    }
}
