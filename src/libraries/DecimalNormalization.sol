// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {StringParser} from "./StringParser.sol";

/// @title DecimalNormalization
/// @notice Library for normalizing decimal values
library DecimalNormalization {
    /// @notice add the decimals to the given amount
    /// @param amount The amount to scale
    /// @param decimals The number of decimals to scale by
    function scaleDecimals(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        return amount * (10 ** uint256(decimals));
    }

    /// @notice converts string to a scaled up token amount in decimal form
    /// @param amount string representation of the amount
    /// @param tokenDecimals number of decimals for the token
    /// returns the scaled up token amount
    function normalizeTokenAmount(string memory amount, uint8 tokenDecimals) internal pure returns (uint256) {
        // Get the scaled amount and decimals using parseDecimals
        (uint256 scaledAmount, uint8 parsedDecimals) = StringParser.parseDecimals(amount);

        // Ensure amount decimals don't exceed token decimals
        require(parsedDecimals <= tokenDecimals, "amount decimals must be less than or equal to token decimals");

        // Scale the amount to match token decimals
        return scaleDecimals(scaledAmount, tokenDecimals - parsedDecimals);
    }
}
