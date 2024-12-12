// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {AddressRegistry} from "src/fps/AddressRegistry.sol";

contract MainnetAddressRegistryTest is Test {
    AddressRegistry private addresses;

    function setUp() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";

        string memory tomlchainListPath = "src/fps/addresses/chainList.toml";

        vm.createSelectFork("mainnet");

        // Create the Addresses contract instance
        addresses = new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testContractState() public view {
        // Test that the contract state is set correctly
        assertEq(addresses.supportedChainId(), block.chainid, "Chain ID incorrect");
    }

    function testLocalAddressesLoaded() public view {
        // Test that the addresses are loaded correctly
        assertEq(
            addresses.getAddress("DEPLOYER_EOA", 10),
            0x9679E26bf0C470521DE83Ad77BB1bf1e7312f739,
            "DEPLOYER_EOA address mismatch"
        );
        assertEq(
            addresses.getAddress("COMPOUND_GOVERNOR_BRAVO", 10),
            0xc0Da02939E1441F497fd74F78cE7Decb17B66529,
            "COMPOUND_GOVERNOR_BRAVO address mismatch"
        );
        assertEq(
            addresses.getAddress("COMPOUND_CONFIGURATOR", 10),
            0x316f9708bB98af7dA9c68C1C3b5e79039cD336E3,
            "COMPOUND_CONFIGURATOR address mismatch"
        );

        assertTrue(
            addresses.isAddressContract("COMPOUND_GOVERNOR_BRAVO", 10), "Address governor bravo should be a contract"
        );
        assertTrue(addresses.isAddressContract("COMPOUND_CONFIGURATOR", 10), "Address configurator should be a contract");
        assertFalse(addresses.isAddressContract("DEPLOYER_EOA", 10), "EOA address should not be a contract");

        assertTrue(addresses.isAddressRegistered("DEPLOYER_EOA", 10), "DEPLOYER_EOA should be registered");
        assertTrue(
            addresses.isAddressRegistered("COMPOUND_GOVERNOR_BRAVO", 10), "COMPOUND_GOVERNOR_BRAVO should be registered"
        );
        assertTrue(addresses.isAddressRegistered("COMPOUND_CONFIGURATOR", 10), "COMPOUND_CONFIGURATOR should be registered");
        assertFalse(
            addresses.isAddressRegistered("NON_EXISTENT_ADDRESS", 10), "Non-existent address should not be registered"
        );
    }

    function testSuperchainAddressesLoaded() public view {
        // Test that the OP Mainnet addresses are loaded correctly with OP_MAINNET prefix
        assertEq(
            addresses.getAddress("OptimismPortalProxy", 10),
            0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
            "OP Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("L1StandardBridgeProxy", 10),
            0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1,
            "OP Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("L1CrossDomainMessengerProxy", 10),
            0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1,
            "OP Messenger address mismatch"
        );

        // Verify these are all contracts
        assertTrue(addresses.isAddressContract("OptimismPortalProxy", 10), "OP Portal should be a contract");
        assertTrue(addresses.isAddressContract("L1StandardBridgeProxy", 10), "OP Bridge should be a contract");
        assertTrue(
            addresses.isAddressContract("L1CrossDomainMessengerProxy", 10), "OP Messenger should be a contract"
        );

        // Verify they are registered
        assertTrue(addresses.isAddressRegistered("OptimismPortalProxy", 10), "OP Portal should be registered");
        assertTrue(addresses.isAddressRegistered("L1StandardBridgeProxy", 10), "OP Bridge should be registered");
        assertTrue(
            addresses.isAddressRegistered("L1CrossDomainMessengerProxy", 10), "OP Messenger should be registered"
        );

        // Test that the Base Mainnet addresses are loaded correctly with BASE_MAINNET prefix
        assertEq(
            addresses.getAddress("OptimismPortalProxy", 8453),
            0x49048044D57e1C92A77f79988d21Fa8fAF74E97e,
            "Base Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("L1StandardBridgeProxy", 8453),
            0x3154Cf16ccdb4C6d922629664174b904d80F2C35,
            "Base Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("L1CrossDomainMessengerProxy", 8453),
            0x866E82a600A1414e583f7F13623F1aC5d58b0Afa,
            "Base Messenger address mismatch"
        );

        // Verify these are all contracts
        assertTrue(addresses.isAddressContract("OptimismPortalProxy", 8453), "Base Portal should be a contract");
        assertTrue(
            addresses.isAddressContract("L1StandardBridgeProxy", 8453), "Base Bridge should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1CrossDomainMessengerProxy", 8453),
            "Base Messenger should be a contract"
        );

        // Verify they are registered
        assertTrue(
            addresses.isAddressRegistered("OptimismPortalProxy", 8453), "Base Portal should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1StandardBridgeProxy", 8453), "Base Bridge should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1CrossDomainMessengerProxy", 8453),
            "Base Messenger should be registered"
        );
    }

    function testInvalidChainIdInSuperchainsFails() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "test/mock/chainList1.toml";

        vm.expectRevert("Invalid chain ID in superchains");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testEmptyNameInSuperchainsFails() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "test/mock/chainList2.toml";

        vm.expectRevert("Empty name in superchains");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testGetNonExistentAddressFails() public {
        vm.expectRevert("Address not found");
        addresses.getAddress("NON_EXISTENT_ADDRESS", 10);
    }

    function testGetIsAddressContractNonExistentAddressFails() public {
        vm.expectRevert("Address not found for identifier NON_EXISTENT_ADDRESS on chain 10");
        addresses.isAddressContract("NON_EXISTENT_ADDRESS", 10);
    }

    function testConstructionFailsIncorrectTypesEOA() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data1";
        string memory tomlchainListPath = "test/mock/data1/chainList.toml";

        vm.expectRevert("Address must contain code");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testConstructionFailsIncorrectTypesContract() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data2";
        string memory tomlchainListPath = "test/mock/data2/chainList.toml";

        vm.expectRevert("Address must not contain code");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testConstructionFailsAddressZero() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data3";
        string memory tomlchainListPath = "test/mock/data3/chainList.toml";

        vm.expectRevert("Invalid address: cannot be zero");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testConstructionFailsDuplicateAddress() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data4";
        string memory tomlchainListPath = "test/mock/data4/chainList.toml";

        vm.expectRevert("Address already registered with this identifier and chain ID");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }
}
