// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm, VmSafe} from "forge-std/Vm.sol";

import {LibString} from "@solady/utils/LibString.sol";

/// @title DecimalNormalization
/// @notice Library for normalizing decimal values and parsing string
/// representations of decimal numbers.
library DecimalNormalization {
    using LibString for string;

    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    /// @notice Struct to hold parsed amount components
    struct AmountComponents {
        uint256 integer;
        uint256 decimal;
        uint8 decimalPlaces;
        bool hasDecimals;
    }

    /// @notice add the decimals to the given amount
    /// @param amount The amount to scale
    /// @param decimalsToScale The number of decimals to scale amount by
    function scaleDecimals(uint256 amount, uint8 decimalsToScale) internal pure returns (uint256) {
        return amount * (10 ** uint256(decimalsToScale));
    }

    /// @notice converts string to a scaled up token amount in decimal form
    /// @param amount string representation of the amount
    /// @param tokenDecimals number of decimals for the token
    /// returns the scaled up token amount
    function normalizeTokenAmount(string memory amount, uint8 tokenDecimals) internal pure returns (uint256) {
        // Get the scaled amount and decimals using parseDecimals
        (uint256 scaledAmount, uint8 parsedDecimals) = parseDecimals(amount);

        // Ensure amount decimals don't exceed token decimals
        require(
            parsedDecimals <= tokenDecimals,
            "DecimalNormalization: amount decimals must be less than or equal to token decimals"
        );

        // Scale the amount to match token decimals
        return scaleDecimals(scaledAmount, tokenDecimals - parsedDecimals);
    }

    /// @notice Validates that the amount string has a valid format
    /// @param components The split components of the amount string
    /// reverts if components are invalid
    function validateAmountFormat(string[] memory components) internal pure {
        // Check for invalid format (more than one decimal point)
        require(components.length <= 2, "DecimalNormalization: invalid amount");

        // If there's a decimal part, ensure it's not empty
        if (components.length == 2) {
            require(bytes(components[1]).length != 0, "DecimalNormalization: decimals cannot be 0");
        }
    }

    /// @notice Checks if the amount represents a non-zero value
    /// @param wholePart The whole number part of the amount
    /// @param decimalPart The decimal part of the amount
    /// @return True if either part results in a non-zero value
    function isNonZeroAmount(uint256 wholePart, uint256 decimalPart) internal pure returns (bool) {
        return wholePart > 0 || decimalPart > 0;
    }

    /// @notice Parses a string amount into its components
    /// @param amount The amount string to parse
    /// @return components The parsed amount components
    function parseAmountComponents(string memory amount) internal pure returns (AmountComponents memory components) {
        // first remove all commas from the amount, then split the amount into
        // its components
        string[] memory stringComponents = amount.replace(",", "").split(".");
        validateAmountFormat(stringComponents);

        components.integer = vm.parseUint(stringComponents[0]);
        components.hasDecimals = stringComponents.length == 2;

        if (components.hasDecimals) {
            components.decimal = vm.parseUint(stringComponents[1]);
            components.decimalPlaces = uint8(bytes(stringComponents[1]).length);
            require(components.decimalPlaces <= 18, "DecimalNormalization: decimals must be less than or equal to 18");
        }

        // Ensure the final amount is non-zero
        require(
            isNonZeroAmount(components.integer, components.decimal), "DecimalNormalization: amount must be non-zero"
        );

        return components;
    }

    /// @notice returns the amount with the length of the decimals parsed
    /// @param amount The amount to parse
    /// @return The amount and the number of decimals
    function parseDecimals(string memory amount) internal pure returns (uint256, uint8) {
        AmountComponents memory components = parseAmountComponents(amount);

        if (!components.hasDecimals || components.decimal == 0) {
            return (components.integer, 0);
        }

        uint256 finalAmount = components.integer * (10 ** uint256(components.decimalPlaces)) + components.decimal;

        return (finalAmount, components.decimalPlaces);
    }
}
