// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {HelloWorld} from "../src/HelloWorld.sol";

contract DeployHelloWorld is Script {
    function run(address auth) public returns (HelloWorld helloWorld) {
        // Deploy HelloWorld.sol
        vm.startBroadcast();
        helloWorld = new HelloWorld(auth);
        vm.stopBroadcast();
    }
}
