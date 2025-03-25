// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

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
    }

    /// @notice converts string to a scaled up token amount in decimal form
    /// @param amount string representation of the amount
    /// @param tokenDecimals number of decimals for the token
    /// returns the scaled up token amount
    function normalizeTokenAmount(string memory amount, uint8 tokenDecimals) internal pure returns (uint256) {
        AmountComponents memory components = parseAmountComponents(amount);

        validateAmountComponents(components, tokenDecimals);

        uint256 finalAmount = components.integer * (10 ** uint256(tokenDecimals))
            + components.decimal * (10 ** uint256(tokenDecimals - components.decimalPlaces));

        return finalAmount;
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
    /// @param integer The integer part of the amount
    /// @param decimal The decimal part of the amount
    /// @return True if either part results in a non-zero value
    function isNonZeroAmount(uint256 integer, uint256 decimal) internal pure returns (bool) {
        return integer > 0 || decimal > 0;
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
        if (stringComponents.length == 2) {
            components.decimal = vm.parseUint(stringComponents[1]);
            components.decimalPlaces = uint8(bytes(stringComponents[1]).length);
        }

        return components;
    }

    /// @notice Validates the parsed amount components
    /// @param components The parsed amount components
    /// @param tokenDecimals The number of decimals for the token
    /// reverts if components are invalid
    function validateAmountComponents(AmountComponents memory components, uint8 tokenDecimals) internal pure {
        require(components.decimalPlaces <= 18, "DecimalNormalization: decimals must be less than or equal to 18");
        require(
            components.decimalPlaces <= tokenDecimals,
            "DecimalNormalization: amount decimals must be less than or equal to token decimals"
        );

        // Ensure the final amount is non-zero
        require(
            isNonZeroAmount(components.integer, components.decimal), "DecimalNormalization: amount must be non-zero"
        );
    }
}
