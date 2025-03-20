// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";

import {Multicall3NoValueCheck} from "src/Multicall3NoValueCheck.sol";

/// @notice Deploys the Multicall3NoValueCheck contract to a deterministic address.
contract DeployMulticall3NoValueCheck is Script {
    function run() public {
        vm.startBroadcast();

        // Deploys to 0x90664A63412b9B07bBfbeaCfe06c1EA5a855014c.
        new Multicall3NoValueCheck{salt: "Multicall3NoValueCheck"}();
        vm.stopBroadcast();
    }
}
