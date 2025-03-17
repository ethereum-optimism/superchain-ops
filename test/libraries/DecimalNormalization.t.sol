// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {StringParser} from "src/libraries/StringParser.sol";
import {DecimalNormalization} from "src/libraries/DecimalNormalization.sol";
import {DecimalUtils} from "src/libraries/DecimalUtils.sol";
import {MockERC20} from "lib/solady/test/utils/mocks/MockERC20.sol";
import {MockDecimalNormalization} from "test/tasks/mock/MockDecimalNormalization.sol";
import {MockStringParser} from "test/tasks/mock/MockStringParser.sol";

contract DecimalNormalizationTest is Test {
    MockERC20 public token6; // 6 decimals
    MockERC20 public token18; // 18 decimals
    DecimalUtils public decimalUtils;
    MockStringParser public mockStringParser;
    MockDecimalNormalization public mockDecimalNormalization;

    function setUp() public {
        token6 = new MockERC20("Token6", "TK6", 6);
        token18 = new MockERC20("Token18", "TK18", 18);
        decimalUtils = new DecimalUtils();
        mockDecimalNormalization = new MockDecimalNormalization();
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

    function testParseDecimalsRevertNoDecimals() public {
        vm.expectRevert("decimals must be less than or equal to 18");
        mockStringParser.parseDecimals("100.1234567890123456789"); // 19 decimal places
    }

    function testValidateAmountFormat() public {
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

    function testParseDecimalsRevertZeroDecimals() public {
        vm.expectRevert("decimals cannot be 0");
        mockStringParser.parseDecimals("100."); // Decimal point with no digits after
    }

    function testParseDecimalsRevertInvalidFormat() public {
        vm.expectRevert("invalid amount");
        mockStringParser.parseDecimals("100.123.456"); // Multiple decimal points
    }

    function testParseDecimalsRevertZeroAmount() public {
        vm.expectRevert("amount must be non-zero");
        mockStringParser.parseDecimals("0.0"); // Zero amount

        vm.expectRevert("amount must be non-zero");
        mockStringParser.parseDecimals("0.00000"); // Zero amount with multiple zeros
    }

    // ==================== DecimalNormalization Tests ====================

    function testScaleDecimalsZero() public view {
        assertEq(mockDecimalNormalization.scaleDecimals(100, 0), 100);
    }

    function testScaleDecimalsStandard() public pure {
        assertEq(DecimalNormalization.scaleDecimals(100, 6), 100 * 10 ** 6);
        assertEq(DecimalNormalization.scaleDecimals(100, 8), 100 * 10 ** 8);
        assertEq(DecimalNormalization.scaleDecimals(100, 18), 100 * 10 ** 18);
    }

    function testScaleDecimalsLarge() public pure {
        // Test with a large amount but still within uint256 range
        uint256 largeAmount = 10 ** 20;
        assertEq(DecimalNormalization.scaleDecimals(largeAmount, 10), largeAmount * 10 ** 10);
    }

    function testNormalizeTokenAmountEqualDecimals() public pure {
        // Test when amount decimals equal token decimals (6)
        uint256 amount = DecimalNormalization.normalizeTokenAmount("100.123456", 6);
        assertEq(amount, 100123456);
    }

    function testNormalizeTokenAmountLessDecimals() public pure {
        // Test when amount decimals (3) are less than token decimals (6)
        uint256 amount = DecimalNormalization.normalizeTokenAmount("100.123", 6);
        assertEq(amount, 100123000); // 100.123 * 10^(6-3) = 100.123 * 10^3 = 100123000

        // Test when amount decimals (0) are less than token decimals (18)
        amount = DecimalNormalization.normalizeTokenAmount("100", 18);
        assertEq(amount, 100 * 10 ** 18); // 100 * 10^(18-0) = 100 * 10^18
    }

    function testNormalizeTokenAmountRevertMoreDecimals() public {
        // Test when amount decimals (8) are greater than token decimals (6)
        vm.expectRevert("amount decimals must be less than or equal to token decimals");
        mockDecimalNormalization.normalizeTokenAmount("100.12345678", 6);
    }

    function testNormalizeTokenAmountSmallDecimal() public pure {
        // Test with small decimal amount for token with 6 decimals
        uint256 amount = DecimalNormalization.normalizeTokenAmount("0.00001", 6);
        assertEq(amount, 10); // 0.00001 * 10^6 = 10

        // Test with small decimal amount for token with 18 decimals
        amount = DecimalNormalization.normalizeTokenAmount("0.00001", 18);
        assertEq(amount, 10 * 10 ** 12); // 0.00001 * 10^18 = 10 * 10^12 = 10000000000000
    }

    function testNormalizeTokenAmountRevertZeroAmount() public {
        vm.expectRevert("amount must be non-zero");
        mockDecimalNormalization.normalizeTokenAmount("0.0", 6);
    }

    // ==================== Integration Tests ====================

    function testIntegrationWithTokens() public view {
        // Test with token6 (6 decimals)
        uint8 tokenDecimals = token6.decimals();
        assertEq(tokenDecimals, 6);
        
        uint256 amount = DecimalNormalization.normalizeTokenAmount("100.123", tokenDecimals);
        assertEq(amount, 100123000);
        
        // Test with token18 (18 decimals)
        tokenDecimals = token18.decimals();
        assertEq(tokenDecimals, 18);
        
        amount = DecimalNormalization.normalizeTokenAmount("100.123456789", tokenDecimals);
        assertEq(amount, 100123456789 * 10 ** 9); // 100.123456789 * 10^(18-9) = 100.123456789 * 10^9
    }

    // ==================== DecimalUtils Wrapper Tests ====================

    function testDecimalUtilsScaleDecimals() public view {
        assertEq(decimalUtils.scaleDecimals(100, 0), 100);
        assertEq(decimalUtils.scaleDecimals(100, 6), 100 * 10 ** 6);
        assertEq(decimalUtils.scaleDecimals(100, 18), 100 * 10 ** 18);
    }

    function testDecimalUtilsParseDecimals() public view {
        (uint256 amount, uint8 decimals) = decimalUtils.parseDecimals("100.123");
        assertEq(amount, 100123);
        assertEq(decimals, 3);

        (amount, decimals) = decimalUtils.parseDecimals("0.000123");
        assertEq(amount, 123);
        assertEq(decimals, 6);
    }

    function testDecimalUtilsGetTokenAmount() public view {
        // Test with token6 (6 decimals)
        uint256 amount = decimalUtils.getTokenAmount("100.123", address(token6));
        assertEq(amount, 100123000);

        // Test with token18 (18 decimals)
        amount = decimalUtils.getTokenAmount("100.123456789", address(token18));
        assertEq(amount, 100123456789 * 10 ** 9);
    }

    function testDecimalUtilsGetTokenAmountWithDecimals() public view {
        // Test with 6 decimals
        uint256 amount = decimalUtils.getTokenAmountWithDecimals("100.123", 6);
        assertEq(amount, 100123000);

        // Test with 18 decimals
        amount = decimalUtils.getTokenAmountWithDecimals("100.123456789", 18);
        assertEq(amount, 100123456789 * 10 ** 9);
    }

    // ==================== Fuzz Tests for DecimalUtils ====================

    function testFuzz_DecimalUtilsScaleDecimals(uint256 amount, uint8 decimals) public view {
        // Bound amount to avoid overflow
        amount = bound(amount, 0, type(uint256).max / (10 ** 18));
        // Bound decimals to a reasonable range (0-18)
        decimals = uint8(bound(decimals, 0, 18));

        uint256 scaled = decimalUtils.scaleDecimals(amount, decimals);
        assertEq(scaled, amount * (10 ** uint256(decimals)));
    }

    function testFuzz_DecimalUtilsGetTokenAmountWithDecimals(uint256 amount, uint8 amountDecimals, uint8 tokenDecimals) public view {
        // Bound inputs to reasonable ranges
        amount = bound(amount, 1, 1000000);
        amountDecimals = uint8(bound(amountDecimals, 0, 18));
        tokenDecimals = uint8(bound(tokenDecimals, amountDecimals, 18)); // Ensure tokenDecimals >= amountDecimals

        // Format the amount string
        string memory amountStr;
        if (amountDecimals == 0) {
            amountStr = vm.toString(amount);
        } else {
            // Create a decimal string with the specified number of decimal places
            uint256 factor = 10 ** amountDecimals;
            uint256 wholePart = amount / factor;
            uint256 decimalPart = amount % factor;

            string memory decimalStr = vm.toString(decimalPart);
            // Pad with leading zeros if needed
            while (bytes(decimalStr).length < amountDecimals) {
                decimalStr = string(abi.encodePacked("0", decimalStr));
            }

            amountStr = string(abi.encodePacked(vm.toString(wholePart), ".", decimalStr));
        }

        uint256 tokenAmount = decimalUtils.getTokenAmountWithDecimals(amountStr, tokenDecimals);

        // Calculate expected amount
        uint256 expectedAmount;
        if (amountDecimals == 0) {
            expectedAmount = amount * (10 ** tokenDecimals);
        } else {
            expectedAmount = amount * (10 ** (tokenDecimals - amountDecimals));
        }

        assertEq(tokenAmount, expectedAmount);
    }
}
