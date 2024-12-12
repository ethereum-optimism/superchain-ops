// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {AddressRegistry} from "src/fps/AddressRegistry.sol";

contract MainnetAddressRegistryTest is Test {
    AddressRegistry private addresses;

    function setUp() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";

        string memory tomlchainListPath = "src/fps/chainList.toml";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.createSelectFork("mainnet");

        // Create the Addresses contract instance
        addresses = new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testContractState() public view {
        // Test that the contract state is set correctly
        assertEq(addresses.supportedChainIds(), block.chainid, "Chain ID incorrect");
    }

    function testLocalAddressesLoaded() public view {
        // Test that the addresses are loaded correctly
        assertEq(
            addresses.getAddress("DEPLOYER_EOA"),
            0x9679E26bf0C470521DE83Ad77BB1bf1e7312f739,
            "DEPLOYER_EOA address mismatch"
        );
        assertEq(
            addresses.getAddress("COMPOUND_GOVERNOR_BRAVO"),
            0xc0Da02939E1441F497fd74F78cE7Decb17B66529,
            "COMPOUND_GOVERNOR_BRAVO address mismatch"
        );
        assertEq(
            addresses.getAddress("COMPOUND_CONFIGURATOR"),
            0x316f9708bB98af7dA9c68C1C3b5e79039cD336E3,
            "COMPOUND_CONFIGURATOR address mismatch"
        );

        assertTrue(
            addresses.isAddressContract("COMPOUND_GOVERNOR_BRAVO"), "Address governor bravo should be a contract"
        );
        assertTrue(addresses.isAddressContract("COMPOUND_CONFIGURATOR"), "Address configurator should be a contract");
        assertFalse(addresses.isAddressContract("DEPLOYER_EOA"), "EOA address should not be a contract");

        assertTrue(addresses.isAddressRegistered("DEPLOYER_EOA"), "DEPLOYER_EOA should be registered");
        assertTrue(
            addresses.isAddressRegistered("COMPOUND_GOVERNOR_BRAVO"), "COMPOUND_GOVERNOR_BRAVO should be registered"
        );
        assertTrue(addresses.isAddressRegistered("COMPOUND_CONFIGURATOR"), "COMPOUND_CONFIGURATOR should be registered");
        assertFalse(
            addresses.isAddressRegistered("NON_EXISTENT_ADDRESS"), "Non-existent address should not be registered"
        );
    }

    function testSuperchainAddressesLoaded() public view {
        // Test that the OP Mainnet addresses are loaded correctly with OP_MAINNET prefix
        assertEq(
            addresses.getAddress("OP_MAINNET_OptimismPortalProxy"),
            0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
            "OP Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("OP_MAINNET_L1StandardBridgeProxy"),
            0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1,
            "OP Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("OP_MAINNET_L1CrossDomainMessengerProxy"),
            0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1,
            "OP Messenger address mismatch"
        );

        // Verify these are all contracts
        assertTrue(addresses.isAddressContract("OP_MAINNET_OptimismPortalProxy"), "OP Portal should be a contract");
        assertTrue(addresses.isAddressContract("OP_MAINNET_L1StandardBridgeProxy"), "OP Bridge should be a contract");
        assertTrue(
            addresses.isAddressContract("OP_MAINNET_L1CrossDomainMessengerProxy"), "OP Messenger should be a contract"
        );

        // Verify they are registered
        assertTrue(addresses.isAddressRegistered("OP_MAINNET_OptimismPortalProxy"), "OP Portal should be registered");
        assertTrue(addresses.isAddressRegistered("OP_MAINNET_L1StandardBridgeProxy"), "OP Bridge should be registered");
        assertTrue(
            addresses.isAddressRegistered("OP_MAINNET_L1CrossDomainMessengerProxy"), "OP Messenger should be registered"
        );

        // Test that the Base Mainnet addresses are loaded correctly with BASE_MAINNET prefix
        assertEq(
            addresses.getAddress("BASE_MAINNET_OptimismPortalProxy"),
            0x49048044D57e1C92A77f79988d21Fa8fAF74E97e,
            "Base Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("BASE_MAINNET_L1StandardBridgeProxy"),
            0x3154Cf16ccdb4C6d922629664174b904d80F2C35,
            "Base Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("BASE_MAINNET_L1CrossDomainMessengerProxy"),
            0x866E82a600A1414e583f7F13623F1aC5d58b0Afa,
            "Base Messenger address mismatch"
        );

        // Verify these are all contracts
        assertTrue(addresses.isAddressContract("BASE_MAINNET_OptimismPortalProxy"), "Base Portal should be a contract");
        assertTrue(
            addresses.isAddressContract("BASE_MAINNET_L1StandardBridgeProxy"), "Base Bridge should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("BASE_MAINNET_L1CrossDomainMessengerProxy"),
            "Base Messenger should be a contract"
        );

        // Verify they are registered
        assertTrue(
            addresses.isAddressRegistered("BASE_MAINNET_OptimismPortalProxy"), "Base Portal should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("BASE_MAINNET_L1StandardBridgeProxy"), "Base Bridge should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("BASE_MAINNET_L1CrossDomainMessengerProxy"),
            "Base Messenger should be registered"
        );
    }

    function testInvalidChainIdInSuperchainsFails() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "test/mock/chainList1.toml";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Invalid chain ID in superchains");
        new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testEmptyIdentifierInSuperchainsFails() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "test/mock/chainList2.toml";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Empty identifier in superchains");
        new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testEmptyNameInSuperchainsFails() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "test/mock/chainList3.toml";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Empty name in superchains");
        new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testMismatchChainIdCreationFails() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "src/fps/chainList.toml";

        // Define the chain ID to be used
        uint256 chainId = 31337; // Assuming chain ID 31337 for this test

        vm.expectRevert("Chain ID mismatch in config");
        new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
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
        string memory tomlchainListPath = "src/fps/chainList.toml";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Address must contain code");
        new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testConstructionFailsIncorrectTypesContract() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data2";
        string memory tomlchainListPath = "src/fps/chainList.toml";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Address must not contain code");
        new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testConstructionFailsAddressZero() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data3";
        string memory tomlchainListPath = "src/fps/chainList.toml";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Invalid address: cannot be zero");
        new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testConstructionFailsChainIdZero() public {
        vm.chainId(0);

        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data4";
        string memory tomlchainListPath = "src/fps/chainList.toml";

        // Define the chain ID to be used
        uint256 chainId = 0;

        vm.expectRevert("Invalid chain ID: cannot be zero");
        new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testConstructionFailsDuplicateAddress() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "test/mock/data5";
        string memory tomlchainListPath = "src/fps/chainList.toml";

        // Define the chain ID to be used
        uint256 chainId = 1;

        vm.expectRevert("Address already registered with this identifier and chain ID");
        new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);
    }

    function testChainNotSupported() public {
        // Define the path to the TOML file
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "src/fps/chainList.toml";

        // Define the chain ID to be used
        uint256 chainId = 1;

        // Create the Addresses contract instance
        addresses = new AddressRegistry(tomlFilePath, tomlchainListPath, chainId);

        // Switch to an unsupported chain
        vm.chainId(2);

        // Try to get an address on unsupported chain
        vm.expectRevert("Chain ID 2 not supported");
        addresses.getAddress("DEPLOYER_EOA");
    }

    /// todo test:
    ///     address is 0
    ///     chain id is 0
    ///     duplicate address

    /// Type check only supported for the current chain
}
