// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice DelayedWETH stand-in with the getters and setter the template uses.
contract MockDelayedWETH {
    uint256 public delay = 604800;

    function minDelay() external pure returns (uint256) {
        return 43200;
    }

    function maxDelay() external pure returns (uint256) {
        return 604800;
    }

    function setDelay(uint256 value) external {
        delay = value;
    }
}
