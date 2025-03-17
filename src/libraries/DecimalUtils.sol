// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {StringParser} from "./StringParser.sol";
import {DecimalNormalization} from "./DecimalNormalization.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

/// @title DecimalUtils
/// @notice Wrapper contract for decimal normalization and string parsing utilities
contract DecimalUtils {
    /// @notice add the decimals to the given amount
    /// @param amount The amount to scale
    /// @param decimals The number of decimals to scale by
    function scaleDecimals(uint256 amount, uint8 decimals) public pure returns (uint256) {
        return DecimalNormalization.scaleDecimals(amount, decimals);
    }

    /// @notice returns the amount with the length of the decimals parsed
    /// @param amount The amount to parse
    /// @return The amount and the number of decimals
    function parseDecimals(string memory amount) public pure returns (uint256, uint8) {
        return StringParser.parseDecimals(amount);
    }

    /// @notice converts string to a scaled up token amount in decimal form
    /// @param amount string representation of the amount
    /// @param token address of the token to send, used discovering the decimals
    /// returns the scaled up token amount
    function getTokenAmount(string memory amount, address token) public view returns (uint256) {
        // Get token decimals
        uint8 tokenDecimals = ERC20(token).decimals();
        
        // Use the DecimalNormalization library to normalize the token amount
        return DecimalNormalization.normalizeTokenAmount(amount, tokenDecimals);
    }

    /// @notice converts string to a scaled up token amount in decimal form
    /// @param amount string representation of the amount
    /// @param tokenDecimals number of decimals for the token
    /// returns the scaled up token amount
    function getTokenAmountWithDecimals(string memory amount, uint8 tokenDecimals) public pure returns (uint256) {
        // Use the DecimalNormalization library to normalize the token amount
        return DecimalNormalization.normalizeTokenAmount(amount, tokenDecimals);
    }
}
