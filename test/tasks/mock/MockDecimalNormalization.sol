pragma solidity 0.8.15;

import {DecimalNormalization} from "src/libraries/DecimalNormalization.sol";

/// @notice mock contract for testing DecimalNormalization library
contract MockDecimalNormalization {
    function scaleDecimals(uint256 amount, uint8 decimals) external pure returns (uint256) {
        return DecimalNormalization.scaleDecimals(amount, decimals);
    }

    function normalizeTokenAmount(string memory amount, uint8 tokenDecimals) external pure returns (uint256) {
        return DecimalNormalization.normalizeTokenAmount(amount, tokenDecimals);
    }
}