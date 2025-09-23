// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {OPCMUpgradeV400} from "src/template/OPCMUpgradeV400.sol";
import {TaskType} from "src/libraries/MultisigTypes.sol";

contract OPCMTaskBase_Test is Test {
    /// @notice Test that safeAddressString returns the correct value
    function test_safeAddressString() public {
        OPCMUpgradeV400 opcmTask = new OPCMUpgradeV400();
        string memory result = opcmTask.safeAddressString();
        assertEq(result, "ProxyAdminOwner", "safeAddressString should return 'ProxyAdminOwner'");
    }

    /// @notice Test that taskType returns the correct value
    function test_taskType() public {
        OPCMUpgradeV400 opcmTask = new OPCMUpgradeV400();
        TaskType result = opcmTask.taskType();
        assertEq(uint256(result), uint256(TaskType.OPCMTaskBase), "taskType should return OPCMTaskBase");
    }
}
