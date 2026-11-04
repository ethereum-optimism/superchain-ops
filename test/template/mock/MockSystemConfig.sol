// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice SystemConfig stand-in: only the DelayedWETH pointer the template resolves.
contract MockSystemConfig {
    address public delayedWETH;

    constructor(address weth) {
        delayedWETH = weth;
    }

    function setDelayedWETH(address weth) external {
        delayedWETH = weth;
    }
}
