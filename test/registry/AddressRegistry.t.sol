// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {AddressRegistry} from "src/fps/AddressRegistry.sol";

contract MainnetAddressRegistryTest is Test {
    AddressRegistry private addresses;

    uint256 public orderlyChainId;
    uint256 public metalChainId;

    function setUp() public {
        string memory networkConfigFilePath = "src/fps/example/task-00/mainnetConfig.toml";

        vm.createSelectFork("mainnet");

        addresses = new AddressRegistry(networkConfigFilePath);
        orderlyChainId = getChain("orderly").chainId;
        metalChainId = getChain("metal").chainId;
    }

    function testContractState() public view {
        assertTrue(addresses.supportedL2ChainIds(orderlyChainId), "Orderly chain ID not supported");
        assertTrue(addresses.supportedL2ChainIds(metalChainId), "Metal chain ID not supported");
    }

    function testSuperchainAddressesLoaded() public view {
        assertEq(
            addresses.getAddress("OptimismPortalProxy", orderlyChainId),
            0x91493a61ab83b62943E6dCAa5475Dd330704Cc84,
            "Orderly Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("L1StandardBridgeProxy", orderlyChainId),
            0xe07eA0436100918F157DF35D01dCE5c11b16D1F1,
            "Orderly Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("L1CrossDomainMessengerProxy", orderlyChainId),
            0xc76543A64666d9a073FaEF4e75F651c88e7DBC08,
            "Orderly Messenger address mismatch"
        );

        assertTrue(
            addresses.isAddressContract("OptimismPortalProxy", orderlyChainId), "Orderly Portal should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1StandardBridgeProxy", orderlyChainId), "Orderly Bridge should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1CrossDomainMessengerProxy", orderlyChainId),
            "Orderly Messenger should be a contract"
        );

        assertTrue(
            addresses.isAddressRegistered("OptimismPortalProxy", orderlyChainId), "Orderly Portal should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1StandardBridgeProxy", orderlyChainId),
            "Orderly Bridge should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1CrossDomainMessengerProxy", orderlyChainId),
            "Orderly Messenger should be registered"
        );

        assertEq(
            addresses.getAddress("OptimismPortalProxy", metalChainId),
            0x3F37aBdE2C6b5B2ed6F8045787Df1ED1E3753956,
            "Metal Portal address mismatch"
        );
        assertEq(
            addresses.getAddress("L1StandardBridgeProxy", metalChainId),
            0x6d0f65D59b55B0FEC5d2d15365154DcADC140BF3,
            "Metal Bridge address mismatch"
        );
        assertEq(
            addresses.getAddress("L1CrossDomainMessengerProxy", metalChainId),
            0x0a47A44f1B2bb753474f8c830322554A96C9934D,
            "Metal Messenger address mismatch"
        );

        assertTrue(
            addresses.isAddressContract("OptimismPortalProxy", metalChainId), "Metal Portal should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1StandardBridgeProxy", metalChainId), "Metal Bridge should be a contract"
        );
        assertTrue(
            addresses.isAddressContract("L1CrossDomainMessengerProxy", metalChainId),
            "Metal Messenger should be a contract"
        );

        assertTrue(
            addresses.isAddressRegistered("OptimismPortalProxy", metalChainId), "Metal Portal should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1StandardBridgeProxy", metalChainId), "Metal Bridge should be registered"
        );
        assertTrue(
            addresses.isAddressRegistered("L1CrossDomainMessengerProxy", metalChainId),
            "Metal Messenger should be registered"
        );
    }

    function testInvalidL2ChainIdGetAddressFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.getAddress("DEPLOYER_EOA", 999);
    }

    function testGetNonExistentAddressFails() public {
        vm.expectRevert("Address not found");
        addresses.getAddress("NON_EXISTENT_ADDRESS", orderlyChainId);
    }

    function testInvalidL2ChainIdIsAddressContractFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.isAddressContract("DEPLOYER_EOA", 999);
    }

    function testGetIsAddressContractNonExistentAddressFails() public {
        vm.expectRevert("Address not found for identifier NON_EXISTENT_ADDRESS on chain 291");
        addresses.isAddressContract("NON_EXISTENT_ADDRESS", orderlyChainId);
    }

    /// Construction failure tests

    function testInvalidChainIdInSuperchainsFails() public {
        string memory networkConfigFilePath = "test/registry/mock/invalidChainIdNetworkConfig.toml";

        vm.expectRevert("Invalid chain ID in config");
        new AddressRegistry(networkConfigFilePath);
    }
}
