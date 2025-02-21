// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";

import {Multicall3Delegatecall} from "src/Multicall3Delegatecall.sol";

/// @notice Deploys the Multicall3Delegatecall contract to a deterministic address.
contract DeployMulticall3Delegatecall is Script {
    function run() public {
        vm.startBroadcast();

        // Deploys to 0x93dc480940585d9961bfceab58124ffd3d60f76a.
        new Multicall3Delegatecall{salt: "Multicall3Delegatecall"}();
        vm.stopBroadcast();
    }
}
