// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {AddressRegistry} from "src/fps/AddressRegistry.sol";

contract LocalAddressRegistryTest is Test {
    AddressRegistry private addresses;

    function setUp() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";

        string memory tomlchainListPath = "src/fps/chainList.toml";

        // Define the chain ID to be used
        uint256 chainId = 31337; // Assuming chain ID 31337 for this test

        // Create the Addresses contract instance
        addresses = new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testContractState() public view {
        // Test that the contract state is set correctly
        assertEq(addresses.supportedChainIds(), block.chainid, "Chain ID incorrect");
    }

    function testAddressesLoaded() public view {
        // Test that the addresses are loaded correctly
        addresses.getAddress("DEPLOYER_EOA");
        addresses.getAddress("COMPOUND_GOVERNOR_BRAVO");
        addresses.getAddress("COMPOUND_CONFIGURATOR");
    }
}
