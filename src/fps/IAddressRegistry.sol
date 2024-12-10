pragma solidity 0.8.15;

/// @title Network Address Registry Interface
/// @notice Interface for managing and retrieving addresses across different networks.
interface IAddressRegistry {
    /// @notice Retrieves the address for a given identifier on the current chain.
    /// @param identifier The unique name associated with the address.
    /// @return The resolved address.
    function getAddress(string memory identifier) external view returns (address);

    /// @notice Checks if the address associated with an identifier is a contract on the current chain.
    /// @param identifier The unique name associated with the address.
    /// @return True if the address is a contract, false otherwise.
    function isAddressContract(string memory identifier) external view returns (bool);

    /// @notice Checks if an address is registered for a given identifier on the current chain.
    /// @param identifier The unique name associated with the address.
    /// @return True if the address is registered, false otherwise.
    function isAddressRegistered(string memory identifier) external view returns (bool);
}
