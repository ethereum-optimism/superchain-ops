// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Create2} from "openzeppelin-contracts/contracts/utils/Create2.sol";

/// @notice A contract that deploys contracts via CREATE2.
contract MockXDeployer {
    function deploy(uint256 value, bytes32 salt, bytes memory initCode) public returns (address) {
        return Create2.deploy(value, salt, initCode);
    }
}
