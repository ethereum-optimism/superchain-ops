// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {AddressRegistry} from "src/fps/AddressRegistry.sol";

contract MainnetAddressRegistryTest is Test {
    AddressRegistry private addresses;

    function setUp() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.createSelectFork("mainnet");

        // Create the Addresses contract instance
        addresses = new AddressRegistry(tomlFilePath, chainId);
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

        assertTrue(addresses.isAddressContract("COMPOUND_GOVERNOR_BRAVO"), "Address governor bravo should be a contract");
        assertTrue(addresses.isAddressContract("COMPOUND_CONFIGURATOR"), "Address configurator should be a contract");
        assertFalse(addresses.isAddressContract("DEPLOYER_EOA"), "EOA address should not be a contract");
    }

    function testMismatchChainIdCreationFails() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";

        // Define the chain ID to be used
        uint256 chainId = 31337; // Assuming chain ID 31337 for this test

        vm.expectRevert("Chain ID mismatch in config");
        new AddressRegistry(tomlFilePath, chainId);
    }

    function testGetNonExistentAddressFails() public {
        vm.expectRevert("Address not found");
        addresses.getAddress("NON_EXISTENT_ADDRESS");
    }

    function testGetIsAddressContractNonExistentAddressFails() public {
        vm.expectRevert("Address not found for identifier NON_EXISTENT_ADDRESS on chain 1");
        addresses.isAddressContract("NON_EXISTENT_ADDRESS");
    }

    function testIsAddressRegisteredInvalidChainFails(uint256 chainid) public {
        vm.assume(chainid != 1);

        chainid = bound(chainid, 2, type(uint64).max - 1);
        vm.chainId(chainid);
        vm.expectRevert(abi.encodePacked("Chain ID ", vm.toString(chainid), " not supported"));
        addresses.isAddressRegistered("DEPLOYER_EOA");
    }

    function testConstructionFailsIncorrectTypesEOA() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data1";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Address must contain code");
        new AddressRegistry(tomlFilePath, chainId);
    }

    function testConstructionFailsIncorrectTypesContract() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data2";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Address must not contain code");
        new AddressRegistry(tomlFilePath, chainId);
    }

    function testConstructionFailsAddressZero() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data3";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Invalid address: cannot be zero");
        new AddressRegistry(tomlFilePath, chainId);
    }

    function testConstructionFailsChainIdZero() public {
        vm.chainId(0);

        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data4";

        // Define the chain ID to be used
        uint256 chainId = 0;

        vm.expectRevert("Invalid chain ID: cannot be zero");
        new AddressRegistry(tomlFilePath, chainId);
    }

    function testConstructionFailsDuplicateAddress() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data5";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Address already registered with this identifier and chain ID");
        new AddressRegistry(tomlFilePath, chainId);
    }

    /// todo test:
    ///     address is 0
    ///     chain id is 0
    ///     duplicate address

    /// Type check only supported for the current chain
}
