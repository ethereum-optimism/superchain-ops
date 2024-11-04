// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";

contract SignFromJson is OriginalSignFromJson {

    address owner = vm.envAddress("OWNER_SAFE");
    address delayedWETH = vm.envAddress("DELAYED_WETH_PROXY");
    uint256 expectedBalanceChange = vm.envUint("WAD_VALUE");
    uint256 prevOwnerBalance;
    uint256 prevDelayedWETHBalance;

    /// @notice Sets up the contract
    function setUp() public {
        // Save the ETH balances of the owner and DelayedWETHProxy contract prior to the execution of the transaction
        prevOwnerBalance = owner.balance;
        prevDelayedWETHBalance = delayedWETH.balance;
    }

    function checkBalances() internal view {
        // Check the balances of the owner of the DelayedWETHProxy contract and the contract itself
        // The differences between the balances should be exactly equal to expectedBalanceChange
        require(owner.balance - prevOwnerBalance == expectedBalanceChange, "Owner balance mismatch");
        require(prevDelayedWETHBalance - delayedWETH.balance == expectedBalanceChange, "DelayedWETH balance mismatch");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory /* accesses */, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        // no call to checkStateDiff because it asserts no balance changes, which is the only change this task makes
        checkBalances();

        console.log("All assertions passed!");
    }
}