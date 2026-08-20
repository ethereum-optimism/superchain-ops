// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {SetFeeVaultConfig} from "src/template/SetFeeVaultConfig.sol";

/// @notice Exposes the template's internal `.minWithdrawalAmounts` parser so the tests below
///         exercise the exact code path `_templateSetup` uses.
contract SetFeeVaultConfigHarness is SetFeeVaultConfig {
    function parseMinWithdrawalAmounts(string memory tomlContent) external pure returns (uint256[] memory) {
        return _parseMinWithdrawalAmounts(tomlContent);
    }
}

/// @title SetFeeVaultConfigTomlTest
/// @notice Pins the parsing behavior claimed in `SetFeeVaultConfig._parseMinWithdrawalAmounts`:
///         the typed (coercing) reader accepts bare integers, decimal strings, and a mix of both,
///         so minimums above TOML's int64 bound (~9.22 ETH) can be
///         written as strings, while a bare integer above int64.max fails the TOML parse loudly
///         at task setup instead of being silently truncated or wrapped.
contract SetFeeVaultConfigTomlTest is Test {
    uint256 internal constant FIVE_ETH = 5_000_000_000_000_000_000;
    uint256 internal constant TEN_ETH = 10_000_000_000_000_000_000;

    SetFeeVaultConfigHarness internal harness;

    function setUp() public {
        harness = new SetFeeVaultConfigHarness();
    }

    /// @notice Bare integers within the int64 range parse as-is (the eth/066 shape: 5 ETH fits).
    function test_parseMinWithdrawalAmounts_bareIntegers() public view {
        uint256[] memory parsed = harness.parseMinWithdrawalAmounts(
            "minWithdrawalAmounts = [5000000000000000000, 5000000000000000000, 5000000000000000000, 0]"
        );
        assertEq(parsed.length, 4);
        assertEq(parsed[0], FIVE_ETH);
        assertEq(parsed[1], FIVE_ETH);
        assertEq(parsed[2], FIVE_ETH);
        assertEq(parsed[3], 0);
    }

    /// @notice Values above int64.max (9223372036854775807, ~9.22 ETH in wei) must be written as
    ///         decimal strings; the typed reader coerces them to uint256.
    function test_parseMinWithdrawalAmounts_stringEncodedAboveInt64() public view {
        uint256[] memory parsed =
            harness.parseMinWithdrawalAmounts("minWithdrawalAmounts = [\"10000000000000000000\", \"0\"]");
        assertEq(parsed.length, 2);
        assertEq(parsed[0], TEN_ETH);
        assertGt(parsed[0], uint256(uint64(type(int64).max))); // not representable as a bare TOML integer
        assertEq(parsed[1], 0);
    }

    /// @notice String encoding covers the full uint256 range.
    function test_parseMinWithdrawalAmounts_uint256MaxViaString() public view {
        uint256[] memory parsed = harness.parseMinWithdrawalAmounts(
            "minWithdrawalAmounts = [\"115792089237316195423570985008687907853269984665640564039457584007913129639935\"]"
        );
        assertEq(parsed.length, 1);
        assertEq(parsed[0], type(uint256).max);
    }

    /// @notice Bare integers and strings can be mixed within one array.
    function test_parseMinWithdrawalAmounts_mixedBareAndString() public view {
        uint256[] memory parsed = harness.parseMinWithdrawalAmounts(
            "minWithdrawalAmounts = [\"10000000000000000000\", 5000000000000000000, 0]"
        );
        assertEq(parsed.length, 3);
        assertEq(parsed[0], TEN_ETH);
        assertEq(parsed[1], FIVE_ETH);
        assertEq(parsed[2], 0);
    }

    /// @notice A bare integer above int64.max is a TOML parse error: the cheatcode reverts at
    ///         setup ("number too large to fit in target type"), a config mistake fails loudly
    ///         and can never truncate into a wrong on-chain value.
    function test_parseMinWithdrawalAmounts_bareIntegerAboveInt64Reverts() public {
        // 10 ETH in wei, one above int64.max, and int64.max + 1 — all must fail identically.
        string[3] memory badConfigs = [
            "minWithdrawalAmounts = [10000000000000000000]",
            "minWithdrawalAmounts = [5000000000000000000, 10000000000000000000, 0]",
            "minWithdrawalAmounts = [9223372036854775808]"
        ];
        for (uint256 i; i < badConfigs.length; i++) {
            try harness.parseMinWithdrawalAmounts(badConfigs[i]) {
                revert("bare integer above int64.max must fail the TOML parse");
            } catch (bytes memory err) {
                assertTrue(
                    vm.contains(_revertReason(err), "number too large to fit in target type"),
                    "expected a TOML out-of-range parse error"
                );
            }
        }

        // int64.max itself is the largest bare integer TOML accepts.
        uint256[] memory parsed = harness.parseMinWithdrawalAmounts("minWithdrawalAmounts = [9223372036854775807]");
        assertEq(parsed[0], uint256(uint64(type(int64).max)));
    }

    /// @notice Decodes `<4-byte selector><abi.encode(string)>` revert data (the shape of both
    ///         `Error(string)` and forge's cheatcode errors) back into the message string.
    function _revertReason(bytes memory err) internal pure returns (string memory) {
        require(err.length >= 68, "revert data too short to carry a reason string");
        bytes memory payload = new bytes(err.length - 4);
        for (uint256 i; i < payload.length; i++) {
            payload[i] = err[i + 4];
        }
        return abi.decode(payload, (string));
    }
}
