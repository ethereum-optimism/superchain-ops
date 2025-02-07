// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {Test} from "forge-std/Test.sol";

import {IAddressRegistry} from "src/improvements/IAddressRegistry.sol";

/// @notice Contains getters for arbitrary methods from all L1 contracts, including legacy getters
/// that have since been deprecated.
interface IFetcher {
    function guardian() external view returns (address);
    function GUARDIAN() external view returns (address);
    function systemConfig() external view returns (address);
    function SYSTEM_CONFIG() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function l2OutputOracle() external view returns (address);
    function superchainConfig() external view returns (address);
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
            ChainInfo memory chain = chains[i];
            uint256 chainId = chain.chainId; // L2 chain ID.

            require(!supportedL2ChainIds[chainId], "Duplicate chain ID in chain config");
            require(chainId != 0, "Invalid chain ID in config");
            require(bytes(chain.name).length > 0, "Empty name in config");

            supportedL2ChainIds[chainId] = true;

            // We get the OptimismPortal proxy address from the addresses file, and fetch everything
            // else from the chain itself to ensure all addresses are up to date. This is required
            // because the superchain registry does not have anything in place to guarantee that the
            // addresses in the addresses file are up to date. In later versions of the OP Stack
            // contracts starting from the SystemConfig is preferable because it stores all other
            // addresses, but for older contract versions, which we still need to support, starting
            // from the OptimismPortal is the only way to go.

            // TODO we should make sure our tests of this file cover enough chains to cover a range
            // of contract versions. For example chain ID 291 is on an older version of the contracts
            // than chain ID 10, so make sure we test both to ensure we have robust getters in this
            // contract.

            // --- Contracts ---
            address optimismPortalProxy = vm.parseJsonAddress(
                chainAddressesContent, string.concat("$.", vm.toString(chainId), ".OptimismPortalProxy")
            );
            saveAddress("OptimismPortalProxy", chain, optimismPortalProxy);

            address systemConfigProxy = getSystemConfigProxy(optimismPortalProxy);
            saveAddress("SystemConfigProxy", chain, systemConfigProxy);

            // AddressManager
            // AnchorStateRegistryProxy
            // DisputeGameFactoryProxy
            // FaultDisputeGame
            // L1CrossDomainMessengerProxy
            // L1ERC721BridgeProxy
            // L1StandardBridgeProxy
            // MIPS
            // OptimismMintableERC20FactoryProxy
            // OptimismPortalProxy
            // PermissionedDisputeGame
            // PreimageOracle
            // SystemConfigProxy

            // --- Roles ---
            address guardian = getGuardian(optimismPortalProxy);
            saveAddress("Guardian", chain, guardian);

            // BatchSubmitter
            // Challenger
            // Guardian
            // Proposer
            // ProxyAdmin
            // ProxyAdminOwner
            // SystemConfigOwner
            // UnsafeBlockSigner
        }
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
}
