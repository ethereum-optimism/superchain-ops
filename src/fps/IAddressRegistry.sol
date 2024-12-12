pragma solidity 0.8.15;

/// @title Network Address Registry Interface
/// @notice Interface for managing and retrieving addresses across different networks.
interface IAddressRegistry {
    /// @notice Retrieves an address by its identifier for a specified L2 chain
    /// @param identifier The unique identifier associated with the address
    /// @param l2ChainId The chain ID of the L2 network
    /// @return The address associated with the given identifier on the specified chain
    function getAddress(string memory identifier, uint256 l2ChainId) external view returns (address);

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
