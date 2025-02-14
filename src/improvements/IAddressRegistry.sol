// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title Network Address Registry Interface
/// @notice Interface for managing and retrieving addresses across different networks.
interface IAddressRegistry {
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

    /// @dev Structure for storing address info for a given address.
    struct AddressInfo {
        string identifier;
        ChainInfo chainInfo;
    }

    /// @notice Retrieves an address by its identifier for a specified L2 chain
    /// @param identifier The unique identifier associated with the address
    /// @param l2ChainId The chain ID of the L2 network
    /// @return The address associated with the given identifier on the specified chain
    function getAddress(string memory identifier, uint256 l2ChainId) external view returns (address);

    /// @notice Retrieves the identifier and chain info for a given address.
    /// @param addr The address to retrieve info for.
    /// @return The identifier and chain info for the given address.
    function getAddressInfo(address addr) external view returns (AddressInfo memory);

    /// @notice Checks if an address is a contract for a given identifier and L2 chain
    /// @param identifier The unique identifier associated with the address
    /// @param l2ChainId The chain ID of the L2 network
    /// @return True if the address is a contract, false otherwise
    function isAddressContract(string memory identifier, uint256 l2ChainId) external view returns (bool);

    /// @notice Checks if an address exists for a specified identifier and L2 chain
    /// @param identifier The unique identifier associated with the address
    /// @param l2ChainId The chain ID of the L2 network
    /// @return True if the address exists, false otherwise
    function isAddressRegistered(string memory identifier, uint256 l2ChainId) external view returns (bool);
}
