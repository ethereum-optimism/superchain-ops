// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice AnchorStateRegistry stand-in with the getters and setter the template uses.
contract MockAnchorStateRegistry {
    uint256 public disputeGameFinalityDelaySeconds = 302400;

    function minDisputeGameFinalityDelaySeconds() external pure returns (uint256) {
        return 43200;
    }

    function maxDisputeGameFinalityDelaySeconds() external pure returns (uint256) {
        return 302400;
    }

    function setDisputeGameFinalityDelaySeconds(uint256 value) external {
        disputeGameFinalityDelaySeconds = value;
    }
}
