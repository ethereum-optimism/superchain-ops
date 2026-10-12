// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {SetReviewPeriodDelays} from "src/template/SetReviewPeriodDelays.sol";

/// @notice Exposes the template's internal `[delays]` parser and bounds check so they can be tested
///         without a fork. These are the only parts of the template that run before a Safe simulation.
contract SetReviewPeriodDelaysHarness is SetReviewPeriodDelays {
    function parseDelays(string memory tomlContent) external view returns (Delays memory) {
        return _parseDelays(tomlContent);
    }

    function requireInBounds(uint256 value, uint256 min, uint256 max, string memory name) external pure {
        _requireInBounds(value, min, max, name);
    }
}

/// @title SetReviewPeriodDelaysTomlTest
/// @notice Pins the contract claimed by `SetReviewPeriodDelays._parseDelays`: both `[delays]` keys are
///         optional and an absent key leaves its `set*` flag false, so that delay is not touched.
contract SetReviewPeriodDelaysTomlTest is Test {
    SetReviewPeriodDelaysHarness internal harness;

    function setUp() public {
        harness = new SetReviewPeriodDelaysHarness();
    }

    /// @notice Both keys present: both flags are set and both values parsed.
    function test_parseDelays_allKeys() public view {
        SetReviewPeriodDelays.Delays memory delays = harness.parseDelays(
            "[delays]\nproofMaturityDelaySeconds = 172800\ndisputeGameFinalityDelaySeconds = 86400"
        );
        assertTrue(delays.setProofMaturity);
        assertTrue(delays.setFinalityDelay);
        assertEq(delays.proofMaturityDelaySeconds, 172800);
        assertEq(delays.disputeGameFinalityDelaySeconds, 86400);
    }

    /// @notice A single key only sets its own flag; the other delay stays untouched.
    function test_parseDelays_singleKey() public view {
        SetReviewPeriodDelays.Delays memory delays =
            harness.parseDelays("[delays]\ndisputeGameFinalityDelaySeconds = 86400");
        assertFalse(delays.setProofMaturity);
        assertTrue(delays.setFinalityDelay);
        assertEq(delays.proofMaturityDelaySeconds, 0);
        assertEq(delays.disputeGameFinalityDelaySeconds, 86400);
    }

    /// @notice No `[delays]` section at all: nothing is set. `_templateSetup` then rejects the task.
    function test_parseDelays_noSection() public view {
        SetReviewPeriodDelays.Delays memory delays = harness.parseDelays("templateName = \"SetReviewPeriodDelays\"");
        assertFalse(delays.setProofMaturity);
        assertFalse(delays.setFinalityDelay);
    }

    /// @notice The bounds check is inclusive and names the offending key in its message.
    function test_requireInBounds_boundsInclusive() public view {
        harness.requireInBounds(86400, 86400, 604800, "proofMaturityDelaySeconds");
        harness.requireInBounds(604800, 86400, 604800, "proofMaturityDelaySeconds");
    }

    function test_requireInBounds_belowMinReverts() public {
        vm.expectRevert(bytes("SetReviewPeriodDelays: proofMaturityDelaySeconds outside the contract's [min, max]"));
        harness.requireInBounds(86399, 86400, 604800, "proofMaturityDelaySeconds");
    }

    function test_requireInBounds_aboveMaxReverts() public {
        vm.expectRevert(
            bytes("SetReviewPeriodDelays: disputeGameFinalityDelaySeconds outside the contract's [min, max]")
        );
        harness.requireInBounds(302401, 43200, 302400, "disputeGameFinalityDelaySeconds");
    }
}
