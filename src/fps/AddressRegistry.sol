pragma solidity 0.8.15;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {Test} from "forge-std/Test.sol";
import {IAddressRegistry} from "src/fps/IAddressRegistry.sol";

/// @title Network Address Manager
/// @notice This contract provides a single source of truth for storing and retrieving addresses across multiple networks.
/// @dev Handles addresses for contracts and externally owned accounts (EOAs) while ensuring correctness and uniqueness.
contract AddressRegistry is IAddressRegistry, Test {
    using EnumerableSet for EnumerableSet.UintSet;

    /// chainlist .toml -> create this file for each task
    /// superchainRegistry
    ///   superchain/configs/ mainnnet/<network_name>.toml

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
    struct Superchain {
        uint256 chainId;
        string identifier;
        string name;
    }

    /// @notice Maps an identifier and chain ID to a stored address entry.
    mapping(string => mapping(uint256 => RegistryEntry)) private registry;

    uint256 public supportedChainIds; // List of supported chain IDs

    /// @notice Array of supported superchains and their configurations
    Superchain[] public superchains;

    /// @notice Initializes the contract by loading addresses from JSON files.
    /// @param addressFolderPath Path to the folder containing JSON files for addresses.
    /// @param chainId The chain IDs to load addresses for.
    constructor(string memory addressFolderPath, string memory superchainListPath, uint256 chainId) {
        supportedChainIds = chainId;

        require(block.chainid == chainId, "Chain ID mismatch in config");

        string memory filePath = string(abi.encodePacked(addressFolderPath, "/", vm.toString(chainId), ".toml"));
        bytes memory fileContent = vm.parseToml(vm.readFile(filePath), ".addresses");

        InputAddress[] memory parsedAddresses = abi.decode(fileContent, (InputAddress[]));

        for (uint256 i = 0; i < parsedAddresses.length; i++) {
            string memory identifier = parsedAddresses[i].identifier;
            address contractAddress = parsedAddresses[i].addr;
            bool isContract = parsedAddresses[i].isContract;

            require(contractAddress != address(0), "Invalid address: cannot be zero");
            require(chainId != 0, "Invalid chain ID: cannot be zero");
            require(
                registry[identifier][chainId].addr == address(0),
                "Address already registered with this identifier and chain ID"
            );

            // Validate if the address is correctly marked as a contract or EOA
            _typeCheckAddress(contractAddress, chainId, isContract);

            registry[identifier][chainId] = RegistryEntry(contractAddress, isContract);
            vm.label(contractAddress, identifier); // Add label for debugging purposes
        }

        bytes memory superchainListContent = vm.parseToml(vm.readFile(superchainListPath), ".chains");
        superchains = abi.decode(superchainListContent, (Superchain[]));

        string memory superchainAddressesPath = "lib/superchain-registry/superchain/extra/addresses/addresses.json";

        for (uint256 i = 0; i < superchains.length; i++) {
            require(superchains[i].chainId != 0, "Invalid chain ID in superchains");
            require(bytes(superchains[i].identifier).length > 0, "Empty identifier in superchains");
            require(bytes(superchains[i].name).length > 0, "Empty name in superchains");

            string memory superchainAddressesContent = vm.readFile(superchainAddressesPath);
            string[] memory keys =
                vm.parseJsonKeys(superchainAddressesContent, string.concat("$.", vm.toString(superchains[i].chainId)));

            for (uint256 j = 0; j < keys.length; j++) {
                address addr = vm.parseJsonAddress(
                    superchainAddressesContent, string.concat("$.", vm.toString(superchains[i].chainId), ".", keys[j])
                );
                string memory prefixedKey = string.concat(superchains[i].identifier, "_", keys[j]);
                registry[prefixedKey][chainId] = RegistryEntry(addr, true);
                vm.label(addr, prefixedKey);
            }
        }
    }

    /// @notice Retrieves an address by its identifier for the current chain.
    /// @param identifier Unique name for the address.
    /// @return The associated address.
    function getAddress(string memory identifier) public view returns (address) {
        _checkChainSupported(block.chainid);

        // Fetch the stored registry entry
        RegistryEntry memory entry = registry[identifier][block.chainid];
        address resolvedAddress = entry.addr;

        require(resolvedAddress != address(0), "Address not found");

        // Perform type checks only for the current chain
        _typeCheckAddress(resolvedAddress, block.chainid, entry.isContract);

        return resolvedAddress;
    }

    /// @notice Checks if an address by its identifier is a contract on the current chain.
    /// @param identifier Unique name for the address.
    /// @return True if the address is a contract, false otherwise.
    function isAddressContract(string memory identifier) public view returns (bool) {
        _checkAddressRegistered(identifier, block.chainid);
        _checkChainSupported(block.chainid);

        return registry[identifier][block.chainid].isContract;
    }

    /// @notice Checks if an address by its identifier exists on the current chain.
    /// @param identifier Unique name for the address.
    /// @return True if the address exists, false otherwise.
    function isAddressRegistered(string memory identifier) public view returns (bool) {
        _checkChainSupported(block.chainid);

        return registry[identifier][block.chainid].addr != address(0);
    }

    /// @notice Verifies that an address is registered for a given identifier on a specific chain.
    /// @dev Ensures the address exists in the registry for the given identifier and chain ID.
    ///      Reverts with an error message if the address is not registered.
    /// @param identifier The unique name associated with the address.
    /// @param chainId The blockchain network identifier.
    function _checkAddressRegistered(string memory identifier, uint256 chainId) private view {
        require(
            isAddressRegistered(identifier),
            string(
                abi.encodePacked("Address not found for identifier ", identifier, " on chain ", vm.toString(chainId))
            )
        );
    }

    /// @notice Validates the type of an address (contract or externally owned account) for the current chain.
    /// @dev Ensures the address either contains or does not contain bytecode based on the `isContract` flag.
    ///      This validation is only performed when the `chainId` matches the current chain's ID.
    ///      Reverts with an error if the address does not meet the expected type.
    /// Only allows for type checking on the current chain. Otherwise reverts. This prevents fork management errors.
    /// @param addr The address to validate.
    /// @param chainId The blockchain network id.
    /// @param isContract True if the address is expected to be a contract, false if it is expected to be an externally owned account (EOA).
    function _typeCheckAddress(address addr, uint256 chainId, bool isContract) private view {
        require(chainId == block.chainid, "Type check only supported for the current chain");

        if (isContract) {
            require(addr.code.length > 0, "Address must contain code");
        } else {
            require(addr.code.length == 0, "Address must not contain code");
        }
    }

    /// @notice Checks whether the specified chain ID is supported by the contract.
    /// @dev Reverts if the given `chainId` is not found in the `supportedChainIds` set.
    /// @param chainId The identifier of the chain to check for support.
    function _checkChainSupported(uint256 chainId) private view {
        require(
            supportedChainIds == chainId, string(abi.encodePacked("Chain ID ", vm.toString(chainId), " not supported"))
        );
    }
}
