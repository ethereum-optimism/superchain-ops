// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {AddressRegistry} from "src/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {SetReviewPeriodDelays} from "src/template/SetReviewPeriodDelays.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";
import {MockSuperchainAddressRegistry} from "test/template/mock/MockSuperchainAddressRegistry.sol";
import {MockOptimismPortal2} from "test/template/mock/MockOptimismPortal2.sol";
import {MockAnchorStateRegistry} from "test/template/mock/MockAnchorStateRegistry.sol";
import {MockDelayedWETH} from "test/template/mock/MockDelayedWETH.sol";
import {MockSystemConfig} from "test/template/mock/MockSystemConfig.sol";

/// @notice Exposes the template's internals and lets the tests inject a registry, so the template runs
///         against local mocks instead of a fork.
contract SetReviewPeriodDelaysHarness is SetReviewPeriodDelays {
    function setRegistry(address registry) external {
        superchainAddrRegistry = SuperchainAddressRegistry(registry);
        addrRegistry = AddressRegistry.wrap(registry);
    }

    function templateSetup(string memory taskConfigFilePath) external {
        _templateSetup(taskConfigFilePath, address(0));
    }

    function parseDelays(string memory tomlContent) external view returns (Delays memory) {
        return _parseDelays(tomlContent);
    }

    function requireInBounds(uint256 value, uint256 min, uint256 max, string memory name) external pure {
        _requireInBounds(value, min, max, name);
    }
}

/// @title SetReviewPeriodDelaysTest
/// @notice Runs the template against local mocks: two chains that share an AnchorStateRegistry and a
///         DelayedWETH, as the chains of an interop set do. Also pins the contract claimed by
///         `SetReviewPeriodDelays._parseDelays` (every `[delays]` key is optional and an absent key leaves
///         its `set*` flag false, so that delay is not touched) and the bounds check.
contract SetReviewPeriodDelaysTest is Test {
    string constant TESTING_DIRECTORY = "set-review-period-delays-testing";
    uint256 constant CHAIN_A = 1001;
    uint256 constant CHAIN_B = 1002;

    SetReviewPeriodDelaysHarness internal harness;
    MockSuperchainAddressRegistry internal registry;
    MockOptimismPortal2 internal portalA;
    MockOptimismPortal2 internal portalB;
    MockAnchorStateRegistry internal asr;
    MockDelayedWETH internal weth;

    function setUp() public {
        harness = new SetReviewPeriodDelaysHarness();
        registry = new MockSuperchainAddressRegistry();
        portalA = new MockOptimismPortal2();
        portalB = new MockOptimismPortal2();
        asr = new MockAnchorStateRegistry();
        weth = new MockDelayedWETH();

        _addChain(CHAIN_A, "chain-a", portalA);
        _addChain(CHAIN_B, "chain-b", portalB);
        harness.setRegistry(address(registry));
    }

    /// @notice Registers a chain with its own portal and SystemConfig, sharing the ASR and DelayedWETH.
    function _addChain(uint256 chainId, string memory name, MockOptimismPortal2 portal) internal {
        registry.addChain(chainId, name);
        registry.set("OptimismPortalProxy", chainId, address(portal));
        registry.set("AnchorStateRegistryProxy", chainId, address(asr));
        registry.set("SystemConfigProxy", chainId, address(new MockSystemConfig(address(weth))));
    }

    /// @notice Writes a task config whose `[delays]` section holds `delays` and returns its path.
    function _config(string memory delays) internal returns (string memory) {
        return
            MultisigTaskTestHelper.createTempTomlFile(
                string.concat("[delays]\n", delays, "\n"), TESTING_DIRECTORY, delays
            );
    }

    /// @notice All three keys present: every flag is set and every value parsed.
    function test_parseDelays_allKeys() public view {
        SetReviewPeriodDelays.Delays memory delays = harness.parseDelays(
            "[delays]\nproofMaturityDelaySeconds = 172800\ndisputeGameFinalityDelaySeconds = 86400\nwithdrawalDelaySeconds = 259200"
        );
        assertTrue(delays.setProofMaturity);
        assertTrue(delays.setFinalityDelay);
        assertTrue(delays.setWithdrawalDelay);
        assertEq(delays.proofMaturityDelaySeconds, 172800);
        assertEq(delays.disputeGameFinalityDelaySeconds, 86400);
        assertEq(delays.withdrawalDelaySeconds, 259200);
    }

    /// @notice A single key only sets its own flag; the other delays stay untouched.
    function test_parseDelays_singleKey() public view {
        SetReviewPeriodDelays.Delays memory delays = harness.parseDelays("[delays]\nwithdrawalDelaySeconds = 259200");
        assertFalse(delays.setProofMaturity);
        assertFalse(delays.setFinalityDelay);
        assertTrue(delays.setWithdrawalDelay);
        assertEq(delays.proofMaturityDelaySeconds, 0);
        assertEq(delays.disputeGameFinalityDelaySeconds, 0);
        assertEq(delays.withdrawalDelaySeconds, 259200);
    }

    /// @notice No `[delays]` section at all: nothing is set. `_templateSetup` then rejects the task.
    function test_parseDelays_noSection() public view {
        SetReviewPeriodDelays.Delays memory delays = harness.parseDelays("templateName = \"SetReviewPeriodDelays\"");
        assertFalse(delays.setProofMaturity);
        assertFalse(delays.setFinalityDelay);
        assertFalse(delays.setWithdrawalDelay);
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
        vm.expectRevert(bytes("SetReviewPeriodDelays: withdrawalDelaySeconds outside the contract's [min, max]"));
        harness.requireInBounds(604801, 43200, 604800, "withdrawalDelaySeconds");
    }

    /// @notice The task is rejected while any included portal is paused, since a delay must not change
    ///         during a pause. The second chain is paused, so the first chain's checks run and pass first.
    function test_templateSetup_pausedPortalReverts() public {
        string memory path = _config("proofMaturityDelaySeconds = 172800");
        portalB.setPaused(true);

        vm.expectRevert(bytes("SetReviewPeriodDelays: chain-b is paused"));
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
    }
}
