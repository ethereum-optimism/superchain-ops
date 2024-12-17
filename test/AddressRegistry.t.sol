// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {AddressRegistry} from "src/fps/AddressRegistry.sol";
import {BASE_CHAIN_ID, OP_CHAIN_ID} from "src/fps/utils/Constants.sol";

contract MainnetAddressRegistryTest is Test {
    AddressRegistry private addresses;

    function setUp() public {
        string memory tomlFilePath = "src/fps/addresses";

        string memory tomlchainListPath = "src/fps/addresses/chainList.toml";

        vm.createSelectFork("mainnet");

        addresses = new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testContractState() public view {
        assertTrue(addresses.supportedL2ChainIds(OP_CHAIN_ID), "Optimism chain ID not supported");
        assertTrue(addresses.supportedL2ChainIds(BASE_CHAIN_ID), "Base chain ID not supported");
    }

    function testLocalAddressesLoaded() public view {
        assertEq(
            addresses.getAddress("DEPLOYER_EOA", OP_CHAIN_ID),
            0x9679E26bf0C470521DE83Ad77BB1bf1e7312f739,
            "DEPLOYER_EOA address mismatch"
        );
        assertEq(
            addresses.getAddress("COMPOUND_GOVERNOR_BRAVO", OP_CHAIN_ID),
            0xc0Da02939E1441F497fd74F78cE7Decb17B66529,
            "COMPOUND_GOVERNOR_BRAVO address mismatch"
        );
        assertEq(
            addresses.getAddress("COMPOUND_CONFIGURATOR", OP_CHAIN_ID),
            0x316f9708bB98af7dA9c68C1C3b5e79039cD336E3,
            "COMPOUND_CONFIGURATOR address mismatch"
        );

        assertTrue(
            addresses.isAddressContract("COMPOUND_GOVERNOR_BRAVO", OP_CHAIN_ID),
            "Address governor bravo should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("COMPOUND_CONFIGURATOR", OP_CHAIN_ID),
            "Address configurator should be a contract"
        );
        assertFalse(addresses.isAddressContract("DEPLOYER_EOA", OP_CHAIN_ID), "EOA address should not be a contract");

        assertTrue(addresses.isAddressRegistered("DEPLOYER_EOA", OP_CHAIN_ID), "DEPLOYER_EOA should be registered");
        assertTrue(
            addresses.isAddressRegistered("COMPOUND_GOVERNOR_BRAVO", OP_CHAIN_ID),
            "COMPOUND_GOVERNOR_BRAVO should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("COMPOUND_CONFIGURATOR", OP_CHAIN_ID),
            "COMPOUND_CONFIGURATOR should be registered"
        );
        assertFalse(
            addresses.isAddressRegistered("NON_EXISTENT_ADDRESS", OP_CHAIN_ID),
            "Non-existent address should not be registered"
        );
    }

    function testSuperchainAddressesLoaded() public view {
        assertEq(
            addresses.getAddress("OptimismPortalProxy", OP_CHAIN_ID),
            0xbEb5Fc579115071764c7423A4f12eDde41f106Ed,
            "OP Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("L1StandardBridgeProxy", OP_CHAIN_ID),
            0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1,
            "OP Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("L1CrossDomainMessengerProxy", OP_CHAIN_ID),
            0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1,
            "OP Messenger address mismatch"
        );

        assertTrue(addresses.isAddressContract("OptimismPortalProxy", OP_CHAIN_ID), "OP Portal should be a contract");
        assertTrue(addresses.isAddressContract("L1StandardBridgeProxy", OP_CHAIN_ID), "OP Bridge should be a contract");
        assertTrue(
            addresses.isAddressContract("L1CrossDomainMessengerProxy", OP_CHAIN_ID), "OP Messenger should be a contract"
        );

        assertTrue(addresses.isAddressRegistered("OptimismPortalProxy", OP_CHAIN_ID), "OP Portal should be registered");
        assertTrue(
            addresses.isAddressRegistered("L1StandardBridgeProxy", OP_CHAIN_ID), "OP Bridge should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1CrossDomainMessengerProxy", OP_CHAIN_ID),
            "OP Messenger should be registered"
        );

        assertEq(
            addresses.getAddress("OptimismPortalProxy", BASE_CHAIN_ID),
            0x49048044D57e1C92A77f79988d21Fa8fAF74E97e,
            "Base Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("L1StandardBridgeProxy", BASE_CHAIN_ID),
            0x3154Cf16ccdb4C6d922629664174b904d80F2C35,
            "Base Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("L1CrossDomainMessengerProxy", BASE_CHAIN_ID),
            0x866E82a600A1414e583f7F13623F1aC5d58b0Afa,
            "Base Messenger address mismatch"
        );

        assertTrue(
            addresses.isAddressContract("OptimismPortalProxy", BASE_CHAIN_ID), "Base Portal should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1StandardBridgeProxy", BASE_CHAIN_ID), "Base Bridge should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1CrossDomainMessengerProxy", BASE_CHAIN_ID),
            "Base Messenger should be a contract"
        );

        assertTrue(
            addresses.isAddressRegistered("OptimismPortalProxy", BASE_CHAIN_ID), "Base Portal should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1StandardBridgeProxy", BASE_CHAIN_ID), "Base Bridge should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1CrossDomainMessengerProxy", BASE_CHAIN_ID),
            "Base Messenger should be registered"
        );
    }

    function testInvalidL2ChainIdGetAddressFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.getAddress("DEPLOYER_EOA", 999);
    }

    function testGetNonExistentAddressFails() public {
        vm.expectRevert("Address not found");
        addresses.getAddress("NON_EXISTENT_ADDRESS", OP_CHAIN_ID);
    }

    function testInvalidL2ChainIdIsAddressContractFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.isAddressContract("DEPLOYER_EOA", 999);
    }

    function testGetIsAddressContractNonExistentAddressFails() public {
        vm.expectRevert("Address not found for identifier NON_EXISTENT_ADDRESS on chain 10");
        addresses.isAddressContract("NON_EXISTENT_ADDRESS", OP_CHAIN_ID);
    }

    /// Construction failure tests

    function testInvalidChainIdInSuperchainsFails() public {
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "test/mock/chainList1.toml";

        vm.expectRevert("Invalid chain ID in superchain config");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testDuplicateChainIdInSuperchainsFails() public {
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "test/mock/chainList3.toml";

        vm.expectRevert("Duplicate chain ID in superchain config");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testEmptyNameInSuperchainsFails() public {
        string memory tomlFilePath = "src/fps/addresses";
        string memory tomlchainListPath = "test/mock/chainList2.toml";

        vm.expectRevert("Empty name in superchain config");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testConstructionFailsIncorrectTypesEOA() public {
        string memory tomlFilePath = "test/mock/data1";
        string memory tomlchainListPath = "test/mock/data1/chainList.toml";

        vm.expectRevert("Address must contain code");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testConstructionFailsIncorrectTypesContract() public {
        string memory tomlFilePath = "test/mock/data2";
        string memory tomlchainListPath = "test/mock/data2/chainList.toml";

        vm.expectRevert("Address must not contain code");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testConstructionFailsAddressZero() public {
        string memory tomlFilePath = "test/mock/data3";
        string memory tomlchainListPath = "test/mock/data3/chainList.toml";

        vm.expectRevert("Invalid address: cannot be zero");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }

    function testConstructionFailsDuplicateAddress() public {
        string memory tomlFilePath = "test/mock/data4";
        string memory tomlchainListPath = "test/mock/data4/chainList.toml";

        vm.expectRevert("Address already registered with this identifier and chain ID");
        new AddressRegistry(tomlFilePath, tomlchainListPath);
    }
}
