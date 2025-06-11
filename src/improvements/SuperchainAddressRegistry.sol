// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
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

    /// @notice Multicall3 helper for batching L1 calls.
    IMulticall3 public immutable multicall3;

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

        multicall3 = IMulticall3(0xcA11bde05977b3631167028862bE2a173976CA11);

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

        address systemConfigProxy;
        {
            IMulticall3.Call3[] memory portalCalls = new IMulticall3.Call3[](3);
            portalCalls[0] = IMulticall3.Call3({
                target: optimismPortalProxy,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.superchainConfig.selector)
            });
            portalCalls[1] = IMulticall3.Call3({
                target: optimismPortalProxy,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.systemConfig.selector)
            });
            portalCalls[2] = IMulticall3.Call3({
                target: optimismPortalProxy,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.SYSTEM_CONFIG.selector)
            });

            IMulticall3.Result[] memory portalResults = multicall3.aggregate3(portalCalls);

            if (portalResults[0].success && portalResults[0].returnData.length == 32) {
                address superchainConfig = abi.decode(portalResults[0].returnData, (address));
                if (superchainConfig != address(0)) {
                    saveAddress("SuperchainConfig", chain, superchainConfig);
                }
            }

            if (portalResults[1].success && portalResults[1].returnData.length == 32) {
                systemConfigProxy = abi.decode(portalResults[1].returnData, (address));
            } else if (portalResults[2].success && portalResults[2].returnData.length == 32) {
                systemConfigProxy = abi.decode(portalResults[2].returnData, (address));
            }
            require(systemConfigProxy != address(0), "SuperchainAddressRegistry: SystemConfigProxy not found");
            saveAddress("SystemConfigProxy", chain, systemConfigProxy);
        }

        _saveProxyAdminEntries(chain, systemConfigProxy);

        {
            IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](8);
            calls[0] = IMulticall3.Call3({
                target: systemConfigProxy,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.l1ERC721Bridge.selector)
            });
            calls[1] = IMulticall3.Call3({
                target: systemConfigProxy,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.optimismMintableERC20Factory.selector)
            });
            calls[2] = IMulticall3.Call3({
                target: systemConfigProxy,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.disputeGameFactory.selector)
            });
            calls[3] = IMulticall3.Call3({
                target: optimismPortalProxy,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.guardian.selector)
            });
            calls[4] = IMulticall3.Call3({
                target: optimismPortalProxy,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.GUARDIAN.selector)
            });
            calls[5] =
                IMulticall3.Call3({target: systemConfigProxy, allowFailure: true, callData: abi.encodeWithSelector(IFetcher.batcherHash.selector)});
            calls[6] = IMulticall3.Call3({
                target: systemConfigProxy,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.unsafeBlockSigner.selector)
            });
            calls[7] =
                IMulticall3.Call3({target: optimismPortalProxy, allowFailure: true, callData: abi.encodeWithSelector(IFetcher.L2_ORACLE.selector)});

            IMulticall3.Result[] memory results = multicall3.aggregate3(calls);

            address l1ERC721BridgeProxy;
            if (results[0].success && results[0].returnData.length == 32) {
                l1ERC721BridgeProxy = abi.decode(results[0].returnData, (address));
            } else {
                l1ERC721BridgeProxy = parseContractAddress(chainAddressesContent, chainId, "L1ERC721BridgeProxy");
            }
            saveAddress("L1ERC721BridgeProxy", chain, l1ERC721BridgeProxy);

            address optimismMintableERC20FactoryProxy;
            if (results[1].success && results[1].returnData.length == 32) {
                optimismMintableERC20FactoryProxy = abi.decode(results[1].returnData, (address));
            } else {
                optimismMintableERC20FactoryProxy =
                    parseContractAddress(chainAddressesContent, chainId, "OptimismMintableERC20FactoryProxy");
            }
            saveAddress("OptimismMintableERC20FactoryProxy", chain, optimismMintableERC20FactoryProxy);

            address disputeGameFactoryProxy;
            if (results[2].success && results[2].returnData.length == 32) {
                disputeGameFactoryProxy = abi.decode(results[2].returnData, (address));
            }

            if (disputeGameFactoryProxy != address(0)) {
                _saveDisputeGameEntries(chain, disputeGameFactoryProxy);
            } else {
                if (results[7].success && results[7].returnData.length == 32) {
                    address l2OutputOracleProxy = abi.decode(results[7].returnData, (address));
                    if (l2OutputOracleProxy != address(0)) {
                        saveAddress("L2OutputOracleProxy", chain, l2OutputOracleProxy);
                        address proposer = IFetcher(l2OutputOracleProxy).PROPOSER();
                        saveAddress("Proposer", chain, proposer);
                    }
                }
            }

            address guardian;
            if (results[3].success && results[3].returnData.length == 32) {
                guardian = abi.decode(results[3].returnData, (address));
            } else if (results[4].success && results[4].returnData.length == 32) {
                guardian = abi.decode(results[4].returnData, (address));
            }
            if (guardian != address(0)) {
                saveAddress("Guardian", chain, guardian);
            }

            if (results[5].success && results[5].returnData.length == 32) {
                bytes32 batcherHash = abi.decode(results[5].returnData, (bytes32));
                address batchSubmitter = address(uint160(uint256(batcherHash)));
                saveAddress("BatchSubmitter", chain, batchSubmitter);
            }

            if (results[6].success && results[6].returnData.length == 32) {
                address unsafeBlockSigner = abi.decode(results[6].returnData, (address));
                if (unsafeBlockSigner != address(0)) {
                    saveAddress("UnsafeBlockSigner", chain, unsafeBlockSigner);
                }
            }
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

        optimismPortalProxy = getOptimismPortalProxy(l1CrossDomainMessengerProxy);
        saveAddress("OptimismPortalProxy", chain, optimismPortalProxy);

        address addressManager = getAddressManager(l1CrossDomainMessengerProxy);
        saveAddress("AddressManager", chain, addressManager);
    }

    function _saveProxyAdminEntries(ChainInfo memory chain, address systemConfigProxy) internal {
        address proxyAdmin = getProxyAdmin(systemConfigProxy);
        saveAddress("ProxyAdmin", chain, proxyAdmin);

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](2);
        calls[0] = IMulticall3.Call3({
            target: proxyAdmin,
            allowFailure: true,
            callData: abi.encodeWithSelector(IFetcher.owner.selector)
        });
        calls[1] = IMulticall3.Call3({
            target: systemConfigProxy,
            allowFailure: true,
            callData: abi.encodeWithSelector(IFetcher.owner.selector)
        });

        IMulticall3.Result[] memory results = multicall3.aggregate3(calls);

        address proxyAdminOwner = abi.decode(results[0].returnData, (address));
        saveAddress("ProxyAdminOwner", chain, proxyAdminOwner);

        address systemConfigOwner = abi.decode(results[1].returnData, (address));
        saveAddress("SystemConfigOwner", chain, systemConfigOwner);
    }

    /// @dev Saves all dispute game related registry entries.
    function _saveDisputeGameEntries(ChainInfo memory chain, address disputeGameFactoryProxy) internal {
        saveAddress("DisputeGameFactoryProxy", chain, disputeGameFactoryProxy);

        IMulticall3.Call3[] memory gameImplCalls = new IMulticall3.Call3[](2);
        gameImplCalls[0] = IMulticall3.Call3({
            target: disputeGameFactoryProxy,
            allowFailure: true,
            callData: abi.encodeWithSelector(IFetcher.gameImpls.selector, GameTypes.CANNON)
        });
        gameImplCalls[1] = IMulticall3.Call3({
            target: disputeGameFactoryProxy,
            allowFailure: true,
            callData: abi.encodeWithSelector(IFetcher.gameImpls.selector, GameTypes.PERMISSIONED_CANNON)
        });

        IMulticall3.Result[] memory gameImplResults = multicall3.aggregate3(gameImplCalls);

        address faultDisputeGame;
        if (gameImplResults[0].success && gameImplResults[0].returnData.length == 32) {
            faultDisputeGame = abi.decode(gameImplResults[0].returnData, (address));
        }

        address permissionedDisputeGame;
        if (gameImplResults[1].success && gameImplResults[1].returnData.length == 32) {
            permissionedDisputeGame = abi.decode(gameImplResults[1].returnData, (address));
        }

        if (faultDisputeGame != address(0)) {
            saveAddress("FaultDisputeGame", chain, faultDisputeGame);
            address weth = getDelayedWETHProxy(faultDisputeGame);
            if (weth != address(0)) {
                saveAddress("PermissionlessWETH", chain, weth);
            }
        }

        if (permissionedDisputeGame != address(0)) {
            saveAddress("PermissionedDisputeGame", chain, permissionedDisputeGame);

            IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](5);
            calls[0] = IMulticall3.Call3({
                target: permissionedDisputeGame,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.challenger.selector)
            });
            calls[1] = IMulticall3.Call3({
                target: permissionedDisputeGame,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.anchorStateRegistry.selector)
            });
            calls[2] = IMulticall3.Call3({
                target: permissionedDisputeGame,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.weth.selector)
            });
            calls[3] = IMulticall3.Call3({
                target: permissionedDisputeGame,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.vm.selector)
            });
            calls[4] = IMulticall3.Call3({
                target: permissionedDisputeGame,
                allowFailure: true,
                callData: abi.encodeWithSelector(IFetcher.proposer.selector)
            });

            IMulticall3.Result[] memory results = multicall3.aggregate3(calls);

            if (results[0].success && results[0].returnData.length == 32) {
                address challenger = abi.decode(results[0].returnData, (address));
                if (challenger != address(0)) saveAddress("Challenger", chain, challenger);
            }

            if (results[1].success && results[1].returnData.length == 32) {
                address anchorStateRegistryProxy = abi.decode(results[1].returnData, (address));
                if (anchorStateRegistryProxy != address(0))
                    saveAddress("AnchorStateRegistryProxy", chain, anchorStateRegistryProxy);
            }

            if (results[2].success && results[2].returnData.length == 32) {
                address permissionedWeth = abi.decode(results[2].returnData, (address));
                if (permissionedWeth != address(0)) saveAddress("PermissionedWETH", chain, permissionedWeth);
            }

            if (results[3].success && results[3].returnData.length == 32) {
                address mips = abi.decode(results[3].returnData, (address));
                if (mips != address(0)) {
                    saveAddress("MIPS", chain, mips);
                    address preimageOracle = IFetcher(mips).oracle();
                    if (preimageOracle != address(0)) {
                        saveAddress("PreimageOracle", chain, preimageOracle);
                    }
                }
            }

            if (results[4].success && results[4].returnData.length == 32) {
                address proposer = abi.decode(results[4].returnData, (address));
                if (proposer != address(0)) saveAddress("Proposer", chain, proposer);
            }
        }
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

    function getSuperchainConfig(address optimismPortalProxy) internal view returns (address) {
        try IFetcher(optimismPortalProxy).superchainConfig() returns (address superchainConfig) {
            return superchainConfig;
        } catch {
            return address(0);
        }
    }

    function getDelayedWETHProxy(address disputeGame) internal view returns (address) {
        (bool ok, bytes memory data) = address(disputeGame).staticcall(abi.encodeWithSelector(IFetcher.weth.selector));
        if (ok && data.length == 32) return abi.decode(data, (address));
        else return address(0);
    }

    function getProxyAdmin(address systemConfigProxy) internal returns (address) {
        vm.prank(address(0));
        return IFetcher(systemConfigProxy).admin();
    }
}
