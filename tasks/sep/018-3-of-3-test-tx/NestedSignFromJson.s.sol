// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {

    // Chains for this task.
    string constant l1ChainName = "sepolia";

    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe foundationSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe chainGovernorSafe = GnosisSafe(payable(vm.envAddress("CHAIN_GOVERNOR_SAFE")));
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    /// @notice Sets up the contract
    function setUp() public {
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](4);
        allowed[0] = address(chainGovernorSafe);
        allowed[1] = address(ownerSafe);
        allowed[2] = address(securityCouncilSafe);
        allowed[3] = address(foundationSafe);
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory exceptions = new address[](0);
        return exceptions;
    }


    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);

        console.log("All assertions passed!");
    }


}
