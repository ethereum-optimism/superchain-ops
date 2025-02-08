// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";

contract MainnetAddressRegistryTest is Test {
    AddressRegistry private addresses;

    uint256 public metalChainId;
    uint256 public baseChainId;
    uint256 public opMainnetChainId;
    uint256 public zoraChainId;
    uint256 public modeChainId;

    function setUp() public {
        string memory networkConfigFilePath = "test/tasks/mock/DiscoverChainAddressesConfig.toml";

        vm.createSelectFork("mainnet");

        addresses = new AddressRegistry(networkConfigFilePath);
        metalChainId = getChain("metal").chainId;
        baseChainId = getChain("base").chainId;
        opMainnetChainId = getChain("optimism").chainId;
        zoraChainId = getChain("zora").chainId;
        modeChainId = getChain("mode").chainId;
    }

    function testContractState() public view {
        assertTrue(addresses.supportedL2ChainIds(metalChainId), "Metal chain ID not supported");
        assertTrue(addresses.supportedL2ChainIds(baseChainId), "Base chain ID not supported");
        assertTrue(addresses.supportedL2ChainIds(opMainnetChainId), "OP Mainnet chain ID not supported");
        assertTrue(addresses.supportedL2ChainIds(zoraChainId), "Zora chain ID not supported");
    }

    function testSuperchainAddressesLoaded() public view {
        AddressRegistry.ChainInfo[] memory chains = addresses.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
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
                bool hasFaultGame = addresses.getAddress("FaultDisputeGame", chainId) != address(0);
                bool hasPermissionedGame = addresses.getAddress("PermissionedDisputeGame", chainId) != address(0);
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
                assertNotEq(
                    addresses.getAddress("DelayedWETHProxy", chainId), address(0), "DelayedWETHProxy not loaded"
                );
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
        }
    }

    function testInvalidL2ChainIdGetAddressFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.getAddress("DEPLOYER_EOA", 999);
    }

    function testGetNonExistentAddressFails() public {
        vm.expectRevert("Address not found");
        addresses.getAddress("NON_EXISTENT_ADDRESS", opMainnetChainId);
    }

    function testInvalidL2ChainIdIsAddressContractFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addresses.isAddressContract("DEPLOYER_EOA", 999);
    }

    function testGetIsAddressContractNonExistentAddressFails() public {
        vm.expectRevert("Address not found for identifier NON_EXISTENT_ADDRESS on chain 34443");
        addresses.isAddressContract("NON_EXISTENT_ADDRESS", modeChainId);
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
