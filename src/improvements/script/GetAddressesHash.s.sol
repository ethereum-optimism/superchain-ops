pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";


contract GetAddressesHash is Script {
    string addressesPath = "lib/superchain-registry/superchain/extra/addresses/addresses.json";

    function run() public {
        bytes32 hash = keccak256(bytes(vm.readFile(addressesPath)));
        string memory hashString = vm.toString(hash);
        vm.writeFile("hash.txt", hashString);
    }

    function matchHash() public {
        bytes32 newHash = keccak256(bytes(vm.readFile(addressesPath)));
        bytes32 oldHash = vm.parseBytes32(vm.readFile("hash.txt"));
        require(newHash == oldHash, "superchain-registry is not up to date");
    }
}
