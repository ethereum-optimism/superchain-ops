// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";

contract TestnetAddressRegistryTest is Test {
    AddressRegistry private addresses;

    uint256 public opSepoliaChainId;
    uint256 public metalSepoliaChainId;

    function setUp() public {
        string memory networkConfigFilePath = "test/tasks/mock/configs/DiscoverChainAddressesTestnetConfig.toml";

        vm.createSelectFork("sepolia");

        addresses = new AddressRegistry(networkConfigFilePath);
        opSepoliaChainId = getChain("optimism_sepolia").chainId;
        metalSepoliaChainId = getChain("metal_sepolia").chainId;
    }

    function testContractState() public view {
        assertTrue(addresses.supportedL2ChainIds(opSepoliaChainId), "Op Sepolia chain ID not supported");
    }

    function testSuperchainAddressesLoaded() public view {
        AddressRegistry.ChainInfo[] memory chains = addresses.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            string memory chainName = chains[i].name;
            assertNotEq(
                addresses.getAddress("L1StandardBridgeProxy", chainId), address(0), "L1StandardBridgeProxy not loaded"
            );
            assertNotEq(
                addresses.getAddress("L1CrossDomainMessengerProxy", chainId),
                address(0),
                "L1CrossDomainMessengerProxy not loaded"
            );
            assertNotEq(addresses.getAddress("AddressManager", chainId), address(0), "AddressManager not loaded");
            assertNotEq(
                addresses.getAddress("OptimismPortalProxy", chainId), address(0), "OptimismPortalProxy not loaded"
            );

            assertEq(
                addresses.getAddressInfo(addresses.getAddress("L1StandardBridgeProxy", chainId)).identifier,
                "L1StandardBridgeProxy",
                "L1StandardBridgeProxy identifier not loaded"
            );
            assertEq(
                addresses.getAddressInfo(addresses.getAddress("L1StandardBridgeProxy", chainId)).chainInfo.chainId,
                chainId,
                "L1StandardBridgeProxy chain id not loaded"
            );
            assertEq(
                addresses.getAddressInfo(addresses.getAddress("L1StandardBridgeProxy", chainId)).chainInfo.name,
                chainName,
                "L1StandardBridgeProxy chain name not loaded"
            );

            assertEq(
                addresses.getAddressInfo(addresses.getAddress("L1CrossDomainMessengerProxy", chainId)).identifier,
                "L1CrossDomainMessengerProxy",
                "L1CrossDomainMessengerProxy identifier not loaded"
            );
            assertEq(
                addresses.getAddressInfo(addresses.getAddress("L1CrossDomainMessengerProxy", chainId)).chainInfo.chainId,
                chainId,
                "L1CrossDomainMessengerProxy chain id not loaded"
            );
            assertEq(
                addresses.getAddressInfo(addresses.getAddress("L1CrossDomainMessengerProxy", chainId)).chainInfo.name,
                chainName,
                "L1CrossDomainMessengerProxy chain name not loaded"
            );

            assertEq(
                addresses.getAddressInfo(addresses.getAddress("AddressManager", chainId)).identifier,
                "AddressManager",
                "AddressManager identifier not loaded"
            );
            assertEq(
                addresses.getAddressInfo(addresses.getAddress("AddressManager", chainId)).chainInfo.chainId,
                chainId,
                "AddressManager chain id not loaded"
            );
            assertEq(
                addresses.getAddressInfo(addresses.getAddress("AddressManager", chainId)).chainInfo.name,
                chainName,
                "AddressManager chain name not loaded"
            );

            assertEq(
                addresses.getAddressInfo(addresses.getAddress("OptimismPortalProxy", chainId)).identifier,
                "OptimismPortalProxy",
                "OptimismPortalProxy identifier not loaded"
            );
            assertEq(
                addresses.getAddressInfo(addresses.getAddress("OptimismPortalProxy", chainId)).chainInfo.chainId,
                chainId,
                "OptimismPortalProxy chain id not loaded"
            );
            assertEq(
                addresses.getAddressInfo(addresses.getAddress("OptimismPortalProxy", chainId)).chainInfo.name,
                chainName,
                "OptimismPortalProxy chain name not loaded"
            );

            // Note: Some older chains (pre-MCP-L1) do not have a SuperchainConfig.
            address superchainConfig = getOptionalAddress("SuperchainConfig", chainId);
            if (superchainConfig != address(0)) {
                assertNotEq(superchainConfig, address(0), "SuperchainConfig not loaded");
            }

            assertNotEq(addresses.getAddress("SystemConfigProxy", chainId), address(0), "SystemConfigProxy not loaded");

            // Note: This is not discoverable on older chains. In these cases, it's read from the superchain registry.
            assertNotEq(
                addresses.getAddress("L1ERC721BridgeProxy", chainId), address(0), "L1ERC721BridgeProxy not loaded"
            );

            // Note: This is not discoverable on older chains. In these cases, it's read from the superchain registry.
            assertNotEq(
                addresses.getAddress("OptimismMintableERC20FactoryProxy", chainId),
                address(0),
                "OptimismMintableERC20FactoryProxy not loaded"
            );

            // Note: Some older chains do not have a dispute game factory.
            // TODO: Remove when we have a dispute game factory on all chains.
            address disputeGameFactoryProxy = getOptionalAddress("DisputeGameFactoryProxy", chainId);
            if (disputeGameFactoryProxy != address(0)) {
                assertNotEq(disputeGameFactoryProxy, address(0), "DisputeGameFactoryProxy not loaded");
                bool hasFaultGame = getOptionalAddress("FaultDisputeGame", chainId) != address(0);
                bool hasPermissionedGame = getOptionalAddress("PermissionedDisputeGame", chainId) != address(0);
                assertTrue(
                    hasFaultGame || hasPermissionedGame, "Neither FaultDisputeGame nor PermissionedDisputeGame loaded"
                );
                if (hasPermissionedGame) {
                    assertNotEq(addresses.getAddress("Challenger", chainId), address(0), "Challenger not loaded");
                }
                assertNotEq(
                    addresses.getAddress("AnchorStateRegistryProxy", chainId),
                    address(0),
                    "AnchorStateRegistryProxy not loaded"
                );
                assertNotEq(addresses.getAddress("MIPS", chainId), address(0), "MIPS not loaded");
                assertNotEq(addresses.getAddress("PreimageOracle", chainId), address(0), "PreimageOracle not loaded");
            } else {
                assertNotEq(
                    addresses.getAddress("L2OutputOracleProxy", chainId), address(0), "L2OutputOracleProxy not loaded"
                );
            }

            assertNotEq(addresses.getAddress("Guardian", chainId), address(0), "Guardian not loaded");
            assertNotEq(addresses.getAddress("Proposer", chainId), address(0), "Proposer not loaded");
            assertNotEq(addresses.getAddress("BatchSubmitter", chainId), address(0), "BatchSubmitter not loaded");
            assertNotEq(addresses.getAddress("ProxyAdmin", chainId), address(0), "ProxyAdmin not loaded");
            assertNotEq(addresses.getAddress("ProxyAdminOwner", chainId), address(0), "ProxyAdminOwner not loaded");
            assertNotEq(addresses.getAddress("SystemConfigOwner", chainId), address(0), "SystemConfigOwner not loaded");
            assertNotEq(addresses.getAddress("UnsafeBlockSigner", chainId), address(0), "UnsafeBlockSigner not loaded");
            assertNotEq(
                addresses.getAddress("FoundationUpgradeSafe", chainId), address(0), "FoundationUpgradeSafe not loaded"
            );
            assertNotEq(
                addresses.getAddress("FoundationOperationSafe", chainId),
                address(0),
                "FoundationOperationSafe not loaded"
            );
            assertNotEq(addresses.getAddress("SecurityCouncil", chainId), address(0), "SecurityCouncil not loaded");

            assertEq(
                addresses.getAddress("FoundationUpgradeSafe", chainId),
                0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B,
                "FoundationUpgradeSafe not properly loaded"
            );
            assertEq(
                addresses.getAddress("FoundationOperationSafe", chainId),
                0x837DE453AD5F21E89771e3c06239d8236c0EFd5E,
                "FoundationOperationSafe not properly loaded"
            );
            assertEq(
                addresses.getAddress("SecurityCouncil", chainId),
                0xf64bc17485f0B4Ea5F06A96514182FC4cB561977,
                "SecurityCouncil not properly loaded"
            );
        }
    }

    function testInvalidL2ChainIdGetAddressFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.getAddress("DEPLOYER_EOA", 999);
    }

    function testGetNonExistentAddressFails() public {
        vm.expectRevert("Address not found");
        addresses.getAddress("NON_EXISTENT_ADDRESS", opSepoliaChainId);
    }

    function testGetNonExistentAddressInfoFails() public {
        vm.expectRevert("Address Info not found");
        addresses.getAddressInfo(address(0x1234567890123456789012345678901234567890));
    }

    function testInvalidL2ChainIdIsAddressContractFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.isAddressContract("DEPLOYER_EOA", 999);
    }

    function testGetIsAddressContractNonExistentAddressFails() public {
        vm.expectRevert("Address not found for identifier NON_EXISTENT_ADDRESS on chain 11155420");
        addresses.isAddressContract("NON_EXISTENT_ADDRESS", opSepoliaChainId);
    }

    /// Construction failure tests
    function testInvalidChainIdInSuperchainsFails() public {
        string memory networkConfigFilePath = "test/registry/mock/invalidChainIdNetworkConfig.toml";

        vm.expectRevert("Invalid chain ID in config");
        new AddressRegistry(networkConfigFilePath);
    }

    /// Helper function to get optional addresses without reverting.
    function getOptionalAddress(string memory identifier, uint256 chainId) internal view returns (address) {
        try addresses.getAddress(identifier, chainId) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
}
