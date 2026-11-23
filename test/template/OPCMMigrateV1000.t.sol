// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {
    OPCMMigrateV1000,
    IOPContractsManagerV1000,
    IOPContractsManagerStandardValidatorV1000,
    IOptimismPortalV1000,
    ISystemConfigV1000
} from "src/template/OPCMMigrateV1000.sol";
import {OPCMUpgradeV1000} from "src/template/OPCMUpgradeV1000.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";

/// @notice Exposes the post-migration state checks, so a test can rerun them on state that differs from what
/// migrate() produced.
contract OPCMMigrateV1000ValidateHarness is OPCMMigrateV1000 {
    function validateMigratedStateForTest(address sharedLockbox, address sharedDgf, address sharedAsr) external view {
        _validateMigratedState(sharedLockbox, sharedDgf, sharedAsr);
    }
}

/// @notice Runs the 049 example task end to end on a Sepolia fork, against the v10 OPCM the example points at. Both
/// chains are on 9.0.3 at FORK_BLOCK_NUMBER, so setUp first simulates the 048 example, which upgrades them with that
/// OPCM, as production stacks the two tasks. OPCMMigrateV1000Setup.t.sol covers the setup guards.
contract OPCMMigrateV1000Test is Test {
    using AccountAccessParser for VmSafe.AccountAccess[];

    string constant CONFIG = "test/tasks/example/sep/049-opcm-migrate-v1000/config.toml";
    string constant UPGRADE_CONFIG = "test/tasks/example/sep/048-opcm-upgrade-v1000/config.toml";
    uint256 internal constant FORK_BLOCK_NUMBER = 12_162_600;

    address internal constant OPCM = 0xe3D1CC898cd19F4ACE77715259eF942766c1d0D3;
    address internal constant FOUNDATION_UPGRADE_SAFE = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B;

    address internal constant UNICHAIN_SEPOLIA_SYSTEM_CONFIG = 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D;
    address internal constant UNICHAIN_SEPOLIA_PORTAL = 0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD;
    address internal constant OP_SEPOLIA_SYSTEM_CONFIG = 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538;
    address internal constant OP_SEPOLIA_PORTAL = 0x16Fc5058F25648194471939df75CF27A2fdC48BC;
    address internal constant OP_SEPOLIA_PROPOSER = 0x9884C33C65111DA7Bbed0e63cD2392F503b135F5;

    // The chains' current SUPER_CANNON_KONA prestate and bond, which the example also uses for the shared game.
    bytes32 internal constant CANNON_KONA_PRESTATE = 0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9;
    uint256 internal constant SUPER_CANNON_KONA_INIT_BOND = 0.08 ether;

    bytes32 internal constant INTEROP = "INTEROP";

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
        new OPCMUpgradeV1000().simulate(UPGRADE_CONFIG, _childSafes());
    }

    /// @notice The task builds exactly one action: a delegatecall to the OPCM's migrate() for the whole set, with the
    /// example's values decoded field by field (Regression.t.sol pins the same calldata as an opaque hex string).
    function test_build_encodesSingleMigrateCall() public {
        (, Action[] memory actions) = _simulate();

        IOPContractsManagerV1000.DisputeGameConfig[] memory gameConfigs =
            new IOPContractsManagerV1000.DisputeGameConfig[](2);
        gameConfigs[0] = IOPContractsManagerV1000.DisputeGameConfig({
            enabled: true,
            initBond: 0,
            gameType: 5,
            gameArgs: abi.encode(OP_SEPOLIA_PROPOSER)
        });
        gameConfigs[1] = IOPContractsManagerV1000.DisputeGameConfig({
            enabled: true,
            initBond: SUPER_CANNON_KONA_INIT_BOND,
            gameType: 9,
            gameArgs: abi.encode(CANNON_KONA_PRESTATE)
        });
        address[] memory systemConfigs = new address[](2);
        systemConfigs[0] = UNICHAIN_SEPOLIA_SYSTEM_CONFIG;
        systemConfigs[1] = OP_SEPOLIA_SYSTEM_CONFIG;
        IOPContractsManagerV1000.MigrateInput memory input = IOPContractsManagerV1000.MigrateInput({
            chainSystemConfigs: systemConfigs,
            disputeGameConfigs: gameConfigs,
            startingAnchorRoot: IOPContractsManagerV1000.Proposal({
                root: 0xdead000000000000000000000000000000000000000000000000000000000000,
                l2SequenceNumber: 1794412446
            }),
            startingRespectedGameType: 9
        });

        assertEq(actions.length, 1);
        assertEq(actions[0].target, OPCM);
        assertEq(actions[0].value, 0);
        assertEq(uint8(actions[0].operation), uint8(Enum.Operation.DelegateCall));
        assertEq(actions[0].arguments, abi.encodeCall(IOPContractsManagerV1000.migrate, (input)));
    }

    /// @notice After execution both portals use the three contracts migrate() created, all ETH from the portals and
    /// their old lockboxes sits in the shared lockbox, and INTEROP is on. simulate() also runs the task's validation,
    /// which must call the real validators and match the example's expected errors, and fails if migrate() writes a
    /// pre-existing contract the task did not allowlist.
    function test_simulate_migratesBothChains() public {
        address[2] memory portals = [UNICHAIN_SEPOLIA_PORTAL, OP_SEPOLIA_PORTAL];
        address[2] memory systemConfigs = [UNICHAIN_SEPOLIA_SYSTEM_CONFIG, OP_SEPOLIA_SYSTEM_CONFIG];
        address[2] memory oldLockboxes;
        uint256 ethBefore;
        for (uint256 i = 0; i < 2; i++) {
            // Seed the portals so migrate() also moves portal-held ETH.
            vm.deal(portals[i], 1 ether);
            oldLockboxes[i] = IOptimismPortalV1000(portals[i]).ethLockbox();
            ethBefore += portals[i].balance + oldLockboxes[i].balance;
        }

        address validator = address(IOPContractsManagerV1000(OPCM).opcmStandardValidator());
        vm.expectCall(
            validator, abi.encodePacked(IOPContractsManagerStandardValidatorV1000.validateMigratedChain.selector), 1
        );
        vm.expectCall(validator, abi.encodePacked(IOPContractsManagerStandardValidatorV1000.validate.selector), 2);
        (VmSafe.AccountAccess[] memory accesses,) = _simulate();

        address[] memory created = accesses.getNewContracts();
        assertEq(created.length, 3);
        (address sharedLockbox, address sharedDGF, address sharedASR) = (created[0], created[1], created[2]);
        for (uint256 i = 0; i < 2; i++) {
            IOptimismPortalV1000 portal = IOptimismPortalV1000(portals[i]);
            assertEq(portal.ethLockbox(), sharedLockbox);
            assertEq(portal.disputeGameFactory(), sharedDGF);
            assertEq(portal.anchorStateRegistry(), sharedASR);
            assertTrue(ISystemConfigV1000(systemConfigs[i]).isFeatureEnabled(INTEROP));
            assertEq(portals[i].balance, 0);
            assertEq(oldLockboxes[i].balance, 0);
        }
        assertEq(sharedLockbox.balance, ethBefore);
    }

    /// @notice migrate() keeps each portal's proof maturity delay. Validation fails if a portal's delay differs from
    /// the one recorded during setup.
    function test_validate_rejectsChangedProofMaturityDelay() public {
        (OPCMMigrateV1000ValidateHarness task, address[] memory created) = _simulateHarness();
        assertEq(task.preMigrationProofMaturityDelay(), 604800);

        vm.mockCall(OP_SEPOLIA_PORTAL, abi.encodeWithSignature("proofMaturityDelaySeconds()"), abi.encode(uint256(1)));
        vm.expectRevert(bytes("OPCMMigrateV1000: proof maturity delay changed"));
        task.validateMigratedStateForTest(created[0], created[1], created[2]);
    }

    /// @notice Validation fails if a portal does not point at each shared contract migrate() created.
    function test_validate_rejectsPortalOffSharedContracts() public {
        (OPCMMigrateV1000ValidateHarness task, address[] memory created) = _simulateHarness();
        vm.expectRevert(bytes("OPCMMigrateV1000: portal not on the shared ETHLockbox"));
        task.validateMigratedStateForTest(address(1), created[1], created[2]);
        vm.expectRevert(bytes("OPCMMigrateV1000: portal not on the shared DisputeGameFactory"));
        task.validateMigratedStateForTest(created[0], address(1), created[2]);
        vm.expectRevert(bytes("OPCMMigrateV1000: portal not on the shared AnchorStateRegistry"));
        task.validateMigratedStateForTest(created[0], created[1], address(1));
    }

    /// @notice Validation fails if a portal kept ETH, or if the shared lockbox holds less than the ETH recorded during
    /// setup.
    function test_validate_rejectsEthNotMoved() public {
        (OPCMMigrateV1000ValidateHarness task, address[] memory created) = _simulateHarness();
        vm.deal(OP_SEPOLIA_PORTAL, 1);
        vm.expectRevert(bytes("OPCMMigrateV1000: ETH left behind"));
        task.validateMigratedStateForTest(created[0], created[1], created[2]);

        vm.deal(OP_SEPOLIA_PORTAL, 0);
        assertGt(task.preMigrationEth(), 0);
        vm.deal(created[0], task.preMigrationEth() - 1);
        vm.expectRevert(bytes("OPCMMigrateV1000: shared lockbox did not receive all ETH"));
        task.validateMigratedStateForTest(created[0], created[1], created[2]);
    }

    /// @notice Validation fails if the shared AnchorStateRegistry does not respect the configured game type.
    function test_validate_rejectsRespectedGameTypeNotApplied() public {
        (OPCMMigrateV1000ValidateHarness task, address[] memory created) = _simulateHarness();
        vm.mockCall(created[2], abi.encodeWithSignature("respectedGameType()"), abi.encode(uint32(5)));
        vm.expectRevert(bytes("OPCMMigrateV1000: startingRespectedGameType not applied"));
        task.validateMigratedStateForTest(created[0], created[1], created[2]);
    }

    /// @notice When the root safe is not the validator's standard L1PAO, both validators run with the root safe as the
    /// L1PAO override. The migration validator applies it silently; the standard validator reports it for each chain.
    function test_simulate_validatesWithL1PAOOverride() public {
        address validator = address(IOPContractsManagerV1000(OPCM).opcmStandardValidator());
        vm.mockCall(validator, abi.encodeWithSignature("l1PAOMultisig()"), abi.encode(address(0xdead)));
        vm.expectCall(
            validator,
            abi.encodePacked(IOPContractsManagerStandardValidatorV1000.validateMigratedChainWithOverrides.selector),
            1
        );
        vm.expectCall(
            validator, abi.encodePacked(IOPContractsManagerStandardValidatorV1000.validateWithOverrides.selector), 2
        );

        string memory config = vm.replace(
            vm.readFile(CONFIG),
            'expectedChainValidationErrors = ["", ""]',
            'expectedChainValidationErrors = ["OVERRIDES-L1PAOMULTISIG", "OVERRIDES-L1PAOMULTISIG"]'
        );
        string memory path = MultisigTaskTestHelper.createTempTomlFile(config, "opcm-migrate-v1000", "l1pao-override");
        new OPCMMigrateV1000().simulate(path, _childSafes());
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice A wrong expectedValidationErrors fails simulate().
    function test_simulate_rejectsUnexpectedMigrationValidationErrors() public {
        _assertSimulateReverts(
            'expectedValidationErrors = ""',
            'expectedValidationErrors = "MIG-TEST"',
            "OPCMMigrateV1000: unexpected validation errors: ; expected: MIG-TEST"
        );
    }

    /// @notice A wrong expected string for the second chain fails simulate().
    function test_simulate_rejectsUnexpectedChainValidationErrors() public {
        _assertSimulateReverts(
            'expectedChainValidationErrors = ["", ""]',
            'expectedChainValidationErrors = ["", "CHAIN-TEST"]',
            "OPCMMigrateV1000: unexpected validation errors for chain 11155420: ; expected: CHAIN-TEST"
        );
    }

    /// @notice Simulates the example task as the Foundation Upgrade Safe, one of the L1PAO's two owners.
    function _simulate() internal returns (VmSafe.AccountAccess[] memory accesses, Action[] memory actions) {
        (accesses, actions,,) = new OPCMMigrateV1000().simulate(CONFIG, _childSafes());
    }

    /// @notice Simulates the example task with a harness that can rerun the post-migration checks, and returns the
    /// contracts migrate() created: the shared ETHLockbox, DisputeGameFactory and AnchorStateRegistry. The checks pass
    /// on the unmodified result.
    function _simulateHarness() internal returns (OPCMMigrateV1000ValidateHarness task, address[] memory created) {
        task = new OPCMMigrateV1000ValidateHarness();
        (VmSafe.AccountAccess[] memory accesses,,,) = task.simulate(CONFIG, _childSafes());
        created = accesses.getNewContracts();
        task.validateMigratedStateForTest(created[0], created[1], created[2]);
    }

    function _childSafes() internal pure returns (address[] memory childSafes) {
        childSafes = new address[](1);
        childSafes[0] = FOUNDATION_UPGRADE_SAFE;
    }

    /// @notice Simulates the example config with `from` replaced by `to` and expects it to revert with `reason`.
    function _assertSimulateReverts(string memory from, string memory to, string memory reason) internal {
        string memory config = vm.readFile(CONFIG);
        string memory edited = vm.replace(config, from, to);
        assertTrue(keccak256(bytes(edited)) != keccak256(bytes(config)), "test config edit did not apply");
        string memory path = MultisigTaskTestHelper.createTempTomlFile(edited, "opcm-migrate-v1000", to);

        OPCMMigrateV1000 task = new OPCMMigrateV1000();
        vm.expectRevert(bytes(reason));
        task.simulate(path, FOUNDATION_UPGRADE_SAFE);
        MultisigTaskTestHelper.removeFile(path);
    }
}
