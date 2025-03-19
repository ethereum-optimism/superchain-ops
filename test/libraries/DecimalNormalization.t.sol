// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MockERC20} from "lib/solady/test/utils/mocks/MockERC20.sol";

import {Test} from "forge-std/Test.sol";

import {DecimalNormalization} from "src/libraries/DecimalNormalization.sol";

/// the "forge-config" comment is used to allow internal expect revert in the
/// tests. This is useful for testing internal functions that are at call depth
/// of 0 without creating mock contracts or libraries.
/// https://book.getfoundry.sh/cheatcodes/expect-revert#error
/// https://book.getfoundry.sh/cheatcodes/expect-revert#description
contract DecimalNormalizationTest is Test {
    MockERC20 public token6; // 6 decimals
    MockERC20 public token18; // 18 decimals

    function setUp() public {
        token6 = new MockERC20("Token6", "TK6", 6);
        token18 = new MockERC20("Token18", "TK18", 18);
    }

    // ==================== DecimalNormalization Tests ====================

    function testScaleDecimalsZero() public pure {
        assertEq(DecimalNormalization.scaleDecimals(100, 0), 100);
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

    /// forge-config: default.allow_internal_expect_revert = true
    function testNormalizeTokenAmountRevertMoreDecimals() public {
        // Test when amount decimals (8) are greater than token decimals (6)
        vm.expectRevert("DecimalNormalization: amount decimals must be less than or equal to token decimals");
        DecimalNormalization.normalizeTokenAmount("100.12345678", 6);
    }

    function testNormalizeTokenAmountSmallDecimal() public pure {
        // Test with small decimal amount for token with 6 decimals
        uint256 amount = DecimalNormalization.normalizeTokenAmount("0.00001", 6);
        assertEq(amount, 10); // 0.00001 * 10^6 = 10

        // Test with small decimal amount for token with 18 decimals
        amount = DecimalNormalization.normalizeTokenAmount("0.00001", 18);
        assertEq(amount, 10 * 10 ** 12); // 0.00001 * 10^18 = 10 * 10^12 = 10000000000000
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testNormalizeTokenAmountRevertZeroAmount() public {
        vm.expectRevert("DecimalNormalization: amount must be non-zero");
        DecimalNormalization.normalizeTokenAmount("0.0", 6);
    }

    // ==================== Integration Tests ====================

    function testNormalizeTokenAmountWithRealTokens() public view {
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

    // ==================== Fuzz Tests ====================

    function testFuzz_ScaleDecimals(uint256 amount, uint8 decimals) public pure {
        // Bound amount to avoid overflow
        amount = bound(amount, 0, type(uint256).max / (10 ** 18));
        // Bound decimals to a reasonable range (0-18)
        decimals = uint8(bound(decimals, 0, 18));

        uint256 scaled = DecimalNormalization.scaleDecimals(amount, decimals);
        assertEq(scaled, amount * (10 ** uint256(decimals)));
    }

    function testFuzz_NormalizeTokenAmount(uint256 amount, uint8 amountDecimals, uint8 tokenDecimals) public pure {
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

        uint256 tokenAmount = DecimalNormalization.normalizeTokenAmount(amountStr, tokenDecimals);

        // Calculate expected amount
        uint256 expectedAmount = amount * (10 ** (tokenDecimals - amountDecimals));

        assertEq(tokenAmount, expectedAmount);
    }

    // ==================== Decimal Parsing Tests ====================

    function testParseDecimalsWholeNumber() public pure {
        (uint256 amount, uint8 decimals) = DecimalNormalization.parseDecimals("100");
        assertEq(amount, 100);
        assertEq(decimals, 0);
    }

    function testParseDecimalsZeroDecimalPart() public pure {
        (uint256 amount, uint8 decimals) = DecimalNormalization.parseDecimals("100.0");
        assertEq(amount, 100);
        assertEq(decimals, 0);

        (amount, decimals) = DecimalNormalization.parseDecimals("100.00");
        assertEq(amount, 100);
        assertEq(decimals, 0);
    }

    function testParseDecimalsNonZeroDecimalPart() public pure {
        (uint256 amount, uint8 decimals) = DecimalNormalization.parseDecimals("100.123");
        assertEq(amount, 100123);
        assertEq(decimals, 3);

        (amount, decimals) = DecimalNormalization.parseDecimals("100.000123");
        assertEq(amount, 100000123);
        assertEq(decimals, 6);
    }

    function testParseDecimalsMaxDecimals() public pure {
        (uint256 amount, uint8 decimals) = DecimalNormalization.parseDecimals("100.123456789012345678");
        assertEq(amount, 100123456789012345678);
        assertEq(decimals, 18);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testParseDecimalsRevertTooManyDecimals() public {
        vm.expectRevert("DecimalNormalization: decimals must be less than or equal to 18");
        DecimalNormalization.parseDecimals("100.1234567890123456789"); // 19 decimal places
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testValidAndInvalidAmountFormats() public {
        // Test valid formats through parseDecimals which calls validateAmountFormat
        DecimalNormalization.parseDecimals("100");
        DecimalNormalization.parseDecimals("100.123");

        // Test invalid formats
        vm.expectRevert("DecimalNormalization: decimals cannot be 0");
        DecimalNormalization.parseDecimals("100.");

        vm.expectRevert("DecimalNormalization: invalid amount");
        DecimalNormalization.parseDecimals("100.123.456");
    }

    function testParseDecimalsZeroValue() public pure {
        // Test with zero whole part and non-zero decimal part
        (uint256 amount, uint8 decimals) = DecimalNormalization.parseDecimals("0.123456789012345678");
        assertEq(amount, 123456789012345678);
        assertEq(decimals, 18);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testParseDecimalsRevertZeroAmount() public {
        vm.expectRevert("DecimalNormalization: amount must be non-zero");
        DecimalNormalization.parseDecimals("0.0"); // Zero amount

        vm.expectRevert("DecimalNormalization: amount must be non-zero");
        DecimalNormalization.parseDecimals("0.00000"); // Zero amount with multiple zeros
    }

    // ==================== AmountComponents Tests ====================

    function testParseAmountComponents() public pure {
        // Test whole number
        DecimalNormalization.AmountComponents memory components = DecimalNormalization.parseAmountComponents("100");
        assertEq(components.integer, 100);
        assertEq(components.decimal, 0);
        assertEq(components.decimalPlaces, 0);
        assertEq(components.hasDecimals, false);

        // Test with decimal part
        components = DecimalNormalization.parseAmountComponents("100.123");
        assertEq(components.integer, 100);
        assertEq(components.decimal, 123);
        assertEq(components.decimalPlaces, 3);
        assertEq(components.hasDecimals, true);

        // Test with zero whole part
        components = DecimalNormalization.parseAmountComponents("0.123");
        assertEq(components.integer, 0);
        assertEq(components.decimal, 123);
        assertEq(components.decimalPlaces, 3);
        assertEq(components.hasDecimals, true);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testParseAmountComponentsRevertInvalidFormat() public {
        // Test with multiple decimal points
        vm.expectRevert("DecimalNormalization: invalid amount");
        DecimalNormalization.parseAmountComponents("100.123.456");

        // Test with empty decimal part
        vm.expectRevert("DecimalNormalization: decimals cannot be 0");
        DecimalNormalization.parseAmountComponents("100.");

        // Test with too many decimals
        vm.expectRevert("DecimalNormalization: decimals must be less than or equal to 18");
        DecimalNormalization.parseAmountComponents("100.1234567890123456789"); // 19 decimal places
    }

    // ==================== isNonZeroAmount Tests ====================

    function testIsNonZeroAmount() public pure {
        // Test with non-zero whole part
        bool result = DecimalNormalization.isNonZeroAmount(100, 0);
        assertEq(result, true);

        // Test with non-zero decimal part
        result = DecimalNormalization.isNonZeroAmount(0, 123);
        assertEq(result, true);

        // Test with both parts non-zero
        result = DecimalNormalization.isNonZeroAmount(100, 123);
        assertEq(result, true);

        // Test with both parts zero
        result = DecimalNormalization.isNonZeroAmount(0, 0);
        assertEq(result, false);
    }
}
