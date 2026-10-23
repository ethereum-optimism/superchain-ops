// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice OptimismPortal2 stand-in with the getters and setter the template uses, plus a pause switch.
contract MockOptimismPortal2 {
    uint256 public proofMaturityDelaySeconds = 604800;
    address public ethLockbox;
    bool public paused;

    function minProofMaturityDelaySeconds() external pure returns (uint256) {
        return 86400;
    }

    function maxProofMaturityDelaySeconds() external pure returns (uint256) {
        return 604800;
    }

    function setProofMaturityDelaySeconds(uint256 value) external {
        proofMaturityDelaySeconds = value;
    }

    function setPaused(bool value) external {
        paused = value;
    }

    function setEthLockbox(address value) external {
        ethLockbox = value;
    }
}
