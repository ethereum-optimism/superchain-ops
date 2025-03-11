// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";

contract CalculateSafeHashes is Script {
    function run() external view {
        // Parse JSON payload
        string memory json = vm.envString("TENDERLY_PAYLOAD");
        string memory inputHex = vm.parseJsonString(json, ".input");
        uint256 chainId = vm.parseJsonUint(json, ".network_id");
        address payable safeAddress = payable(vm.parseJsonAddress(json, ".to"));

        // Get nonce from storage
        string memory storagePath = string(
            abi.encodePacked(
                ".state_objects.",
                vm.toString(safeAddress),
                ".storage.0x0000000000000000000000000000000000000000000000000000000000000005"
            )
        );
        uint256 nonce = uint256(vm.parseBytes32(vm.parseJsonString(json, storagePath)));

        // Convert hex string to bytes
        bytes memory callData = vm.parseBytes(inputHex);

        // Calculate domain separator
        bytes32 domainSeparator = GnosisSafeHashes.calculateDomainSeparator(chainId, safeAddress);

        // Calculate message hash
        bytes32 messageHash = GnosisSafeHashes.calculateMessageHashFromCalldata(callData, nonce);

        // Output results
        console.log("\n\n-------- Domain Separator and Message Hashes from Local Simulation --------");
        console.log("Forge Domain Separator:", vm.toString(domainSeparator));
        console.log("Forge Message Hash:", vm.toString(messageHash));
    }
}
