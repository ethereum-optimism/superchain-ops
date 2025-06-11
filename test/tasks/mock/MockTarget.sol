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
        bytes32 startSnapshotSlot = bytes32(uint256(stdstore.target(address(task)).sig("getStartSnapshot()").find()));
        vm.store(task, startSnapshotSlot, bytes32(id));
    }

    function foobar() public {
        // This function is when creating dummy/noop actions for testing.
    }
}
