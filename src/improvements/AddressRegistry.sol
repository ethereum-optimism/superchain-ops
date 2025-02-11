// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {Test} from "forge-std/Test.sol";
import {IAddressRegistry} from "src/improvements/IAddressRegistry.sol";
import {GameTypes, GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

/// @notice Contains getters for arbitrary methods from all L1 contracts, including legacy getters
/// that have since been deprecated.
interface IFetcher {
    function guardian() external view returns (address);
    function GUARDIAN() external view returns (address);
    function systemConfig() external view returns (address);
    function SYSTEM_CONFIG() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function superchainConfig() external view returns (address);
    function messenger() external view returns (address);
    function addressManager() external view returns (address);
    function PORTAL() external view returns (address);
    function portal() external view returns (address);
    function l1ERC721BridgeProxy() external view returns (address);
    function optimismMintableERC20Factory() external view returns (address);
    function gameImpls(GameType _gameType) external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function L2_ORACLE() external view returns (address);
    function vm() external view returns (address);
    function oracle() external view returns (address);
    function challenger() external view returns (address);
    function proposer() external view returns (address);
    function PROPOSER() external view returns (address);
    function batcherHash() external view returns (bytes32);
    function admin() external view returns (address);
    function owner() external view returns (address);
    function unsafeBlockSigner() external view returns (address);
    function weth() external view returns (address);
}

/// @title Network Address Manager
/// @notice This contract provides a single source of truth for storing and retrieving addresses across multiple networks.
/// @dev Handles addresses for contracts and externally owned accounts (EOAs) while ensuring correctness and uniqueness.
contract AddressRegistry is IAddressRegistry, Test {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev Structure for reading address details from JSON files.
    struct InputAddress {
        /// Blockchain network identifier
        address addr;
        /// contract identifier (name)
        string identifier;
        /// Address (contract or EOA)
        /// Indicates if the address is a contract
        bool isContract;
    }

    /// @dev Structure for storing address details in the contract.
    struct RegistryEntry {
        address addr;
        /// Address (contract or EOA)
        /// Indicates if the address is a contract
        bool isContract;
    }

    /// @dev Structure for reading chain list details from toml file
    struct ChainInfo {
        uint256 chainId;
        string name;
    }

    /// @notice Maps an identifier and l2 instance chain ID to a stored address entry.
    /// All addresses will live on the same chain.
    mapping(string => mapping(uint256 => RegistryEntry)) private registry;

    /// @notice Supported L2 chain IDs for this Address Registry instance.
    mapping(uint256 => bool) public supportedL2ChainIds;

    /// @notice Array of supported chains and their configurations
    ChainInfo[] public chains;

    /// @notice Initializes the contract by loading addresses from TOML files
    /// and configuring the supported L2 chains.
    /// @param networkConfigFilePath the path to the TOML file containing the network configuration(s)
    constructor(string memory networkConfigFilePath) {
        require(
            block.chainid == getChain("mainnet").chainId || block.chainid == getChain("sepolia").chainId,
            "Unsupported network"
        );

        bytes memory chainListContent;
        try vm.parseToml(vm.readFile(networkConfigFilePath), ".l2chains") returns (bytes memory parsedChainListContent)
        {
            chainListContent = parsedChainListContent;
        } catch {
            revert(string.concat("Failed to parse network config file path: ", networkConfigFilePath));
        }

        // Cannot assign the abi.decode result to `chains` directly because it's a storage array, so
        // compiling without via-ir will fail with:
        //    Unimplemented feature (/solidity/libsolidity/codegen/ArrayUtils.cpp:228):Copying of type struct AddressRegistry.ChainInfo memory[] memory to storage not yet supported.
        ChainInfo[] memory _chains = abi.decode(chainListContent, (ChainInfo[]));
        for (uint256 i = 0; i < _chains.length; i++) {
            chains.push(_chains[i]);
        }

        string memory chainAddressesContent =
            vm.readFile("lib/superchain-registry/superchain/extra/addresses/addresses.json");

        for (uint256 i = 0; i < chains.length; i++) {
            require(!supportedL2ChainIds[chains[i].chainId], "Duplicate chain ID in chain config");
            require(chains[i].chainId != 0, "Invalid chain ID in config");
            require(bytes(chains[i].name).length > 0, "Empty name in config");

            supportedL2ChainIds[chains[i].chainId] = true;

            if (block.chainid == getChain("mainnet").chainId) {
                _processMainnet(chains[i], chainAddressesContent);
            } else {
                _processTestnet(chains[i], chainAddressesContent);
            }
        }
    }

    /// @dev Processes all configuration for a mainnet chain.
    function _processMainnet(ChainInfo memory chain, string memory chainAddressesContent) internal {
        uint256 chainId = chain.chainId; // L2 chain ID.

        address optimismPortalProxy = _fetchAndSaveInitialContracts(chain, chainAddressesContent);

        address superchainConfig = getSuperchainConfig(optimismPortalProxy);
        saveAddress("SuperchainConfig", chain, superchainConfig);

        address systemConfigProxy = getSystemConfigProxy(optimismPortalProxy);
        saveAddress("SystemConfigProxy", chain, systemConfigProxy);

        _saveProxyAdminEntries(chain, systemConfigProxy);

        address l1ERC721BridgeProxy = getL1ERC721BridgeProxy(systemConfigProxy, chainAddressesContent, chainId);
        saveAddress("L1ERC721BridgeProxy", chain, l1ERC721BridgeProxy);

        address optimismMintableERC20FactoryProxy =
            getOptimismMintableERC20FactoryProxy(systemConfigProxy, chainAddressesContent, chainId);
        saveAddress("OptimismMintableERC20FactoryProxy", chain, optimismMintableERC20FactoryProxy);

        // Some older chains don't have a DisputeGameFactory.
        address disputeGameFactoryProxy = getDisputeGameFactoryProxy(systemConfigProxy);
        if (disputeGameFactoryProxy != address(0)) {
            _saveDisputeGameEntries(chain, disputeGameFactoryProxy);
        } else {
            // Older chains have an L2OutputOracleProxy.
            address l2OutputOracleProxy = IFetcher(optimismPortalProxy).L2_ORACLE();
            saveAddress("L2OutputOracleProxy", chain, l2OutputOracleProxy);
            address proposer = IFetcher(l2OutputOracleProxy).PROPOSER();
            saveAddress("Proposer", chain, proposer);
        }

        address guardian = getGuardian(optimismPortalProxy);
        saveAddress("Guardian", chain, guardian);

        address batchSubmitter = getBatchSubmitter(systemConfigProxy);
        saveAddress("BatchSubmitter", chain, batchSubmitter);

        address systemConfigOwner = IFetcher(systemConfigProxy).owner();
        saveAddress("SystemConfigOwner", chain, systemConfigOwner);

        address unsafeBlockSigner = IFetcher(systemConfigProxy).unsafeBlockSigner();
        saveAddress("UnsafeBlockSigner", chain, unsafeBlockSigner);
    }

    /// @notice load addresses for a testnet chain.
    /// this function reads all values from the superchain-registry
    /// addresses.json and does no onchain discovery.
    function _processTestnet(ChainInfo memory chain, string memory chainAddressesContent) internal {
        string[] memory keys = vm.parseJsonKeys(chainAddressesContent, string.concat("$.", vm.toString(chain.chainId)));
        for (uint256 j = 0; j < keys.length; j++) {
            string memory key = keys[j];
            address addr =
                vm.parseJsonAddress(chainAddressesContent, string.concat("$.", vm.toString(chain.chainId), ".", key));

            saveAddress(key, chain, addr);
        }
    }

    function _fetchAndSaveInitialContracts(ChainInfo memory chain, string memory chainAddressesContent)
        internal
        returns (address optimismPortalProxy)
    {
        address l1StandardBridgeProxy =
            parseContractAddress(chainAddressesContent, chain.chainId, "L1StandardBridgeProxy");
        saveAddress("L1StandardBridgeProxy", chain, l1StandardBridgeProxy);

        address l1CrossDomainMessengerProxy = IFetcher(l1StandardBridgeProxy).messenger();
        saveAddress("L1CrossDomainMessengerProxy", chain, l1CrossDomainMessengerProxy);

        address addressManager = getAddressManager(l1CrossDomainMessengerProxy);
        saveAddress("AddressManager", chain, addressManager);

        optimismPortalProxy = getOptimismPortalProxy(l1CrossDomainMessengerProxy);
        saveAddress("OptimismPortalProxy", chain, optimismPortalProxy);
    }

    function _saveProxyAdminEntries(ChainInfo memory chain, address systemConfigProxy) internal {
        address proxyAdmin = getProxyAdmin(systemConfigProxy);
        saveAddress("ProxyAdmin", chain, proxyAdmin);
        address proxyAdminOwner = IFetcher(proxyAdmin).owner();
        saveAddress("ProxyAdminOwner", chain, proxyAdminOwner);
    }

    function saveAddress(string memory identifier, ChainInfo memory chain, address addr) internal {
        require(addr != address(0), "Address cannot be zero");
        require(registry[identifier][chain.chainId].addr == address(0), "Address already registered");

        registry[identifier][chain.chainId] = RegistryEntry(addr, addr.code.length > 0);

        // Format the chain name: uppercase it and replace spaces with underscores,
        // then concatenate with the identifier to form a readable label.
        string memory formattedChain = vm.replace(vm.toUppercase(chain.name), " ", "_");
        string memory label = string.concat(formattedChain, "_", identifier);
        vm.label(addr, label);
    }

    /// @notice Retrieves an address by its identifier for a specified L2 chain
    /// @param identifier The unique identifier associated with the address
    /// @param l2ChainId The chain ID of the L2 network
    /// @return The address associated with the given identifier on the specified chain
    function getAddress(string memory identifier, uint256 l2ChainId) public view returns (address) {
        _l2ChainIdSupported(l2ChainId);

        // Fetch the stored registry entry
        RegistryEntry memory entry = registry[identifier][l2ChainId];
        address resolvedAddress = entry.addr;

        require(resolvedAddress != address(0), "Address not found");

        return resolvedAddress;
    }

    /// @notice Checks if an address is a contract for a given identifier and L2 chain
    /// @param identifier The unique identifier associated with the address
    /// @param l2ChainId The chain ID of the L2 network
    /// @return True if the address is a contract, false otherwise
    function isAddressContract(string memory identifier, uint256 l2ChainId) public view returns (bool) {
        _l2ChainIdSupported(l2ChainId);
        _checkAddressRegistered(identifier, l2ChainId);

        return registry[identifier][l2ChainId].isContract;
    }

    /// @notice Checks if an address exists for a specified identifier and L2 chain
    /// @param identifier The unique identifier associated with the address
    /// @param l2ChainId The chain ID of the L2 network
    /// @return True if the address exists, false otherwise
    function isAddressRegistered(string memory identifier, uint256 l2ChainId) public view returns (bool) {
        return registry[identifier][l2ChainId].addr != address(0);
    }

    /// @notice Verifies that an address is registered for a given identifier and chain
    /// @dev Reverts if the address is not registered
    /// @param identifier The unique identifier associated with the address
    /// @param l2ChainId The chain ID of the L2 network
    function _checkAddressRegistered(string memory identifier, uint256 l2ChainId) private view {
        require(
            isAddressRegistered(identifier, l2ChainId),
            string(
                abi.encodePacked("Address not found for identifier ", identifier, " on chain ", vm.toString(l2ChainId))
            )
        );
    }

    /// @notice Returns the list of supported chains
    /// @return An array of ChainInfo structs representing the supported chains
    function getChains() public view returns (ChainInfo[] memory) {
        return chains;
    }

    /// @notice Verifies that the given L2 chain ID is supported
    /// @param l2ChainId The chain ID of the L2 network to verify
    function _l2ChainIdSupported(uint256 l2ChainId) private view {
        require(
            supportedL2ChainIds[l2ChainId],
            string(abi.encodePacked("L2 Chain ID ", vm.toString(l2ChainId), " not supported"))
        );
    }

    /// @notice Validates whether an address matches its expected type (contract or EOA)
    /// @dev Reverts if the address type does not match the expected type
    /// @param addr The address to validate
    /// @param isContract True if the address should be a contract, false if it should be an EOA
    function _typeCheckAddress(address addr, bool isContract) private view {
        if (isContract) {
            require(addr.code.length > 0, "Address must contain code");
        } else {
            require(addr.code.length == 0, "Address must not contain code");
        }
    }

    /// @dev Saves all dispute game related registry entries.
    function _saveDisputeGameEntries(ChainInfo memory chain, address disputeGameFactoryProxy) internal {
        saveAddress("DisputeGameFactoryProxy", chain, disputeGameFactoryProxy);

        address faultDisputeGame = getFaultDisputeGame(disputeGameFactoryProxy);
        if (faultDisputeGame != address(0)) {
            saveAddress("FaultDisputeGame", chain, faultDisputeGame);
        }

        address permissionedDisputeGame = getPermissionedDisputeGame(disputeGameFactoryProxy);
        saveAddress("PermissionedDisputeGame", chain, permissionedDisputeGame);

        address challenger = IFetcher(permissionedDisputeGame).challenger();
        saveAddress("Challenger", chain, challenger);

        address anchorStateRegistryProxy = getAnchorStateRegistryProxy(permissionedDisputeGame);
        saveAddress("AnchorStateRegistryProxy", chain, anchorStateRegistryProxy);

        // Not retreiving delayed WETH proxy because 'n' exist based on the number of GameTypes.
        // We will leave these addresses for the task developer to retrieve.

        address mips = getMips(permissionedDisputeGame);
        saveAddress("MIPS", chain, mips);

        address preimageOracle = IFetcher(mips).oracle();
        saveAddress("PreimageOracle", chain, preimageOracle);

        address proposer = IFetcher(permissionedDisputeGame).proposer();
        saveAddress("Proposer", chain, proposer);
    }

    function parseContractAddress(
        string memory chainAddressesContent,
        uint256 chainId,
        string memory contractIdentifier
    ) internal pure returns (address) {
        return vm.parseJsonAddress(
            chainAddressesContent, string.concat("$.", vm.toString(chainId), ".", contractIdentifier)
        );
    }

    function getGuardian(address portal) internal view returns (address) {
        try IFetcher(portal).guardian() returns (address guardian) {
            return guardian;
        } catch {
            return IFetcher(portal).GUARDIAN();
        }
    }

    function getSystemConfigProxy(address portal) internal view returns (address) {
        try IFetcher(portal).systemConfig() returns (address systemConfig) {
            return systemConfig;
        } catch {
            return IFetcher(portal).SYSTEM_CONFIG();
        }
    }

    function getOptimismPortalProxy(address l1CrossDomainMessengerProxy) internal view returns (address) {
        try IFetcher(l1CrossDomainMessengerProxy).PORTAL() returns (address optimismPortal) {
            return optimismPortal;
        } catch {
            return IFetcher(l1CrossDomainMessengerProxy).portal();
        }
    }

    function getAddressManager(address l1CrossDomainMessengerProxy) internal view returns (address addressManager) {
        uint256 ADDRESS_MANAGER_MAPPING_SLOT = 1;
        bytes32 slot = keccak256(abi.encode(l1CrossDomainMessengerProxy, ADDRESS_MANAGER_MAPPING_SLOT));
        addressManager = address(uint160(uint256((vm.load(l1CrossDomainMessengerProxy, slot)))));
    }

    function getL1ERC721BridgeProxy(address systemConfigProxy, string memory chainAddressesContent, uint256 chainId)
        internal
        view
        returns (address)
    {
        try IFetcher(systemConfigProxy).l1ERC721BridgeProxy() returns (address l1ERC721BridgeProxy) {
            return l1ERC721BridgeProxy;
        } catch {
            return parseContractAddress(chainAddressesContent, chainId, "L1ERC721BridgeProxy");
        }
    }

    function getOptimismMintableERC20FactoryProxy(
        address systemConfigProxy,
        string memory chainAddressesContent,
        uint256 chainId
    ) internal view returns (address) {
        try IFetcher(systemConfigProxy).optimismMintableERC20Factory() returns (
            address optimismMintableERC20FactoryProxy
        ) {
            return optimismMintableERC20FactoryProxy;
        } catch {
            return parseContractAddress(chainAddressesContent, chainId, "OptimismMintableERC20FactoryProxy");
        }
    }

    function getDisputeGameFactoryProxy(address systemConfigProxy) internal view returns (address) {
        try IFetcher(systemConfigProxy).disputeGameFactory() returns (address disputeGameFactoryProxy) {
            return disputeGameFactoryProxy;
        } catch {
            return address(0); // Older chains don't have a dispute game factory, they have the L2OutputOracle
        }
    }

    function getSuperchainConfig(address optimismPortalProxy) internal view returns (address) {
        try IFetcher(optimismPortalProxy).superchainConfig() returns (address superchainConfig) {
            return superchainConfig;
        } catch {
            return address(0);
        }
    }

    function getFaultDisputeGame(address disputeGameFactoryProxy) internal view returns (address) {
        try IFetcher(disputeGameFactoryProxy).gameImpls(GameTypes.CANNON) returns (address faultDisputeGame) {
            return faultDisputeGame;
        } catch {
            return address(0);
        }
    }

    function getPermissionedDisputeGame(address disputeGameFactoryProxy) internal view returns (address) {
        try IFetcher(disputeGameFactoryProxy).gameImpls(GameTypes.PERMISSIONED_CANNON) returns (
            address permissionedDisputeGame
        ) {
            return permissionedDisputeGame;
        } catch {
            return address(0);
        }
    }

    function getAnchorStateRegistryProxy(address permissionedDisputeGame) internal view returns (address) {
        return IFetcher(permissionedDisputeGame).anchorStateRegistry();
    }

    function getMips(address permissionedDisputeGame) internal view returns (address) {
        return IFetcher(permissionedDisputeGame).vm();
    }

    function getBatchSubmitter(address systemConfigProxy) internal view returns (address) {
        bytes32 batcherHash = IFetcher(systemConfigProxy).batcherHash();
        return address(uint160(uint256(batcherHash)));
    }

    function getProxyAdmin(address systemConfigProxy) internal returns (address) {
        vm.prank(address(0));
        return IFetcher(systemConfigProxy).admin();
    }
}
