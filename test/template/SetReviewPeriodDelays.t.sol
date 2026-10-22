// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";

import {AddressRegistry} from "src/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {
    SetReviewPeriodDelays,
    IOptimismPortal2,
    IAnchorStateRegistry,
    IDelayedWETH
} from "src/template/SetReviewPeriodDelays.sol";
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

    function validateTemplate() external view {
        _validate(new VmSafe.AccountAccess[](0), new Action[](0), address(0));
    }

    function parseDelays(string memory tomlContent) external view returns (Delays memory) {
        return _parseDelays(tomlContent);
    }

    function requireInBounds(uint256 value, uint256 min, uint256 max, string memory name) external pure {
        _requireInBounds(value, min, max, name);
    }
}

/// @title SetReviewPeriodDelaysTest
/// @notice Runs the template's setup, build and validation against local mocks: two chains that share an
///         AnchorStateRegistry and a DelayedWETH, as the chains of an interop set do. Also pins the
///         contract claimed by `SetReviewPeriodDelays._parseDelays` (every `[delays]` key is optional and
///         an absent key leaves its `set*` flag false, so that delay is not touched) and the bounds check.
contract SetReviewPeriodDelaysTest is Test {
    string constant TESTING_DIRECTORY = "set-review-period-delays-testing";
    uint256 constant CHAIN_A = 1001;
    uint256 constant CHAIN_B = 1002;

    uint256 constant PROOF_MATURITY = 172800;
    uint256 constant FINALITY_DELAY = 86400;
    uint256 constant WITHDRAWAL_DELAY = 259200;
    string constant ALL_KEYS =
        "proofMaturityDelaySeconds = 172800\ndisputeGameFinalityDelaySeconds = 86400\nwithdrawalDelaySeconds = 259200";

    address internal rootSafe = makeAddr("rootSafe");

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
    ///         Tests run in parallel and `randomBytes` repeats across them, so the running test's selector
    ///         is the salt that keeps each test on its own file.
    function _config(string memory delays) internal returns (string memory) {
        return MultisigTaskTestHelper.createTempTomlFile(
            string.concat("[delays]\n", delays, "\n"), TESTING_DIRECTORY, vm.toString(msg.sig)
        );
    }

    /// @notice Runs the template's setup on a config holding `delays`, then builds the task's actions
    ///         the way the framework does: calls made from the pranked root safe are recorded and the
    ///         state they changed is rolled back.
    function _setupAndBuild(string memory delays) internal returns (Action[] memory actions) {
        string memory path = _config(delays);
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
        actions = harness.build(rootSafe);
    }

    /// @notice Replays the built actions against the mocks, standing in for the Safe execution.
    function _execute(Action[] memory actions) internal {
        for (uint256 i = 0; i < actions.length; i++) {
            (bool ok,) = actions[i].target.call(actions[i].arguments);
            require(ok, "SetReviewPeriodDelaysTest: action reverted");
        }
    }

    function _assertAction(Action memory action, address target, bytes memory data) internal pure {
        assertEq(action.target, target);
        assertEq(action.arguments, data);
        assertEq(action.value, 0);
    }

    /// @notice Puts both portals behind one ETHLockbox, as the portals of an interop set are.
    function _shareLockbox() internal {
        address lockbox = makeAddr("lockbox");
        portalA.setEthLockbox(lockbox);
        portalB.setEthLockbox(lockbox);
    }

    ///////////////////// Parser and bounds //////////////////////

    /// @notice All three keys present: every flag is set and every value parsed.
    function test_parseDelays_allKeys() public view {
        SetReviewPeriodDelays.Delays memory delays = harness.parseDelays(string.concat("[delays]\n", ALL_KEYS));
        assertTrue(delays.setProofMaturity);
        assertTrue(delays.setFinalityDelay);
        assertTrue(delays.setWithdrawalDelay);
        assertEq(delays.proofMaturityDelaySeconds, PROOF_MATURITY);
        assertEq(delays.disputeGameFinalityDelaySeconds, FINALITY_DELAY);
        assertEq(delays.withdrawalDelaySeconds, WITHDRAWAL_DELAY);
    }

    /// @notice A single key only sets its own flag; the other delays stay untouched.
    function test_parseDelays_singleKey() public view {
        SetReviewPeriodDelays.Delays memory delays = harness.parseDelays("[delays]\nwithdrawalDelaySeconds = 259200");
        assertFalse(delays.setProofMaturity);
        assertFalse(delays.setFinalityDelay);
        assertTrue(delays.setWithdrawalDelay);
        assertEq(delays.proofMaturityDelaySeconds, 0);
        assertEq(delays.disputeGameFinalityDelaySeconds, 0);
        assertEq(delays.withdrawalDelaySeconds, WITHDRAWAL_DELAY);
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

    /////////////////////// Template setup ///////////////////////

    /// @notice The task is rejected while any included portal is paused, since a delay must not change
    ///         during a pause. The second chain is paused, so the first chain's checks run and pass first.
    function test_templateSetup_pausedPortalReverts() public {
        string memory path = _config("proofMaturityDelaySeconds = 172800");
        portalB.setPaused(true);

        vm.expectRevert(bytes("SetReviewPeriodDelays: chain-b is paused"));
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice An empty `[delays]` section configures nothing, so the task is rejected.
    function test_templateSetup_noKeysReverts() public {
        string memory path = _config("");

        vm.expectRevert(bytes("SetReviewPeriodDelays: no key set under [delays]"));
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice A contract from before its setter shipped is rejected at setup, naming the chain, contract
    ///         and version. Only the contracts the configured keys touch are checked.
    function test_templateSetup_oldPortalVersionReverts() public {
        portalB.setVersion("5.11.0");
        string memory path = _config("proofMaturityDelaySeconds = 172800");

        vm.expectRevert(bytes("SetReviewPeriodDelays: chain-b OptimismPortal2 5.11.0 is below 6.0.0"));
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    function test_templateSetup_oldAnchorStateRegistryVersionReverts() public {
        asr.setVersion("4.0.0");
        string memory path = _config("disputeGameFinalityDelaySeconds = 86400");

        vm.expectRevert(bytes("SetReviewPeriodDelays: chain-a AnchorStateRegistry 4.0.0 is below 5.0.0"));
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    function test_templateSetup_oldDelayedWETHVersionReverts() public {
        weth.setVersion("2.0.0");
        string memory path = _config("withdrawalDelaySeconds = 259200");

        vm.expectRevert(bytes("SetReviewPeriodDelays: chain-a DelayedWETH 2.0.0 is below 3.0.0"));
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice An old contract is ignored when its key is not configured.
    function test_templateSetup_oldVersionUnconfiguredKeyIgnored() public {
        portalA.setVersion("5.11.0");
        portalB.setVersion("5.11.0");
        Action[] memory actions = _setupAndBuild("withdrawalDelaySeconds = 259200");

        assertEq(actions.length, 1);
    }

    /// @notice A configured value outside the contract's bounds is rejected at setup, before any build.
    function test_templateSetup_outOfBoundsReverts() public {
        string memory path = _config("proofMaturityDelaySeconds = 604801");

        vm.expectRevert(bytes("SetReviewPeriodDelays: proofMaturityDelaySeconds outside the contract's [min, max]"));
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice The DelayedWETH delay cannot be set on a chain whose SystemConfig has no DelayedWETH pointer.
    function test_templateSetup_noDelayedWETHReverts() public {
        MockSystemConfig(registry.getAddress("SystemConfigProxy", CHAIN_A)).setDelayedWETH(address(0));
        string memory path = _config("withdrawalDelaySeconds = 259200");

        vm.expectRevert(bytes("SetReviewPeriodDelays: SystemConfig.delayedWETH() is zero"));
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice Every configured value already matches on-chain, so the task is rejected as a no-op.
    function test_templateSetup_allValuesMatchReverts() public {
        portalA.setProofMaturityDelaySeconds(PROOF_MATURITY);
        portalB.setProofMaturityDelaySeconds(PROOF_MATURITY);
        asr.setDisputeGameFinalityDelaySeconds(FINALITY_DELAY);
        weth.setDelay(WITHDRAWAL_DELAY);
        string memory path = _config(ALL_KEYS);

        vm.expectRevert(bytes("SetReviewPeriodDelays: no-op (all configured delays already match on-chain values)"));
        harness.templateSetup(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /////////////////////////// Build ////////////////////////////

    /// @notice Two chains sharing an ASR and a DelayedWETH: one portal call per chain and one call per
    ///         shared contract. After execution every configured value reads back and validation passes.
    function test_build_sharedTargetsCalledOnce() public {
        Action[] memory actions = _setupAndBuild(ALL_KEYS);

        assertEq(actions.length, 4);
        _assertAction(
            actions[0],
            address(portalA),
            abi.encodeCall(IOptimismPortal2.setProofMaturityDelaySeconds, (PROOF_MATURITY))
        );
        _assertAction(
            actions[1],
            address(portalB),
            abi.encodeCall(IOptimismPortal2.setProofMaturityDelaySeconds, (PROOF_MATURITY))
        );
        _assertAction(
            actions[2],
            address(asr),
            abi.encodeCall(IAnchorStateRegistry.setDisputeGameFinalityDelaySeconds, (FINALITY_DELAY))
        );
        _assertAction(actions[3], address(weth), abi.encodeCall(IDelayedWETH.setDelay, (WITHDRAWAL_DELAY)));

        _execute(actions);
        harness.validateTemplate();
        assertEq(portalA.proofMaturityDelaySeconds(), PROOF_MATURITY);
        assertEq(portalB.proofMaturityDelaySeconds(), PROOF_MATURITY);
        assertEq(asr.disputeGameFinalityDelaySeconds(), FINALITY_DELAY);
        assertEq(weth.delay(), WITHDRAWAL_DELAY);
    }

    /// @notice A portal that already holds the requested delay is skipped; the other targets are still set.
    function test_build_portalAlreadySetSkipped() public {
        portalA.setProofMaturityDelaySeconds(PROOF_MATURITY);
        Action[] memory actions = _setupAndBuild(ALL_KEYS);

        assertEq(actions.length, 3);
        _assertAction(
            actions[0],
            address(portalB),
            abi.encodeCall(IOptimismPortal2.setProofMaturityDelaySeconds, (PROOF_MATURITY))
        );
        _assertAction(
            actions[1],
            address(asr),
            abi.encodeCall(IAnchorStateRegistry.setDisputeGameFinalityDelaySeconds, (FINALITY_DELAY))
        );
        _assertAction(actions[2], address(weth), abi.encodeCall(IDelayedWETH.setDelay, (WITHDRAWAL_DELAY)));

        _execute(actions);
        harness.validateTemplate();
    }

    /// @notice Only one key configured: a single call, and the other two delays keep their values.
    function test_build_singleKeyLeavesOthersUnchanged() public {
        uint256 proofMaturityBefore = portalA.proofMaturityDelaySeconds();
        uint256 finalityDelayBefore = asr.disputeGameFinalityDelaySeconds();
        Action[] memory actions = _setupAndBuild("withdrawalDelaySeconds = 259200");

        assertEq(actions.length, 1);
        _assertAction(actions[0], address(weth), abi.encodeCall(IDelayedWETH.setDelay, (WITHDRAWAL_DELAY)));

        _execute(actions);
        harness.validateTemplate();
        assertEq(portalA.proofMaturityDelaySeconds(), proofMaturityBefore);
        assertEq(portalB.proofMaturityDelaySeconds(), proofMaturityBefore);
        assertEq(asr.disputeGameFinalityDelaySeconds(), finalityDelayBefore);
        assertEq(weth.delay(), WITHDRAWAL_DELAY);
    }

    ////////////////////////// Validate //////////////////////////

    /// @notice A configured value that does not read back after execution fails validation for that field.
    function test_validate_proofMaturityMismatchReverts() public {
        _execute(_setupAndBuild(ALL_KEYS));
        portalB.setProofMaturityDelaySeconds(PROOF_MATURITY + 1);

        vm.expectRevert(bytes("SetReviewPeriodDelays: proofMaturityDelaySeconds mismatch"));
        harness.validateTemplate();
    }

    function test_validate_finalityDelayMismatchReverts() public {
        _execute(_setupAndBuild(ALL_KEYS));
        asr.setDisputeGameFinalityDelaySeconds(FINALITY_DELAY + 1);

        vm.expectRevert(bytes("SetReviewPeriodDelays: disputeGameFinalityDelaySeconds mismatch"));
        harness.validateTemplate();
    }

    function test_validate_withdrawalDelayMismatchReverts() public {
        _execute(_setupAndBuild(ALL_KEYS));
        weth.setDelay(WITHDRAWAL_DELAY + 1);

        vm.expectRevert(bytes("SetReviewPeriodDelays: withdrawalDelaySeconds mismatch"));
        harness.validateTemplate();
    }

    /// @notice Portals that share an ETHLockbox must hold the same proof maturity. The key is configured,
    ///         so both portals end at the same value and the set check passes.
    function test_validate_sharedLockboxUniformPasses() public {
        _shareLockbox();
        _execute(_setupAndBuild(ALL_KEYS));
        harness.validateTemplate();
    }

    /// @notice Proof maturity is not configured, so the per-chain check skips it, but the portals share a
    ///         lockbox and hold different values: the set check rejects the task.
    function test_validate_sharedLockboxMismatchReverts() public {
        _shareLockbox();
        portalA.setProofMaturityDelaySeconds(PROOF_MATURITY);
        _execute(_setupAndBuild("disputeGameFinalityDelaySeconds = 86400"));

        vm.expectRevert(
            bytes("SetReviewPeriodDelays: portals in the same set have different proofMaturityDelaySeconds")
        );
        harness.validateTemplate();
    }

    /// @notice The set check also runs when the task only touches the DelayedWETH delay.
    function test_validate_sharedLockboxMismatchWithdrawalDelayOnlyReverts() public {
        _shareLockbox();
        portalA.setProofMaturityDelaySeconds(PROOF_MATURITY);
        _execute(_setupAndBuild("withdrawalDelaySeconds = 259200"));

        vm.expectRevert(
            bytes("SetReviewPeriodDelays: portals in the same set have different proofMaturityDelaySeconds")
        );
        harness.validateTemplate();
    }

    /// @notice Portals behind different lockboxes belong to different sets, so they may keep different
    ///         proof maturities.
    function test_validate_differentLockboxesKeepDifferentProofMaturity() public {
        portalA.setEthLockbox(makeAddr("lockboxA"));
        portalB.setEthLockbox(makeAddr("lockboxB"));
        portalA.setProofMaturityDelaySeconds(PROOF_MATURITY);
        _execute(_setupAndBuild("disputeGameFinalityDelaySeconds = 86400"));

        harness.validateTemplate();
        assertTrue(portalA.proofMaturityDelaySeconds() != portalB.proofMaturityDelaySeconds());
    }
}
