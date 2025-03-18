// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {StringParser} from "src/libraries/StringParser.sol";
import {MockStringParser} from "test/tasks/mock/MockStringParser.sol";

contract StringParserTest is Test {
    MockStringParser public mockStringParser;

    function setUp() public {
        mockStringParser = new MockStringParser();
    }

    // ==================== StringParser Tests ====================

    function testParseDecimalsWholeNumber() public pure {
        (uint256 amount, uint8 decimals) = StringParser.parseDecimals("100");
        assertEq(amount, 100);
        assertEq(decimals, 0);
    }

    function testParseDecimalsZeroDecimalPart() public pure {
        (uint256 amount, uint8 decimals) = StringParser.parseDecimals("100.0");
        assertEq(amount, 100);
        assertEq(decimals, 0);

        (amount, decimals) = StringParser.parseDecimals("100.00");
        assertEq(amount, 100);
        assertEq(decimals, 0);
    }

    function testParseDecimalsNonZeroDecimalPart() public pure {
        (uint256 amount, uint8 decimals) = StringParser.parseDecimals("100.123");
        assertEq(amount, 100123);
        assertEq(decimals, 3);

        (amount, decimals) = StringParser.parseDecimals("100.000123");
        assertEq(amount, 100000123);
        assertEq(decimals, 6);
    }

    function testParseDecimalsMaxDecimals() public pure {
        (uint256 amount, uint8 decimals) = StringParser.parseDecimals("100.123456789012345678");
        assertEq(amount, 100123456789012345678);
        assertEq(decimals, 18);
    }

    function testParseDecimalsRevertTooManyDecimals() public {
        vm.expectRevert("decimals must be less than or equal to 18");
        mockStringParser.parseDecimals("100.1234567890123456789"); // 19 decimal places
    }

    function testValidAndInvalidAmountFormats() public {
        // Test valid formats through parseDecimals which calls validateAmountFormat
        StringParser.parseDecimals("100");
        StringParser.parseDecimals("100.123");

        // Test invalid formats
        vm.expectRevert("decimals cannot be 0");
        mockStringParser.parseDecimals("100.");

        vm.expectRevert("invalid amount");
        mockStringParser.parseDecimals("100.123.456");
    }

    function testParseDecimalsZeroValue() public pure {
        // Test with zero whole part and non-zero decimal part
        (uint256 amount, uint8 decimals) = StringParser.parseDecimals("0.123456789012345678");
        assertEq(amount, 123456789012345678);
        assertEq(decimals, 18);
    }

    function testParseDecimalsRevertZeroAmount() public {
        vm.expectRevert("amount must be non-zero");
        mockStringParser.parseDecimals("0.0"); // Zero amount

        vm.expectRevert("amount must be non-zero");
        mockStringParser.parseDecimals("0.00000"); // Zero amount with multiple zeros
    }

    // ==================== AmountComponents Tests ====================

    function testParseAmountComponents() public view {
        // Test whole number
        StringParser.AmountComponents memory components = mockStringParser.parseAmountComponents("100");
        assertEq(components.wholePart, 100);
        assertEq(components.decimalPart, 0);
        assertEq(components.decimalPlaces, 0);
        assertEq(components.hasDecimals, false);

        // Test with decimal part
        components = mockStringParser.parseAmountComponents("100.123");
        assertEq(components.wholePart, 100);
        assertEq(components.decimalPart, 123);
        assertEq(components.decimalPlaces, 3);
        assertEq(components.hasDecimals, true);

        // Test with zero whole part
        components = mockStringParser.parseAmountComponents("0.123");
        assertEq(components.wholePart, 0);
        assertEq(components.decimalPart, 123);
        assertEq(components.decimalPlaces, 3);
        assertEq(components.hasDecimals, true);
    }

    function testParseAmountComponentsRevertInvalidFormat() public {
        // Test with multiple decimal points
        vm.expectRevert("invalid amount");
        mockStringParser.parseAmountComponents("100.123.456");

        // Test with empty decimal part
        vm.expectRevert("decimals cannot be 0");
        mockStringParser.parseAmountComponents("100.");

        // Test with too many decimals
        vm.expectRevert("decimals must be less than or equal to 18");
        mockStringParser.parseAmountComponents("100.1234567890123456789"); // 19 decimal places
    }

    // ==================== isNonZeroAmount Tests ====================

    function testIsNonZeroAmount() public pure {
        // Test with non-zero whole part
        bool result = StringParser.isNonZeroAmount(100, 0);
        assertEq(result, true);

        // Test with non-zero decimal part
        result = StringParser.isNonZeroAmount(0, 123);
        assertEq(result, true);

        // Test with both parts non-zero
        result = StringParser.isNonZeroAmount(100, 123);
        assertEq(result, true);

        // Test with both parts zero
        result = StringParser.isNonZeroAmount(0, 0);
        assertEq(result, false);
    }
}
