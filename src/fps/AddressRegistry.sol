// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {Test} from "forge-std/Test.sol";

import {IAddressRegistry} from "src/fps/IAddressRegistry.sol";

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

        chains = abi.decode(chainListContent, (ChainInfo[]));

        /// should never revert
        string memory chainAddressesContent =
            vm.readFile("lib/superchain-registry/superchain/extra/addresses/addresses.json");

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            string memory chainName = chains[i].name;
            require(!supportedL2ChainIds[chainId], "Duplicate chain ID in chain config");
            require(chainId != 0, "Invalid chain ID in config");
            require(bytes(chainName).length > 0, "Empty name in config");

            supportedL2ChainIds[chainId] = true;

            string[] memory keys = vm.parseJsonKeys(chainAddressesContent, string.concat("$.", vm.toString(chainId)));

            for (uint256 j = 0; j < keys.length; j++) {
                string memory key = keys[j];
                address addr =
                    vm.parseJsonAddress(chainAddressesContent, string.concat("$.", vm.toString(chainId), ".", key));

                require(addr != address(0), "Invalid address: cannot be zero");
                require(
                    registry[key][chainId].addr == address(0),
                    "Address already registered with this identifier and chain ID"
                );

                registry[key][chainId] = RegistryEntry(addr, addr.code.length > 0);
                string memory prefixedIdentifier =
                    string(abi.encodePacked(vm.replace(vm.toUppercase(chainName), " ", "_"), "_", key));
                vm.label(addr, prefixedIdentifier);
            }
        }
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
}
