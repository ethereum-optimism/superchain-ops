// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {AddressRegistry} from "src/fps/AddressRegistry.sol";
import {ORDERLY_CHAIN_ID, METAL_CHAIN_ID} from "src/fps/utils/Constants.sol";

contract MainnetAddressRegistryTest is Test {
    AddressRegistry private addresses;

    function setUp() public {
        string memory networkConfigFilePath = "src/fps/example/task-00/mainnetConfig.toml";

        vm.createSelectFork("mainnet");

        addresses = new AddressRegistry(networkConfigFilePath);
    }

    function testContractState() public view {
        assertTrue(addresses.supportedL2ChainIds(ORDERLY_CHAIN_ID), "Orderly chain ID not supported");
        assertTrue(addresses.supportedL2ChainIds(METAL_CHAIN_ID), "Metal chain ID not supported");
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
        string memory networkConfigFilePath = "test/mock/invalidChainIdNetworkConfig.toml";

        vm.expectRevert("Invalid chain ID in config");
        new AddressRegistry(networkConfigFilePath);
    }
}
