// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice Interface of the Create2 Preinstall in L2.
interface ICreate2Deployer {
    function deploy(uint256 _value, bytes32 _salt, bytes memory _code) external;
}
