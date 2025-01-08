// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {AddressRegistry} from "src/fps/AddressRegistry.sol";
import {ORDERLY_CHAIN_ID, METAL_CHAIN_ID} from "src/fps/utils/Constants.sol";

contract MainnetAddressRegistryTest is Test {
    AddressRegistry private addresses;

    function setUp() public {
        string memory addressFolderPath = "src/fps/addresses";

        string memory networkConfigFilePath = "src/fps/addresses/mainnetConfig.toml";

        vm.createSelectFork("mainnet");

        addresses = new AddressRegistry(addressFolderPath, networkConfigFilePath);
    }

    function testContractState() public view {
        assertTrue(addresses.supportedL2ChainIds(ORDERLY_CHAIN_ID), "Orderly chain ID not supported");
        assertTrue(addresses.supportedL2ChainIds(METAL_CHAIN_ID), "Metal chain ID not supported");
    }

    function testLocalAddressesLoaded() public view {
        assertEq(
            addresses.getAddress("DEPLOYER_EOA", ORDERLY_CHAIN_ID),
            0x9679E26bf0C470521DE83Ad77BB1bf1e7312f739,
            "DEPLOYER_EOA address mismatch"
        );
        assertEq(
            addresses.getAddress("COMPOUND_GOVERNOR_BRAVO", ORDERLY_CHAIN_ID),
            0xc0Da02939E1441F497fd74F78cE7Decb17B66529,
            "COMPOUND_GOVERNOR_BRAVO address mismatch"
        );
        assertEq(
            addresses.getAddress("COMPOUND_CONFIGURATOR", ORDERLY_CHAIN_ID),
            0x316f9708bB98af7dA9c68C1C3b5e79039cD336E3,
            "COMPOUND_CONFIGURATOR address mismatch"
        );

        assertTrue(
            addresses.isAddressContract("COMPOUND_GOVERNOR_BRAVO", ORDERLY_CHAIN_ID),
            "Address governor bravo should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("COMPOUND_CONFIGURATOR", ORDERLY_CHAIN_ID),
            "Address configurator should be a contract"
        );
        assertFalse(
            addresses.isAddressContract("DEPLOYER_EOA", ORDERLY_CHAIN_ID), "EOA address should not be a contract"
        );

        assertTrue(addresses.isAddressRegistered("DEPLOYER_EOA", ORDERLY_CHAIN_ID), "DEPLOYER_EOA should be registered");
        assertTrue(
            addresses.isAddressRegistered("COMPOUND_GOVERNOR_BRAVO", ORDERLY_CHAIN_ID),
            "COMPOUND_GOVERNOR_BRAVO should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("COMPOUND_CONFIGURATOR", ORDERLY_CHAIN_ID),
            "COMPOUND_CONFIGURATOR should be registered"
        );
        assertFalse(
            addresses.isAddressRegistered("NON_EXISTENT_ADDRESS", ORDERLY_CHAIN_ID),
            "Non-existent address should not be registered"
        );
    }

    function testSuperchainAddressesLoaded() public view {
        assertEq(
            addresses.getAddress("OptimismPortalProxy", ORDERLY_CHAIN_ID),
            0x91493a61ab83b62943E6dCAa5475Dd330704Cc84,
            "Orderly Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("L1StandardBridgeProxy", ORDERLY_CHAIN_ID),
            0xe07eA0436100918F157DF35D01dCE5c11b16D1F1,
            "Orderly Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("L1CrossDomainMessengerProxy", ORDERLY_CHAIN_ID),
            0xc76543A64666d9a073FaEF4e75F651c88e7DBC08,
            "Orderly Messenger address mismatch"
        );

        assertTrue(
            addresses.isAddressContract("OptimismPortalProxy", ORDERLY_CHAIN_ID), "Orderly Portal should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1StandardBridgeProxy", ORDERLY_CHAIN_ID),
            "Orderly Bridge should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1CrossDomainMessengerProxy", ORDERLY_CHAIN_ID),
            "Orderly Messenger should be a contract"
        );

        assertTrue(
            addresses.isAddressRegistered("OptimismPortalProxy", ORDERLY_CHAIN_ID),
            "Orderly Portal should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1StandardBridgeProxy", ORDERLY_CHAIN_ID),
            "Orderly Bridge should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1CrossDomainMessengerProxy", ORDERLY_CHAIN_ID),
            "Orderly Messenger should be registered"
        );

        assertEq(
            addresses.getAddress("OptimismPortalProxy", METAL_CHAIN_ID),
            0x3F37aBdE2C6b5B2ed6F8045787Df1ED1E3753956,
            "Metal Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("L1StandardBridgeProxy", METAL_CHAIN_ID),
            0x6d0f65D59b55B0FEC5d2d15365154DcADC140BF3,
            "Metal Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("L1CrossDomainMessengerProxy", METAL_CHAIN_ID),
            0x0a47A44f1B2bb753474f8c830322554A96C9934D,
            "Metal Messenger address mismatch"
        );

        assertTrue(
            addresses.isAddressContract("OptimismPortalProxy", METAL_CHAIN_ID), "Metal Portal should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1StandardBridgeProxy", METAL_CHAIN_ID), "Metal Bridge should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1CrossDomainMessengerProxy", METAL_CHAIN_ID),
            "Metal Messenger should be a contract"
        );

        assertTrue(
            addresses.isAddressRegistered("OptimismPortalProxy", METAL_CHAIN_ID), "Metal Portal should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1StandardBridgeProxy", METAL_CHAIN_ID), "Metal Bridge should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1CrossDomainMessengerProxy", METAL_CHAIN_ID),
            "Metal Messenger should be registered"
        );
    }

    function testInvalidL2ChainIdGetAddressFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.getAddress("DEPLOYER_EOA", 999);
    }

    function testGetNonExistentAddressFails() public {
        vm.expectRevert("Address not found");
        addresses.getAddress("NON_EXISTENT_ADDRESS", ORDERLY_CHAIN_ID);
    }

    function testInvalidL2ChainIdIsAddressContractFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.isAddressContract("DEPLOYER_EOA", 999);
    }

    function testGetIsAddressContractNonExistentAddressFails() public {
        vm.expectRevert("Address not found for identifier NON_EXISTENT_ADDRESS on chain 291");
        addresses.isAddressContract("NON_EXISTENT_ADDRESS", ORDERLY_CHAIN_ID);
    }

    /// Construction failure tests

    function testInvalidChainIdInSuperchainsFails() public {
        string memory addressFolderPath = "src/fps/addresses";
        string memory networkConfigFilePath = "test/mock/networkConfig1.toml";

        vm.expectRevert("Invalid chain ID in superchain config");
        new AddressRegistry(addressFolderPath, networkConfigFilePath);
    }

    function testEmptyNameInSuperchainsFails() public {
        string memory addressFolderPath = "src/fps/addresses";
        string memory networkConfigFilePath = "test/mock/networkConfig2.toml";

        vm.expectRevert("Empty name in superchain config");
        new AddressRegistry(addressFolderPath, networkConfigFilePath);
    }

    function testDuplicateChainIdInSuperchainsFails() public {
        string memory addressFolderPath = "src/fps/addresses";
        string memory networkConfigFilePath = "test/mock/networkConfig3.toml";

        vm.expectRevert("Duplicate chain ID in superchain config");
        new AddressRegistry(addressFolderPath, networkConfigFilePath);
    }

    function testConstructionFailsIncorrectTypesEOA() public {
        string memory addressFolderPath = "test/mock/data1";
        string memory networkConfigFilePath = "test/mock/data1/networkConfig.toml";

        vm.expectRevert("Address must contain code");
        new AddressRegistry(addressFolderPath, networkConfigFilePath);
    }

    function testConstructionFailsIncorrectTypesContract() public {
        string memory addressFolderPath = "test/mock/data2";
        string memory networkConfigFilePath = "test/mock/data2/networkConfig.toml";

        vm.expectRevert("Address must not contain code");
        new AddressRegistry(addressFolderPath, networkConfigFilePath);
    }

    function testConstructionFailsAddressZero() public {
        string memory addressFolderPath = "test/mock/data3";
        string memory networkConfigFilePath = "test/mock/data3/networkConfig.toml";

        vm.expectRevert("Invalid address: cannot be zero");
        new AddressRegistry(addressFolderPath, networkConfigFilePath);
    }

    function testConstructionFailsDuplicateAddress() public {
        string memory addressFolderPath = "test/mock/data4";
        string memory networkConfigFilePath = "test/mock/data4/networkConfig.toml";

        vm.expectRevert("Address already registered with this identifier and chain ID");
        new AddressRegistry(addressFolderPath, networkConfigFilePath);
    }
}
