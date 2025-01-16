// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IDisputeGameFactory
/// @notice The interface for a DisputeGameFactory contract.
interface IDisputeGameFactory {
    /// @notice `gameImpls` is a mapping that maps `GameType`s to their respective
    ///         `IDisputeGame` implementations.
    /// @param _gameType The type of the dispute game.
    /// @return impl_ The address of the implementation of the game type.
    ///         Will be cloned on creation of a new dispute game with the given `gameType`.
    function gameImpls(uint32 _gameType) external view returns (address impl_);

    /// @notice Sets the implementation contract for a specific `GameType`.
    /// @dev May only be called by the `owner`.
    /// @param _gameType The type of the DisputeGame.
    /// @param _impl The implementation contract for the given `GameType`.
    function setImplementation(uint32 _gameType, address _impl) external;
}
