pragma solidity 0.8.15;

/// @title Network Address Registry Interface
/// @notice Interface for managing and retrieving addresses across different networks.
interface IAddressRegistry {
    /// @notice Retrieves an address by its identifier for a specified l2 chain instance.
    /// @param identifier The unique name associated with the address.
    /// @param l2chainId The chain ID of the L2 superchain.
    /// @return The address associated with the given identifier on the specified chain.
    function getAddress(string memory identifier, uint256 l2chainId) external view returns (address);

    /// @notice Checks if an address by its identifier is a contract for a given l2 chain instance.
    /// @param identifier The unique name associated with the address.
    /// @param l2chainId The chain ID of the L2 superchain.
    /// @return True if the address is a contract, false otherwise.
    function isAddressContract(string memory identifier, uint256 l2chainId) external view returns (bool);

    /// @notice Checks if an address by its identifier exists for a specified L2 chain instance.
    /// @param identifier The unique name associated with the address.
    /// @param l2chainId The chain ID of the L2 superchain.
    /// @return True if the address exists, false otherwise.
    function isAddressRegistered(string memory identifier, uint256 l2chainId) external view returns (bool);
}
