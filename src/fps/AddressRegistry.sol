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
        string name;
    }

    /// @notice Maps an identifier and l2 instance chain ID to a stored address entry.
    mapping(string => mapping(uint256 => RegistryEntry)) private registry;

    /// @notice The task implementation chain id.
    uint256 public supportedChainId;

    /// @notice Array of supported superchains and their configurations
    Superchain[] public superchains;

    /// @notice Initializes the contract by loading addresses from TOML files and setting up the superchains.
    /// @param addressFolderPath Path to the folder containing TOML files for addresses.
    /// @param superchainListFilePath Path to the TOML file containing the list of superchains.
    constructor(string memory addressFolderPath, string memory superchainListFilePath) {
        supportedChainId = block.chainid;

        bytes memory superchainListContent = vm.parseToml(vm.readFile(superchainListFilePath), ".chains");
        superchains = abi.decode(superchainListContent, (Superchain[]));

        string memory superchainAddressesPath = "lib/superchain-registry/superchain/extra/addresses/addresses.json";
        string memory superchainAddressesContent = vm.readFile(superchainAddressesPath);

        for (uint256 i = 0; i < superchains.length; i++) {
            uint256 superchainId = superchains[i].chainId;
            string memory superchainName = superchains[i].name;
            require(superchainId != 0, "Invalid chain ID in superchains");
            require(bytes(superchainName).length > 0, "Empty name in superchains");

            string memory filePath =
                string(abi.encodePacked(addressFolderPath, "/", vm.toString(superchainId), ".toml"));
            bytes memory fileContent = vm.parseToml(vm.readFile(filePath), ".addresses");

            InputAddress[] memory parsedAddresses = abi.decode(fileContent, (InputAddress[]));

            for (uint256 j = 0; j < parsedAddresses.length; j++) {
                string memory identifier = parsedAddresses[j].identifier;
                address contractAddress = parsedAddresses[j].addr;
                bool isContract = parsedAddresses[j].isContract;

                require(contractAddress != address(0), "Invalid address: cannot be zero");
                require(
                    registry[identifier][superchainId].addr == address(0),
                    "Address already registered with this identifier and chain ID"
                );

                _typeCheckAddress(contractAddress, isContract);

                registry[identifier][superchainId] = RegistryEntry(contractAddress, isContract);
                string memory prefixedIdentifier =
                    string(abi.encodePacked(vm.replace(vm.toUppercase(superchainName), " ", "_"), "_", identifier));
                vm.label(contractAddress, prefixedIdentifier); // Add label for debugging purposes
            }

            string[] memory keys =
                vm.parseJsonKeys(superchainAddressesContent, string.concat("$.", vm.toString(superchainId)));

            for (uint256 j = 0; j < keys.length; j++) {
                string memory key = keys[j];
                address addr = vm.parseJsonAddress(
                    superchainAddressesContent, string.concat("$.", vm.toString(superchainId), ".", key)
                );

                require(addr != address(0), "Invalid address: cannot be zero");
                require(
                    registry[key][superchainId].addr == address(0),
                    "Address already registered with this identifier and chain ID"
                );

                // todo: update this to accomodate for non-contract addresses in superchain registry
                // _typeCheckAddress(addr, true);

                registry[key][superchainId] = RegistryEntry(addr, true);
                string memory prefixedIdentifier =
                    string(abi.encodePacked(vm.replace(vm.toUppercase(superchainName), " ", "_"), "_", key));
                vm.label(addr, prefixedIdentifier);
            }
        }
    }

    /// @notice Retrieves an address by its identifier for a specified l2 chain instance.
    /// @param identifier The unique name associated with the address.
    /// @param l2chainId The chain ID of the L2 superchain.
    /// @return The address associated with the given identifier on the specified chain.
    function getAddress(string memory identifier, uint256 l2chainId) public view returns (address) {
        // Fetch the stored registry entry
        RegistryEntry memory entry = registry[identifier][l2chainId];
        address resolvedAddress = entry.addr;

        require(resolvedAddress != address(0), "Address not found");

        return resolvedAddress;
    }

    /// @notice Checks if an address by its identifier is a contract for a given l2 chain instance.
    /// @param identifier The unique name associated with the address.
    /// @param l2chainId The chain ID of the L2 superchain.
    /// @return True if the address is a contract, false otherwise.
    function isAddressContract(string memory identifier, uint256 l2chainId) public view returns (bool) {
        _checkAddressRegistered(identifier, l2chainId);

        return registry[identifier][l2chainId].isContract;
    }

    /// @notice Checks if an address by its identifier exists for a specified L2 chain instance.
    /// @param identifier The unique name associated with the address.
    /// @param l2chainId The chain ID of the L2 superchain.
    /// @return True if the address exists, false otherwise.
    function isAddressRegistered(string memory identifier, uint256 l2chainId) public view returns (bool) {
        return registry[identifier][l2chainId].addr != address(0);
    }

    /// @notice Verifies that an address is registered for a given identifier on a specific chain.
    /// @dev Ensures the address exists in the registry for the given identifier and chain ID.
    ///      Reverts with an error message if the address is not registered.
    /// @param identifier The unique name associated with the address.
    /// @param l2chainId l2 superchain chain id.
    function _checkAddressRegistered(string memory identifier, uint256 l2chainId) private view {
        require(
            isAddressRegistered(identifier, l2chainId),
            string(
                abi.encodePacked("Address not found for identifier ", identifier, " on chain ", vm.toString(l2chainId))
            )
        );
    }

    /// @notice Validates the type of an address (contract or externally owned account).
    /// @dev Ensures the address either contains or does not contain bytecode based on the `isContract` flag.
    ///      Reverts with an error if the address does not meet the expected type.
    /// @param addr The address to validate.
    /// @param isContract True if the address is expected to be a contract, false if it is expected to be an externally owned account (EOA).
    function _typeCheckAddress(address addr, bool isContract) private view {
        if (isContract) {
            require(addr.code.length > 0, "Address must contain code");
        } else {
            require(addr.code.length == 0, "Address must not contain code");
        }
    }
}
