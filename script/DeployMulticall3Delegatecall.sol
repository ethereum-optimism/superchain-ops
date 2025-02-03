// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";

import {Multicall3Delegatecall} from "src/Multicall3Delegatecall.sol";

/// @notice Deploys the Multicall3Delegatecall contract to a deterministic address.
contract DeployMulticall3Delegatecall is Script {
    function run() public {
        vm.startBroadcast();

        // Deploys to 0x95b259eae68ba96edB128eF853fFbDffe47D2Db0.
        new Multicall3Delegatecall{salt: "Multicall3Delegatecall"}();
        vm.stopBroadcast();
    }
}
