// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Forge
import {Test} from "forge-std/Test.sol";

// Libraries
import {BytecodeComparison} from "src/libraries/BytecodeComparison.sol";

contract MockContract {
    uint256 public immutable VALUE;

    constructor(uint256 _value) {
        VALUE = _value;
    }
}

/// @notice Library to expose the internal functions, to avoid tests stopping after hitting an expected revert.
/// https://book.getfoundry.sh/cheatcodes/expect-revert
library BytecodeComparisonHarness {
    function compare(address _contractA, address _contractB, BytecodeComparison.Diff[] memory _allowed)
        external
        view
        returns (bool)
    {
        return BytecodeComparison.compare(_contractA, _contractB, _allowed);
    }

    function compare(bytes memory _bytecodeA, bytes memory _bytecodeB, BytecodeComparison.Diff[] memory _allowed)
        external
        pure
        returns (bool)
    {
        return BytecodeComparison.compare(_bytecodeA, _bytecodeB, _allowed);
    }
}

contract VeryDifferentContract {
    bytes public constant WOW =
        hex"00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF";
}

contract BytecodeComparison_compare_Test is Test {
    /// @notice Test that identical contracts match.
    function test_identicalBytecode_succeeds() public {
        MockContract contractA1 = new MockContract(100);
        MockContract contractA2 = new MockContract(100);

        BytecodeComparison.Diff[] memory allowed = new BytecodeComparison.Diff[](0);
        bool result = BytecodeComparison.compare(address(contractA1), address(contractA2), allowed);
        assertTrue(result, "Identical contracts should match");
    }

    /// @notice Test that different contracts with different bytecode lengths revert.
    function test_differentBytecode_reverts() public {
        MockContract contractA = new MockContract(100);
        VeryDifferentContract contractB = new VeryDifferentContract();

        BytecodeComparison.Diff[] memory allowed = new BytecodeComparison.Diff[](0);
        vm.expectRevert("BytecodeComparison: diff in bytecode length");
        BytecodeComparisonHarness.compare(address(contractA), address(contractB), allowed);
    }

    /// @notice Test that a single allowed diff matches.
    function test_allowedDiff_succeeds() public pure {
        // Create two different byte arrays with a known difference
        bytes memory bytecodeA = hex"0011223344556677";
        bytes memory bytecodeB = hex"0011FF3344556677";

        BytecodeComparison.Diff[] memory allowed = new BytecodeComparison.Diff[](1);
        allowed[0] = BytecodeComparison.Diff({start: 2, content: hex"FF"});

        bool result = BytecodeComparison.compare(bytecodeA, bytecodeB, allowed);
        assertTrue(result, "Should match with allowed diff");
    }

    /// @notice Test that an unallowed diff reverts.
    function test_unallowedDiff_reverts() public {
        bytes memory bytecodeA = hex"0011223344556677";
        bytes memory bytecodeB = hex"0011FF3344556677";

        BytecodeComparison.Diff[] memory allowed = new BytecodeComparison.Diff[](0);

        vm.expectRevert("BytecodeComparison: unexpected diff found at index:2, byte:0xff");
        BytecodeComparisonHarness.compare(bytecodeA, bytecodeB, allowed);
    }

    /// @notice Test that multiple allowed diffs match.
    function test_multipleAllowedDiffs_succeeds() public pure {
        bytes memory bytecodeA = hex"0011223344556677";
        bytes memory bytecodeB = hex"00FF22FF44556677";

        BytecodeComparison.Diff[] memory allowed = new BytecodeComparison.Diff[](2);
        allowed[0] = BytecodeComparison.Diff({start: 1, content: hex"FF"});
        allowed[1] = BytecodeComparison.Diff({start: 3, content: hex"FF"});

        bool result = BytecodeComparison.compare(bytecodeA, bytecodeB, allowed);
        assertTrue(result, "Should match with multiple allowed diffs");
    }

    /// @notice Test that consecutive diffs match.
    function test_consecutiveDiffs_succeeds() public pure {
        bytes memory bytecodeA = hex"0011223344556677";
        bytes memory bytecodeB = hex"00FFFF3344556677";

        BytecodeComparison.Diff[] memory allowed = new BytecodeComparison.Diff[](1);
        allowed[0] = BytecodeComparison.Diff({start: 1, content: hex"FFFF"});

        bool result = BytecodeComparison.compare(bytecodeA, bytecodeB, allowed);
        assertTrue(result, "Should match with consecutive diffs");
    }

    /// @notice Test that a wrong diff position reverts.
    function test_wrongDiffPosition_reverts() public {
        bytes memory bytecodeA = hex"0011223344556677";
        bytes memory bytecodeB = hex"0011FF3344556677";

        BytecodeComparison.Diff[] memory allowed = new BytecodeComparison.Diff[](1);
        allowed[0] = BytecodeComparison.Diff({
            start: 1, // Wrong position (actual diff is at position 2)
            content: hex"FF"
        });

        vm.expectRevert("BytecodeComparison: unexpected diff found at index:2, byte:0xff");
        BytecodeComparisonHarness.compare(bytecodeA, bytecodeB, allowed);
    }

    /// @notice Test that a wrong diff content reverts.
    function test_wrongDiffContent_reverts() public {
        bytes memory bytecodeA = hex"0011223344556677";
        bytes memory bytecodeB = hex"0011FF3344556677";

        BytecodeComparison.Diff[] memory allowed = new BytecodeComparison.Diff[](1);
        allowed[0] = BytecodeComparison.Diff({
            start: 2,
            content: hex"EE" // Wrong content (actual diff is FF)
        });

        vm.expectRevert("BytecodeComparison: unexpected diff found at index:2, byte:0xff");
        BytecodeComparisonHarness.compare(bytecodeA, bytecodeB, allowed);
    }
}
