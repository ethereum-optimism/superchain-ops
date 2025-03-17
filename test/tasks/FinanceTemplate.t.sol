// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {FinanceTemplate} from "src/improvements/template/FinanceTemplate.sol";
import {MockERC20} from "lib/solady/test/utils/mocks/MockERC20.sol";

// Test contract for FinanceTemplate functions
contract FinanceTemplateUnitTest is Test {
    FinanceTemplate public template;
    MockERC20 public token6; // 6 decimals
    MockERC20 public token18; // 18 decimals

    function setUp() public {
        template = new FinanceTemplate();
        token6 = new MockERC20("Token6", "TK6", 6);
        token18 = new MockERC20("Token18", "TK18", 18);
    }

    // ==================== scaleDecimals Tests ====================

    function testScaleDecimalsZero() public view {
        assertEq(template.scaleDecimals(100, 0), 100);
    }

    function testScaleDecimalsStandard() public view {
        assertEq(template.scaleDecimals(100, 6), 100 * 10 ** 6);
        assertEq(template.scaleDecimals(100, 8), 100 * 10 ** 8);
        assertEq(template.scaleDecimals(100, 18), 100 * 10 ** 18);
    }

    function testScaleDecimalsLarge() public view {
        // Test with a large amount but still within uint256 range
        uint256 largeAmount = 10 ** 20;
        assertEq(template.scaleDecimals(largeAmount, 10), largeAmount * 10 ** 10);
    }

    function testFuzz_ScaleDecimals(uint256 amount, uint8 decimals) public view {
        // Bound amount to avoid overflow
        amount = bound(amount, 0, type(uint256).max / (10 ** 18));
        // Bound decimals to a reasonable range (0-18)
        decimals = uint8(bound(decimals, 0, 18));

        uint256 scaled = template.scaleDecimals(amount, decimals);
        assertEq(scaled, amount * (10 ** uint256(decimals)));
    }

    // ==================== parseDecimals Tests ====================

    function testParseDecimalsWholeNumber() public view {
        (uint256 amount, uint8 decimals) = template.parseDecimals("100");
        assertEq(amount, 100);
        assertEq(decimals, 0);
    }

    function testParseDecimalsZeroDecimalPart() public view {
        (uint256 amount, uint8 decimals) = template.parseDecimals("100.0");
        assertEq(amount, 100);
        assertEq(decimals, 0);

        (amount, decimals) = template.parseDecimals("100.00");
        assertEq(amount, 100);
        assertEq(decimals, 0);
    }

    function testParseDecimalsNonZeroDecimalPart() public view {
        (uint256 amount, uint8 decimals) = template.parseDecimals("100.123");
        assertEq(amount, 100123);
        assertEq(decimals, 3);

        (amount, decimals) = template.parseDecimals("100.000123");
        assertEq(amount, 100000123);
        assertEq(decimals, 6);
    }

    function testParseDecimalsMaxDecimals() public view {
        (uint256 amount, uint8 decimals) = template.parseDecimals("100.123456789012345678");
        assertEq(amount, 100123456789012345678);
        assertEq(decimals, 18);
    }

    function testParseDecimalsRevertNoDecimals() public {
        vm.expectRevert("decimals must be less than or equal to 18");
        template.parseDecimals("100.1234567890123456789"); // 19 decimal places
    }

    // This test is no longer relevant with the new implementation
    // as we now allow decimal-only values as long as they're non-zero

    // ==================== Helper Function Tests ====================

    function testValidateAmountFormat() public {
        // Test valid formats through parseDecimals which calls validateAmountFormat
        template.parseDecimals("100");
        template.parseDecimals("100.123");

        // Test invalid formats
        vm.expectRevert("decimals cannot be 0");
        template.parseDecimals("100.");

        vm.expectRevert("invalid amount");
        template.parseDecimals("100.123.456");
    }

    function testIsNonZeroAmount() public view {
        // These tests indirectly test isNonZeroAmount through parseDecimals

        // Whole part zero, decimal part non-zero
        (uint256 amount, uint8 decimals) = template.parseDecimals("0.123");
        assertEq(amount, 123);
        assertEq(decimals, 3);

        // Whole part non-zero, decimal part zero
        (amount, decimals) = template.parseDecimals("123.0");
        assertEq(amount, 123);
        assertEq(decimals, 0);

        // Both parts non-zero
        (amount, decimals) = template.parseDecimals("123.456");
        assertEq(amount, 123456);
        assertEq(decimals, 3);
    }

    function testCalculateFinalAmount() public view {
        // These tests indirectly test calculateFinalAmount through parseDecimals

        // Test with whole number and decimals
        (uint256 amount,) = template.parseDecimals("123.456");
        assertEq(amount, 123456);

        // Test with only decimals
        (amount,) = template.parseDecimals("0.123");
        assertEq(amount, 123);
    }

    function testParseDecimalsZeroValue() public view {
        // Test with zero whole part and non-zero decimal part
        (uint256 amount, uint8 decimals) = template.parseDecimals("0.123456789012345678");
        assertEq(amount, 123456789012345678);
        assertEq(decimals, 18);
    }

    function testParseDecimalsRevertZeroDecimals() public {
        vm.expectRevert("decimals cannot be 0");
        template.parseDecimals("100."); // Decimal point with no digits after
    }

    function testParseDecimalsRevertInvalidFormat() public {
        vm.expectRevert("invalid amount");
        template.parseDecimals("100.123.456"); // Multiple decimal points
    }

    function testParseDecimalsRevertZeroAmount() public {
        vm.expectRevert("amount must be non-zero");
        template.parseDecimals("0.0"); // Zero amount

        vm.expectRevert("amount must be non-zero");
        template.parseDecimals("0.00000"); // Zero amount with multiple zeros
    }

    function testFuzz_ParseDecimals(uint256 wholeNumber, uint256 decimalPart, uint8 decimalPlaces) public view {
        // Bound inputs to reasonable ranges
        wholeNumber = bound(wholeNumber, 0, 1000000);
        decimalPlaces = uint8(bound(decimalPlaces, 1, 18));

        // Ensure decimalPart has the right number of digits
        decimalPart = bound(decimalPart, 1, 10 ** decimalPlaces - 1);

        // Format the decimal string
        string memory decimalStr = vm.toString(decimalPart);
        // Pad with leading zeros if needed
        while (bytes(decimalStr).length < decimalPlaces) {
            decimalStr = string(abi.encodePacked("0", decimalStr));
        }

        string memory amountStr = string(abi.encodePacked(vm.toString(wholeNumber), ".", decimalStr));

        (uint256 parsedAmount, uint8 parsedDecimals) = template.parseDecimals(amountStr);

        // Verify the parsed result
        assertEq(parsedDecimals, decimalPlaces);

        // Calculate expected amount
        uint256 expectedAmount = wholeNumber * (10 ** decimalPlaces) + decimalPart;
        assertEq(parsedAmount, expectedAmount);
    }

    // ==================== getTokenAmount Tests ====================

    function testGetTokenAmountEqualDecimals() public view {
        // Test when amount decimals equal token decimals (6)
        uint256 amount = template.getTokenAmount("100.123456", address(token6));
        assertEq(amount, 100123456);
    }

    function testGetTokenAmountLessDecimals() public view {
        // Test when amount decimals (3) are less than token decimals (6)
        uint256 amount = template.getTokenAmount("100.123", address(token6));
        assertEq(amount, 100123000); // 100.123 * 10^(6-3) = 100.123 * 10^3 = 100123000

        // Test when amount decimals (0) are less than token decimals (18)
        amount = template.getTokenAmount("100", address(token18));
        assertEq(amount, 100 * 10 ** 18); // 100 * 10^(18-0) = 100 * 10^18
    }

    function testGetTokenAmountRevertMoreDecimals() public {
        // Test when amount decimals (8) are greater than token decimals (6)
        vm.expectRevert("amount decimals must be less than or equal to token decimals");
        template.getTokenAmount("100.12345678", address(token6));
    }

    function testGetTokenAmountSmallDecimal() public view {
        // Test with small decimal amount for token with 6 decimals
        uint256 amount = template.getTokenAmount("0.00001", address(token6));
        assertEq(amount, 10); // 0.00001 * 10^6 = 10

        // Test with small decimal amount for token with 18 decimals
        amount = template.getTokenAmount("0.00001", address(token18));
        assertEq(amount, 10 * 10 ** 12); // 0.00001 * 10^18 = 10 * 10^12 = 10000000000000
    }

    function testGetTokenAmountRevertZeroAmount() public {
        vm.expectRevert("amount must be non-zero");
        template.getTokenAmount("0.0", address(token6));
    }

    function testFuzz_GetTokenAmount(uint256 amount, uint8 amountDecimals, uint8 tokenDecimals) public {
        // Bound inputs to reasonable ranges
        amount = bound(amount, 1, 1000000);
        amountDecimals = uint8(bound(amountDecimals, 0, 18));
        tokenDecimals = uint8(bound(tokenDecimals, amountDecimals, 18)); // Ensure tokenDecimals >= amountDecimals

        // Create a token with the specified decimals
        MockERC20 token = new MockERC20("TestToken", "TT", tokenDecimals);

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

        uint256 tokenAmount = template.getTokenAmount(amountStr, address(token));

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
