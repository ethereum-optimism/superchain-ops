// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMTaskBase} from "src/improvements/tasks/types/OPCMTaskBase.sol";
import {Action, TaskType, TaskPayload} from "src/libraries/MultisigTypes.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {OPCMUpgradeV400} from "src/improvements/template/OPCMUpgradeV400.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Action, TaskType, TaskPayload} from "src/libraries/MultisigTypes.sol";
import {
    IOPContractsManager,
    ISystemConfig,
    IProxyAdmin
} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOPContractsManager.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

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
