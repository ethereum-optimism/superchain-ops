// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {
    OPCMMigrateV900,
    IOPContractsManagerV900,
    IOPContractsManagerStandardValidatorV900,
    IOptimismPortalV900
} from "src/template/OPCMMigrateV900.sol";
import {OPCMUpgradeV900} from "src/template/OPCMUpgradeV900.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";

interface ISystemConfigFeatures {
    function isFeatureEnabled(bytes32 _feature) external view returns (bool);
}

/// @notice Runs the 046 example task end to end on a Sepolia fork, against the v9 OPCM the example points at. Both
/// chains are on 8.0.1 at FORK_BLOCK_NUMBER, so setUp first simulates the 045 example, which upgrades them with that
/// OPCM, as production stacks the two tasks.
contract OPCMMigrateV900Test is Test {
    using AccountAccessParser for VmSafe.AccountAccess[];

    string constant CONFIG = "test/tasks/example/sep/046-opcm-migrate-v900/config.toml";
    string constant UPGRADE_CONFIG = "test/tasks/example/sep/045-opcm-upgrade-v900/config.toml";
    uint256 internal constant FORK_BLOCK_NUMBER = 11_999_987;

    address internal constant OPCM = 0xe09c417496C786ABFFefA676dA9e11aaB2c32eA9;
    address internal constant FOUNDATION_UPGRADE_SAFE = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B;

    address internal constant UNICHAIN_SEPOLIA_SYSTEM_CONFIG = 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D;
    address internal constant UNICHAIN_SEPOLIA_PORTAL = 0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD;
    address internal constant OP_SEPOLIA_SYSTEM_CONFIG = 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538;
    address internal constant OP_SEPOLIA_PORTAL = 0x16Fc5058F25648194471939df75CF27A2fdC48BC;
    address internal constant OP_SEPOLIA_PROPOSER = 0x9884C33C65111DA7Bbed0e63cD2392F503b135F5;

    // The chains' current SUPER_CANNON_KONA prestate and bond, which the example also uses for the shared game.
    bytes32 internal constant CANNON_KONA_PRESTATE = 0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df;
    uint256 internal constant SUPER_CANNON_KONA_INIT_BOND = 0.08 ether;

    bytes32 internal constant INTEROP = "INTEROP";

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
        new OPCMUpgradeV900().simulate(UPGRADE_CONFIG, _childSafes());
    }

    /// @notice The task builds exactly one action: a delegatecall to the OPCM's migrate() for the whole set.
    function test_build_encodesSingleMigrateCall() public {
        (, Action[] memory actions) = _simulate();

        IOPContractsManagerV900.DisputeGameConfig[] memory gameConfigs =
            new IOPContractsManagerV900.DisputeGameConfig[](2);
        gameConfigs[0] = IOPContractsManagerV900.DisputeGameConfig({
            enabled: true,
            initBond: 0,
            gameType: 5,
            gameArgs: abi.encode(OP_SEPOLIA_PROPOSER)
        });
        gameConfigs[1] = IOPContractsManagerV900.DisputeGameConfig({
            enabled: true,
            initBond: SUPER_CANNON_KONA_INIT_BOND,
            gameType: 9,
            gameArgs: abi.encode(CANNON_KONA_PRESTATE)
        });
        address[] memory systemConfigs = new address[](2);
        systemConfigs[0] = UNICHAIN_SEPOLIA_SYSTEM_CONFIG;
        systemConfigs[1] = OP_SEPOLIA_SYSTEM_CONFIG;
        IOPContractsManagerV900.MigrateInput memory input = IOPContractsManagerV900.MigrateInput({
            chainSystemConfigs: systemConfigs,
            disputeGameConfigs: gameConfigs,
            startingAnchorRoot: IOPContractsManagerV900.Proposal({
                root: 0xdead000000000000000000000000000000000000000000000000000000000000,
                l2SequenceNumber: 1792000000
            }),
            startingRespectedGameType: 9
        });

        assertEq(actions.length, 1);
        assertEq(actions[0].target, OPCM);
        assertEq(actions[0].value, 0);
        assertEq(uint8(actions[0].operation), uint8(Enum.Operation.DelegateCall));
        assertEq(actions[0].arguments, abi.encodeCall(IOPContractsManagerV900.migrate, (input)));
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
            // Portals hold no ETH at FORK_BLOCK_NUMBER; seed some so migrate() also moves portal-held ETH.
            vm.deal(portals[i], 1 ether);
            oldLockboxes[i] = IOptimismPortalV900(portals[i]).ethLockbox();
            ethBefore += portals[i].balance + oldLockboxes[i].balance;
        }

        address validator = address(IOPContractsManagerV900(OPCM).opcmStandardValidator());
        vm.expectCall(
            validator, abi.encodePacked(IOPContractsManagerStandardValidatorV900.validateMigratedChain.selector), 1
        );
        vm.expectCall(validator, abi.encodePacked(IOPContractsManagerStandardValidatorV900.validate.selector), 2);
        (VmSafe.AccountAccess[] memory accesses,) = _simulate();

        address[] memory created = accesses.getNewContracts();
        assertEq(created.length, 3);
        (address sharedLockbox, address sharedDGF, address sharedASR) = (created[0], created[1], created[2]);
        for (uint256 i = 0; i < 2; i++) {
            IOptimismPortalV900 portal = IOptimismPortalV900(portals[i]);
            assertEq(portal.ethLockbox(), sharedLockbox);
            assertEq(portal.disputeGameFactory(), sharedDGF);
            assertEq(portal.anchorStateRegistry(), sharedASR);
            assertTrue(ISystemConfigFeatures(systemConfigs[i]).isFeatureEnabled(INTEROP));
            assertEq(portals[i].balance, 0);
            assertEq(oldLockboxes[i].balance, 0);
        }
        assertEq(sharedLockbox.balance, ethBefore);
    }

    /// @notice A wrong expectedValidationErrors fails simulate().
    function test_simulate_rejectsUnexpectedMigrationValidationErrors() public {
        _assertSimulateReverts(
            'expectedValidationErrors = ""',
            'expectedValidationErrors = "MIG-TEST"',
            "OPCMMigrateV900: unexpected validation errors: ; expected: MIG-TEST"
        );
    }

    /// @notice A wrong expected string for the second chain fails simulate().
    function test_simulate_rejectsUnexpectedChainValidationErrors() public {
        _assertSimulateReverts(
            'expectedChainValidationErrors = ["", ""]',
            'expectedChainValidationErrors = ["", "CHAIN-TEST"]',
            "OPCMMigrateV900: unexpected validation errors for chain 11155420: ; expected: CHAIN-TEST"
        );
    }

    /// @notice Simulates the example task as the Foundation Upgrade Safe, one of the L1PAO's two owners.
    function _simulate() internal returns (VmSafe.AccountAccess[] memory accesses, Action[] memory actions) {
        (accesses, actions,,) = new OPCMMigrateV900().simulate(CONFIG, _childSafes());
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
        string memory path = MultisigTaskTestHelper.createTempTomlFile(edited, "opcm-migrate-v900", to);

        OPCMMigrateV900 task = new OPCMMigrateV900();
        vm.expectRevert(bytes(reason));
        task.simulate(path, FOUNDATION_UPGRADE_SAFE);
        MultisigTaskTestHelper.removeFile(path);
    }
}
