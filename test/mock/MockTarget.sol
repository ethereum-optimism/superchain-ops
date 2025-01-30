// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

contract MockTarget is Test {
    address public task;

    function setTask(address _task) public {
        task = _task;
    }

    function setSnapshotIdTask(uint256 id) public {
        vm.store(
            task,
            bytes32(uint256(48)),
            bytes32(id)
        );
    }
}
