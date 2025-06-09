// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {stdToml} from "forge-std/StdToml.sol";
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
    function l1ERC721Bridge() external view returns (address);
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

/// @notice This contract provides a single source of truth for storing and retrieving addresses
/// across multiple networks. It handles addresses for contracts and externally owned accounts
/// (EOAs) while ensuring correctness and uniqueness.
contract SuperchainAddressRegistry is StdChains {
    using stdToml for string;

    address private constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm private constant vm = Vm(VM_ADDRESS);

    /// @notice Structure for reading chain list details from toml file
    struct ChainInfo {
        uint256 chainId;
        string name;
    }

    /// @notice Structure for storing address info for a given address.
    struct AddressInfo {
        string identifier;
        ChainInfo chainInfo;
    }

    /// @notice Sentinel chain for generic task addresses.
    /// Chain ID is: 18359133240529938341515463404940784280234256774636175192927404318365594808696
    ChainInfo public sentinelChain =
        ChainInfo({chainId: uint256(keccak256("SuperchainAddressRegistry")), name: "SuperchainAddressRegistry"});

    /// @notice Maps a contract identifier to an L2 chain ID to an address.
    mapping(string => mapping(uint256 => address)) private registry;

    /// @notice During constructions, tracks if we've seen a chain ID to avoid duplicates and misuse.
    mapping(uint256 => bool) public seenL2ChainIds;

    /// @notice Maps an address to its identifier and chain info.
    mapping(address => AddressInfo) public addressInfo;

    /// @notice Array of supported chains and their configurations
    ChainInfo[] public chains;

    /// @notice The path to the addresses.json file in the superchain-registry repo.
    string public constant SUPERCHAIN_REGISTRY_ADDRESSES_PATH =
        "lib/superchain-registry/superchain/extra/addresses/addresses.json";

    /// @notice Initializes the contract by loading addresses from TOML files
    /// and configuring the supported L2 chains.
    /// @param configPath the path to the TOML file containing the network configuration(s)
    constructor(string memory configPath) {
        require(
            block.chainid == getChain("mainnet").chainId || block.chainid == getChain("sepolia").chainId,
            string.concat("SuperchainAddressRegistry: Unsupported task chain ID ", vm.toString(block.chainid))
        );

        string memory toml = vm.readFile(configPath);
        bytes memory chainListContent = toml.parseRaw(".l2chains");

        // Read in the list of OP chains from the config file.
        // Cannot assign the abi.decode result to `chains` directly because it's a storage array, so
        // compiling without via-ir will fail with:
        //    Unimplemented feature (/solidity/libsolidity/codegen/ArrayUtils.cpp:228):Copying of type struct AddressRegistry.ChainInfo memory[] memory to storage not yet supported.
        ChainInfo[] memory _chains = abi.decode(chainListContent, (ChainInfo[]));
        require(_chains.length > 0, "SuperchainAddressRegistry: no chains found");
        for (uint256 i = 0; i < _chains.length; i++) {
            require(_chains[i].chainId != 0, "SuperchainAddressRegistry: Invalid chain ID in config");
            require(bytes(_chains[i].name).length > 0, "SuperchainAddressRegistry: Empty name in config");
            require(!seenL2ChainIds[_chains[i].chainId], "SuperchainAddressRegistry: Duplicate chain ID");

            seenL2ChainIds[_chains[i].chainId] = true;
            chains.push(_chains[i]);
        }

        // For each OP chain, read in all addresses for that OP Chain.
        string memory chainAddrs = vm.readFile(SUPERCHAIN_REGISTRY_ADDRESSES_PATH);

        for (uint256 i = 0; i < chains.length; i++) {
            _processAddresses(chains[i], chainAddrs);
        }

        string memory chainKey;
        if (block.chainid == getChain("mainnet").chainId) chainKey = ".eth";
        else if (block.chainid == getChain("sepolia").chainId) chainKey = ".sep";
        else revert(string.concat("SuperchainAddressRegistry: Unknown task chain ID ", vm.toString(block.chainid)));

        _loadHardcodedAddresses(chainKey);

        // Lastly, we read in addresses from the `[addresses]` section of the config file.
        if (!toml.keyExists(".addresses")) return; // If the addresses section is missing, do nothing.

        string[] memory _identifiers = vm.parseTomlKeys(toml, ".addresses");
        for (uint256 i = 0; i < _identifiers.length; i++) {
            string memory key = _identifiers[i];
            address who = toml.readAddress(string.concat(".addresses.", key));
            saveAddress(key, sentinelChain, who);
        }
    }

    /// @notice Reads in hardcoded addresses from the addresses.toml file.
    function _loadHardcodedAddresses(string memory chainKey) internal {
        string memory toml = vm.readFile("./src/improvements/addresses.toml");
        string[] memory keys = vm.parseTomlKeys(toml, chainKey);
        require(keys.length > 0, string.concat("SuperchainAddressRegistry: no keys found for ", chainKey));

        for (uint256 i = 0; i < keys.length; i++) {
            string memory identifier = keys[i];
            address addr = toml.readAddress(string.concat(chainKey, ".", identifier));

            require(addr != address(0), string.concat("SuperchainAddressRegistry: zero address for ", identifier));
            require(
                registry[identifier][sentinelChain.chainId] == address(0),
                string.concat("SuperchainAddressRegistry: address already registered for ", identifier)
            );

            saveAddress(identifier, sentinelChain, addr);
        }
    }

    function saveAddress(string memory identifier, ChainInfo memory chain, address addr) internal {
        require(addr != address(0), string.concat("SuperchainAddressRegistry: zero address for ", identifier));
        require(bytes(identifier).length > 0, "SuperchainAddressRegistry: empty key");
        require(
            registry[identifier][chain.chainId] == address(0),
            string.concat(
                "SuperchainAddressRegistry: duplicate key ", identifier, " for chain ", vm.toString(chain.chainId)
            )
        );

        registry[identifier][chain.chainId] = addr;
        addressInfo[addr] = AddressInfo(identifier, chain);

        // Format the chain name: uppercase it and replace spaces with underscores,
        // then concatenate with the identifier to form a readable label.
        string memory formattedChain = vm.replace(vm.toUppercase(chain.name), " ", "_");
        string memory label = string.concat(formattedChain, "_", identifier);
        vm.label(addr, label);
    }

    /// @notice Retrieves an address by its identifier for a specified L2 chain
    /// This is deprecated in favor of the `get` function.
    function getAddress(string memory identifier, uint256 l2ChainId) public view returns (address who_) {
        who_ = registry[identifier][l2ChainId];
        require(
            who_ != address(0),
            string.concat(
                "SuperchainAddressRegistry: address not found for ", identifier, " on chain ", vm.toString(l2ChainId)
            )
        );
    }

    /// @notice Retrieves an address by its identifier for the sentinel chain, i.e. the
    /// `[addresses]` section of the config file.
    function get(string memory _identifier) public view returns (address who_) {
        return getAddress(_identifier, sentinelChain.chainId);
    }

    /// @notice Retrieves the identifier and chain info for a given address.
    /// This is deprecated in favor of the `get` function.
    function getAddressInfo(address addr) public view returns (AddressInfo memory) {
        require(
            bytes(addressInfo[addr].identifier).length != 0,
            string.concat("SuperchainAddressRegistry: AddressInfo not found for ", vm.toString(addr))
        );
        return addressInfo[addr];
    }

    /// @notice Retrieves the identifier and chain info for a given address.
    /// There might be multiple infos for the same address, this function
    /// will return the last info that was saved for the _who address.
    function get(address _who) public view returns (AddressInfo memory) {
        return getAddressInfo(_who);
    }

    /// @notice Returns the list of supported chains
    function getChains() public view returns (ChainInfo[] memory) {
        return chains;
    }

    // ========================================================
    // ======== Superchain address discovery functions ========
    // ========================================================

    /// @notice After instantiation of this contract, you can continue to discover new chains by calling this function.
    /// This makes addresses on these chains available by using the getAddress function.
    function discoverNewChain(ChainInfo memory chain) public {
        string memory chainAddressesContent = vm.readFile(SUPERCHAIN_REGISTRY_ADDRESSES_PATH);
        _processAddresses(chain, chainAddressesContent);
        chains.push(chain);
    }

    /// @dev Processes all configurations for a given chain.
    function _processAddresses(ChainInfo memory chain, string memory chainAddressesContent) internal {
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

    /// @dev Saves all dispute game related registry entries.
    function _saveDisputeGameEntries(ChainInfo memory chain, address disputeGameFactoryProxy) internal {
        saveAddress("DisputeGameFactoryProxy", chain, disputeGameFactoryProxy);

        address faultDisputeGame = getFaultDisputeGame(disputeGameFactoryProxy);
        if (faultDisputeGame != address(0)) {
            saveAddress("FaultDisputeGame", chain, faultDisputeGame);
            saveAddress("PermissionlessWETH", chain, getDelayedWETHProxy(faultDisputeGame));
        }

        address permissionedDisputeGame = getPermissionedDisputeGame(disputeGameFactoryProxy);
        saveAddress("PermissionedDisputeGame", chain, permissionedDisputeGame);

        address challenger = IFetcher(permissionedDisputeGame).challenger();
        saveAddress("Challenger", chain, challenger);

        address anchorStateRegistryProxy = getAnchorStateRegistryProxy(permissionedDisputeGame);
        saveAddress("AnchorStateRegistryProxy", chain, anchorStateRegistryProxy);

        saveAddress("PermissionedWETH", chain, getDelayedWETHProxy(permissionedDisputeGame));

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
        try IFetcher(systemConfigProxy).l1ERC721Bridge() returns (address l1ERC721Bridge) {
            return l1ERC721Bridge;
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

    function getDelayedWETHProxy(address disputeGame) internal view returns (address) {
        (bool ok, bytes memory data) = address(disputeGame).staticcall(abi.encodeWithSelector(IFetcher.weth.selector));
        if (ok && data.length == 32) return abi.decode(data, (address));
        else return address(0);
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
