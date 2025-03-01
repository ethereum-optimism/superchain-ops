// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

abstract contract AddressRegistryTest_Base is Test {
    using LibString for string;

    SuperchainAddressRegistry private addrRegistry;

    uint256 public metalChainId;
    uint256 public baseChainId;
    uint256 public opChainId;
    uint256 public zoraChainId;
    uint256 public modeChainId;

    function setUp() public {
        (string memory configPath, string memory chainName) = config();

        vm.createSelectFork(chainName);

        addrRegistry = new SuperchainAddressRegistry(configPath);
        metalChainId = getChain(string.concat("metal", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
        baseChainId = getChain(string.concat("base", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
        opChainId = getChain(string.concat("optimism", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
        zoraChainId = getChain(string.concat("zora", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
        modeChainId = getChain(string.concat("mode", chainName.eq("sepolia") ? "_sepolia" : "")).chainId;
    }

    function config() internal pure virtual returns (string memory configFilePath_, string memory chainName_);

    function testContractState() public view {
        assertTrue(addrRegistry.supportedL2ChainIds(metalChainId), "Metal chain ID not supported");
        assertTrue(addrRegistry.supportedL2ChainIds(baseChainId), "Base chain ID not supported");
        assertTrue(addrRegistry.supportedL2ChainIds(opChainId), "OP chain ID not supported");
        assertTrue(addrRegistry.supportedL2ChainIds(zoraChainId), "Zora chain ID not supported");
        assertTrue(addrRegistry.supportedL2ChainIds(modeChainId), "Mode chain ID not supported");
    }

    function testSuperchainAddressesLoaded() public view {
        SuperchainAddressRegistry.ChainInfo[] memory chains = addrRegistry.getChains();
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

            // Define expected superchain auth addresses for mainnet and testnet.
            address fus = block.chainid == 1
                ? 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
                : 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B;
            address fos = block.chainid == 1
                ? 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
                : 0x837DE453AD5F21E89771e3c06239d8236c0EFd5E;
            address sc = block.chainid == 1
                ? 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
                : 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977;

            assertEq(addrRegistry.getAddress("FoundationUpgradeSafe", chainId), fus, "350");
            assertEq(addrRegistry.getAddress("FoundationOperationSafe", chainId), fos, "360");
            assertEq(addrRegistry.getAddress("SecurityCouncil", chainId), sc, "370");
            // Sepolia does not define a ChainGovernorSafe in addresses.toml, so we skip in that case.
            if (block.chainid != 11155111) {
                assertEq(
                    addrRegistry.getAddress("ChainGovernorSafe", chainId),
                    0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC,
                    "380"
                );
            }
        }
    }

    function testInvalidL2ChainIdGetAddressFails() public {
        vm.expectRevert("L2 Chain ID 999 not supported");
        addrRegistry.getAddress("DEPLOYER_EOA", 999);
    }

    function testGetNonExistentAddressFails() public {
        vm.expectRevert("Address not found");
        addrRegistry.getAddress("NON_EXISTENT_ADDRESS", opChainId);
    }

    function testGetNonExistentAddressInfoFails() public {
        vm.expectRevert("Address Info not found");
        addrRegistry.getAddressInfo(address(0x1234567890123456789012345678901234567890));
    }

    /// Construction failure tests
    function testInvalidChainIdInSuperchainsFails() public {
        string memory networkConfigFilePath = "test/registry/mock/invalidChainIdNetworkConfig.toml";

        vm.expectRevert("Invalid chain ID in config");
        new SuperchainAddressRegistry(networkConfigFilePath);
    }

    /// Helper function to get optional addresses without reverting.
    function getOptionalAddress(string memory identifier, uint256 chainId) internal view returns (address) {
        require(gasleft() > 500_000, "insufficient gas for getAddress() call"); // Ensure try/catch is EIP-150 safe.
        try addrRegistry.getAddress(identifier, chainId) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
}

contract AddressRegistryTest_Mainnet is AddressRegistryTest_Base {
    function config() internal pure override returns (string memory configFilePath_, string memory chainName_) {
        configFilePath_ = "test/tasks/mock/configs/DiscoverChainAddressesConfig.toml";
        chainName_ = "mainnet";
    }
}

contract AddressRegistryTest_Sepolia is AddressRegistryTest_Base {
    function config() internal pure override returns (string memory configFilePath_, string memory chainName_) {
        configFilePath_ = "test/tasks/mock/configs/DiscoverChainAddressesTestnetConfig.toml";
        chainName_ = "sepolia";
    }
}
