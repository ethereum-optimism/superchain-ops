// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

import {SimpleAddressRegistryTest} from "./SimpleAddressRegistry.t.sol";

abstract contract SuperchainAddressRegistryTest_Base is Test {
    using LibString for string;

    SuperchainAddressRegistry private addrRegistry;

    uint256 public metalChainId;
    uint256 public baseChainId;
    uint256 public opChainId;
    uint256 public zoraChainId;
    uint256 public modeChainId;
    uint256 public unichainChainId;

    function setUp() public {
        (string memory configPath, string memory chainName) = config();

        vm.createSelectFork(chainName);

        addrRegistry = new SuperchainAddressRegistry(configPath);
        metalChainId = getChain(string.concat("metal", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
        baseChainId = getChain(string.concat("base", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
        opChainId = getChain(string.concat("optimism", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
        zoraChainId = getChain(string.concat("zora", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
        modeChainId = getChain(string.concat("mode", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
        unichainChainId = chainName.eq("sepolia") ? 1301 : 130; // TODO: add to Unichain to Foundry.
    }

    function config() internal pure virtual returns (string memory configFilePath_, string memory chainName_);

    function testContractState() public view {
        assertTrue(addrRegistry.seenL2ChainIds(metalChainId), "Metal chain ID not supported");
        assertTrue(addrRegistry.seenL2ChainIds(baseChainId), "Base chain ID not supported");
        assertTrue(addrRegistry.seenL2ChainIds(opChainId), "OP chain ID not supported");
        assertTrue(addrRegistry.seenL2ChainIds(zoraChainId), "Zora chain ID not supported");
        assertTrue(addrRegistry.seenL2ChainIds(modeChainId), "Mode chain ID not supported");
    }

    function testSuperchainAddressesLoaded() public {
        SuperchainAddressRegistry.ChainInfo[] memory chains = addrRegistry.getChains();
        assertAddresses(chains);
        assertEq(chains.length, 6, "Expected 6 chains");

        // Now discover a new chain that isn't in the config. Make sure not addresses are overridden.
        addrRegistry.discoverNewChain(SuperchainAddressRegistry.ChainInfo({chainId: unichainChainId, name: "Unichain"}));
        chains = addrRegistry.getChains();
        // Unichain should be the 7th chain added after discovery.
        assertEq(chains.length, 7, "Expected 7 chains");
        assertAddresses(chains);
    }

    function testInvalidL2ChainIdGetAddressFails() public {
        string memory err = string.concat("SuperchainAddressRegistry: address not found for DEPLOYER_EOA on chain 999");
        vm.expectRevert(bytes(err));
        addrRegistry.getAddress("DEPLOYER_EOA", 999);
    }

    function testGetNonExistentAddressFails() public {
        string memory err = string.concat(
            "SuperchainAddressRegistry: address not found for NON_EXISTENT_ADDRESS on chain ", vm.toString(opChainId)
        );
        vm.expectRevert(bytes(err));
        addrRegistry.getAddress("NON_EXISTENT_ADDRESS", opChainId);
    }

    function testGetNonExistentAddressInfoFails() public {
        string memory err = string.concat(
            "SuperchainAddressRegistry: AddressInfo not found for 0x1234567890123456789012345678901234567890"
        );
        vm.expectRevert(bytes(err));
        addrRegistry.getAddressInfo(address(0x1234567890123456789012345678901234567890));
    }

    function testInvalidChainIdInSuperchainsFailsInConstruction() public {
        string memory networkConfigFilePath = "test/registry/mock/invalidChainIdNetworkConfig.toml";

        vm.expectRevert("SuperchainAddressRegistry: Invalid chain ID in config");
        new SuperchainAddressRegistry(networkConfigFilePath);
    }

    function assertAddresses(SuperchainAddressRegistry.ChainInfo[] memory chains) internal view {
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            string memory chainName = chains[i].name;
            assertNotEq(addrRegistry.getAddress("L1StandardBridgeProxy", chainId), address(0), "10");
            assertNotEq(addrRegistry.getAddress("L1CrossDomainMessengerProxy", chainId), address(0), "20");
            assertNotEq(addrRegistry.getAddress("AddressManager", chainId), address(0), "30");
            assertNotEq(addrRegistry.getAddress("OptimismPortalProxy", chainId), address(0), "40");

            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("L1StandardBridgeProxy", chainId)).identifier,
                "L1StandardBridgeProxy",
                "50"
            );
            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("L1StandardBridgeProxy", chainId)).chainInfo.chainId,
                chainId,
                "60"
            );
            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("L1StandardBridgeProxy", chainId)).chainInfo.name,
                chainName,
                "70"
            );

            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("L1CrossDomainMessengerProxy", chainId)).identifier,
                "L1CrossDomainMessengerProxy",
                "80"
            );
            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("L1CrossDomainMessengerProxy", chainId))
                    .chainInfo
                    .chainId,
                chainId,
                "90"
            );
            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("L1CrossDomainMessengerProxy", chainId))
                    .chainInfo
                    .name,
                chainName,
                "100"
            );

            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("AddressManager", chainId)).identifier,
                "AddressManager",
                "110"
            );
            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("AddressManager", chainId)).chainInfo.chainId,
                chainId,
                "120"
            );
            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("AddressManager", chainId)).chainInfo.name,
                chainName,
                "130"
            );

            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("OptimismPortalProxy", chainId)).identifier,
                "OptimismPortalProxy",
                "140"
            );
            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("OptimismPortalProxy", chainId)).chainInfo.chainId,
                chainId,
                "150"
            );
            assertEq(
                addrRegistry.getAddressInfo(addrRegistry.getAddress("OptimismPortalProxy", chainId)).chainInfo.name,
                chainName,
                "160"
            );

            // Note: Some older chains (pre-MCP-L1) do not have a SuperchainConfig.
            address superchainConfig = getOptionalAddress("SuperchainConfig", chainId);
            if (superchainConfig != address(0)) {
                assertNotEq(superchainConfig, address(0), "170");
            }

            assertNotEq(addrRegistry.getAddress("SystemConfigProxy", chainId), address(0), "180");

            // Note: This is not discoverable on older chains. In these cases, it's read from the superchain registry.
            assertNotEq(addrRegistry.getAddress("L1ERC721BridgeProxy", chainId), address(0), "190");

            // Note: This is not discoverable on older chains. In these cases, it's read from the superchain registry.
            assertNotEq(addrRegistry.getAddress("OptimismMintableERC20FactoryProxy", chainId), address(0), "200");

            // Note: Some older chains do not have a dispute game factory.
            // TODO: Remove when we have a dispute game factory on all chains.
            address disputeGameFactoryProxy = getOptionalAddress("DisputeGameFactoryProxy", chainId);
            if (disputeGameFactoryProxy != address(0)) {
                assertNotEq(disputeGameFactoryProxy, address(0), "210");
                bool hasFaultGame = getOptionalAddress("FaultDisputeGame", chainId) != address(0);
                bool hasPermissionedGame = getOptionalAddress("PermissionedDisputeGame", chainId) != address(0);
                assertTrue(hasFaultGame || hasPermissionedGame, "220");
                if (hasPermissionedGame) {
                    assertNotEq(addrRegistry.getAddress("Challenger", chainId), address(0), "230");
                }
                assertNotEq(addrRegistry.getAddress("AnchorStateRegistryProxy", chainId), address(0), "240");
                assertNotEq(addrRegistry.getAddress("MIPS", chainId), address(0), "250");
                assertNotEq(addrRegistry.getAddress("PreimageOracle", chainId), address(0), "260");
            } else {
                assertNotEq(addrRegistry.getAddress("L2OutputOracleProxy", chainId), address(0), "270");
            }

            assertNotEq(addrRegistry.getAddress("Guardian", chainId), address(0), "280");
            assertNotEq(addrRegistry.getAddress("Proposer", chainId), address(0), "290");
            assertNotEq(addrRegistry.getAddress("BatchSubmitter", chainId), address(0), "300");
            assertNotEq(addrRegistry.getAddress("ProxyAdmin", chainId), address(0), "310");
            assertNotEq(addrRegistry.getAddress("ProxyAdminOwner", chainId), address(0), "320");
            assertNotEq(addrRegistry.getAddress("SystemConfigOwner", chainId), address(0), "330");
            assertNotEq(addrRegistry.getAddress("UnsafeBlockSigner", chainId), address(0), "340");
        }
    }

    // Helper function to get optional addresses without reverting.
    function getOptionalAddress(string memory identifier, uint256 chainId) internal view returns (address) {
        require(gasleft() > 500_000, "insufficient gas for getAddress() call"); // Ensure try/catch is EIP-150 safe.
        try addrRegistry.getAddress(identifier, chainId) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
}

contract SuperchainAddressRegistryTest_Mainnet is SuperchainAddressRegistryTest_Base {
    function config() internal pure override returns (string memory configFilePath_, string memory chainName_) {
        configFilePath_ = "test/tasks/mock/configs/DiscoverChainAddressesConfig.toml";
        chainName_ = "mainnet";
    }
}

contract SuperchainAddressRegistryTest_Sepolia is SuperchainAddressRegistryTest_Base {
    function config() internal pure override returns (string memory configFilePath_, string memory chainName_) {
        configFilePath_ = "test/tasks/mock/configs/DiscoverChainAddressesTestnetConfig.toml";
        chainName_ = "sepolia";
    }
}

// We test the addresses key-value store by extending the SimpleAddressRegistryTest.
contract SuperchainAddressRegistryTest_Addresses is SimpleAddressRegistryTest {
    function setUp() public override {
        vm.createSelectFork("mainnet");
        registryName = "SuperchainAddressRegistry";
        idReturnKind = "AddressInfo";
    }

    function _deployRegistry(string memory configFile) internal override returns (address) {
        return address(new SuperchainAddressRegistry(_getPath(configFile)));
    }
}
