// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice DelayedWETH stand-in with the getters and setter the template uses.
contract MockDelayedWETH {
    string internal _version = "3.0.0";
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

    function version() public view returns (string memory) {
        return _version;
    }

    function setVersion(string memory value) external {
        _version = value;
    }
}
