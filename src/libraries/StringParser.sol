// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {LibString} from "@solady/utils/LibString.sol";

/// @title StringParser
/// @notice Library for parsing string representations of decimal numbers
library StringParser {
    using LibString for string;

    /// @notice Struct to hold parsed amount components
    struct AmountComponents {
        uint256 wholePart;
        uint256 decimalPart;
        uint8 decimalPlaces;
        bool hasDecimals;
    }

    /// @notice Validates that the amount string has a valid format
    /// @param components The split components of the amount string
    /// reverts if components are invalid
    function validateAmountFormat(string[] memory components) internal pure {
        // Check for invalid format (more than one decimal point)
        require(components.length <= 2, "invalid amount");

        // If there's a decimal part, ensure it's not empty
        if (components.length == 2) {
            require(bytes(components[1]).length != 0, "decimals cannot be 0");
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
        VmSafe vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));
        
        string[] memory stringComponents = amount.split(".");
        validateAmountFormat(stringComponents);

        components.wholePart = vm.parseUint(stringComponents[0]);
        components.hasDecimals = stringComponents.length == 2;

        if (components.hasDecimals) {
            components.decimalPart = vm.parseUint(stringComponents[1]);
            components.decimalPlaces = uint8(bytes(stringComponents[1]).length);
            require(components.decimalPlaces <= 18, "decimals must be less than or equal to 18");
        }

        // Ensure the final amount is non-zero
        require(isNonZeroAmount(components.wholePart, components.decimalPart), "amount must be non-zero");

        return components;
    }

    /// @notice returns the amount with the length of the decimals parsed
    /// @param amount The amount to parse
    /// @return The amount and the number of decimals
    function parseDecimals(string memory amount) internal pure returns (uint256, uint8) {
        AmountComponents memory components = parseAmountComponents(amount);

        if (!components.hasDecimals || components.decimalPart == 0) {
            return (components.wholePart, 0);
        }

        uint256 finalAmount = components.wholePart * (10 ** uint256(components.decimalPlaces)) + components.decimalPart;

        return (finalAmount, components.decimalPlaces);
    }
}
