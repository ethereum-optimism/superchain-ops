// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "safe-contracts/proxies/GnosisSafeProxyFactory.sol";

contract DeploySafe is Script {
    // These values are constant across chains
    GnosisSafeProxyFactory immutable SAFE_PROXY_FACTORY =
        GnosisSafeProxyFactory(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
    GnosisSafe immutable SAFE_SINGLETON = GnosisSafe(payable(0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552));

    function run(address[] calldata signers, uint256 threshold, string calldata name, string calldata dir) public {
        bytes memory initData = abi.encodeWithSelector(
            GnosisSafe.setup.selector, signers, threshold, address(0), hex"", address(0), address(0), 0, address(0)
        );
        address addr = address(
            SAFE_PROXY_FACTORY.createProxyWithNonce(
                address(SAFE_SINGLETON), initData, uint256(bytes32("superchain-ops")) + block.timestamp
            )
        );

        console.log("New safe deployed. Name: %s, Address: %s", name, addr);
        string memory path = string.concat(dir, "/", name, ".json");
        console.log("Saving JSON to %s", path);
        vm.writeJson({json: stdJson.serialize("", name, addr), path: string.concat(dir, "/", name, ".json")});
    }
}
