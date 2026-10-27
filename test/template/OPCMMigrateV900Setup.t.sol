// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMMigrateV900, IOptimismPortalV900, ISystemConfigV900} from "src/template/OPCMMigrateV900.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";

contract OPCMMigrateV900SetupHarness is OPCMMigrateV900 {
    function setupForTest(string memory configPath) external {
        superchainAddrRegistry = new SuperchainAddressRegistry(configPath);
        _templateSetup(configPath, address(0));
    }
}

/// @notice Reports a configurable version, so setup can be tested against OPCM versions that are not deployed.
contract MockOPCMV900 {
    string public version;

    constructor(string memory _version) {
        version = _version;
    }

    function opcmStandardValidator() external view returns (address) {
        return address(this);
    }

    function isPermittedMigrateSequence(address) external pure returns (bool) {
        return true;
    }
}

/// @notice Exercises the `_templateSetup` checks of OPCMMigrateV900 against the 046 example task.
/// @dev The example's chains are not upgraded to v9 at FORK_BLOCK_NUMBER, so setup only completes with a mock OPCM.
/// OPCMMigrateV900.t.sol runs the 045 upgrade example first and then the whole task.
contract OPCMMigrateV900SetupValidationTest is Test {
    string constant CONFIG = "test/tasks/example/sep/046-opcm-migrate-v900/config.toml";
    string constant TESTING_DIRECTORY = "opcm-migrate-v900";
    uint256 internal constant FORK_BLOCK_NUMBER = 11_999_987;
    string constant EXAMPLE_OPCM = 'OPCM = "0xe09c417496C786ABFFefA676dA9e11aaB2c32eA9"';

    // op-contracts/v8.0.0-rc.3 OPCM on Sepolia, version 8.0.1 (sep/108).
    address internal constant SEPOLIA_OPCM_V801 = 0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca;
    address internal constant OP_SEPOLIA_PORTAL = 0x16Fc5058F25648194471939df75CF27A2fdC48BC;
    address internal constant OP_SEPOLIA_SYSTEM_CONFIG = 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
    }

    function test_rejects_zero_cannon_kona_prestate() public {
        _assertSetupReverts(
            "zero-prestate",
            'cannonKonaPrestate = "0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df"',
            'cannonKonaPrestate = "0x0000000000000000000000000000000000000000000000000000000000000000"',
            "OPCMMigrateV900: cannonKonaPrestate is zero"
        );
    }

    function test_rejects_zero_proposer() public {
        _assertSetupReverts(
            "zero-proposer",
            'proposer = "0x9884C33C65111DA7Bbed0e63cD2392F503b135F5"',
            'proposer = "0x0000000000000000000000000000000000000000"',
            "OPCMMigrateV900: proposer is zero"
        );
    }

    function test_rejects_zero_super_cannon_kona_init_bond() public {
        _assertSetupReverts(
            "zero-bond",
            "superCannonKonaInitBond = 80000000000000000",
            "superCannonKonaInitBond = 0",
            "OPCMMigrateV900: superCannonKonaInitBond is zero"
        );
    }

    function test_rejects_non_super_starting_respected_game_type() public {
        _assertSetupReverts(
            "cannon-kona-respected",
            "startingRespectedGameType = 9",
            "startingRespectedGameType = 8",
            "OPCMMigrateV900: startingRespectedGameType must be a super game type (5 or 9)"
        );
    }

    function test_rejects_zero_starting_anchor_root() public {
        _assertSetupReverts(
            "zero-anchor",
            'startingAnchorRootRoot = "0xdead000000000000000000000000000000000000000000000000000000000000"',
            'startingAnchorRootRoot = "0x0000000000000000000000000000000000000000000000000000000000000000"',
            "OPCMMigrateV900: startingAnchorRootRoot is zero"
        );
    }

    /// @dev A timestamp in milliseconds instead of seconds.
    function test_rejects_future_starting_anchor() public {
        _assertSetupReverts(
            "future-anchor",
            "startingAnchorRootL2SequenceNumber = 1792000000",
            "startingAnchorRootL2SequenceNumber = 1792000000000",
            "OPCMMigrateV900: startingAnchorRootL2SequenceNumber is in the future"
        );
    }

    function test_rejects_wrong_expected_chain_validation_errors_length() public {
        _assertSetupReverts(
            "chain-errors-length",
            'expectedChainValidationErrors = ["", ""]',
            'expectedChainValidationErrors = [""]',
            "OPCMMigrateV900: expectedChainValidationErrors must have one entry per chain"
        );
    }

    function test_rejects_chains_out_of_order() public {
        _assertSetupReverts(
            "out-of-order",
            '{name = "Unichain Sepolia Testnet", chainId = 1301},\n    {name = "OP Sepolia Testnet", chainId = 11155420}',
            '{name = "OP Sepolia Testnet", chainId = 11155420},\n    {name = "Unichain Sepolia Testnet", chainId = 1301}',
            "OPCMMigrateV900: l2chains must be in strictly ascending chainId order"
        );
    }

    /// @dev sepolia-devnet-2 has its own SuperchainConfig, so it cannot join the public Sepolia set.
    function test_rejects_mismatched_superchain_config() public {
        string memory config = _edit(
            vm.readFile(CONFIG),
            '{name = "OP Sepolia Testnet", chainId = 11155420}\n]',
            '{name = "OP Sepolia Testnet", chainId = 11155420},\n    {name = "sepolia-devnet-2", chainId = 420130015}\n]'
        );
        config =
            _edit(config, 'expectedChainValidationErrors = ["", ""]', 'expectedChainValidationErrors = ["", "", ""]');
        _expectSetupRevert(
            _write("mismatched-superchain-config", config),
            "OPCMMigrateV900: all chains must share the same SuperchainConfig"
        );
    }

    function test_rejects_mismatched_finality_delay() public {
        vm.mockCall(
            IOptimismPortalV900(OP_SEPOLIA_PORTAL).anchorStateRegistry(),
            abi.encodeWithSignature("disputeGameFinalityDelaySeconds()"),
            abi.encode(uint256(1))
        );
        _assertSetupReverts(
            "mismatched-finality-delay",
            "",
            "",
            "OPCMMigrateV900: all chains must have the same dispute game finality delay"
        );
    }

    function test_rejects_mismatched_delayed_weth_delay() public {
        vm.mockCall(
            ISystemConfigV900(OP_SEPOLIA_SYSTEM_CONFIG).delayedWETH(),
            abi.encodeWithSignature("delay()"),
            abi.encode(uint256(1))
        );
        _assertSetupReverts(
            "mismatched-weth-delay", "", "", "OPCMMigrateV900: all chains must have the same DelayedWETH delay"
        );
    }

    function test_rejects_opcm_without_code() public {
        _assertSetupReverts(
            "no-code-opcm",
            EXAMPLE_OPCM,
            'OPCM = "0x000000000000000000000000000000000000dEaD"',
            "OPCMMigrateV900: OPCM has no code"
        );
    }

    function test_rejects_chains_not_upgraded_with_opcm_release() public {
        _assertSetupReverts(
            "not-upgraded", "", "", "OPCMMigrateV900: chain must be upgraded with this OPCM's release before migrating"
        );
    }

    function test_rejects_non_v9_opcm() public {
        _assertSetupReverts(
            "v801-opcm",
            EXAMPLE_OPCM,
            string.concat('OPCM = "', vm.toString(SEPOLIA_OPCM_V801), '"'),
            "OPCMMigrateV900: incorrect OPCM major version"
        );
    }

    /// @dev The version gate accepts any 9.x OPCM.
    function test_accepts_newer_v9_minor_opcm() public {
        string memory path = _writeConfigWithMockOPCM("v910-opcm", "9.1.0", false);
        OPCMMigrateV900SetupHarness harness = new OPCMMigrateV900SetupHarness();
        harness.setupForTest(path);
        MultisigTaskTestHelper.removeFile(path);
        assertEq(harness.opcm().version(), "9.1.0");
    }

    function test_skip_version_check_accepts_non_v9_opcm() public {
        string memory path = _writeConfigWithMockOPCM("skip-version-check", "8.0.1", true);
        OPCMMigrateV900SetupHarness harness = new OPCMMigrateV900SetupHarness();
        harness.setupForTest(path);
        MultisigTaskTestHelper.removeFile(path);
        assertTrue(harness.skipOPCMVersionCheck());
        assertEq(harness.opcm().version(), "8.0.1");
    }

    /// @notice Writes the example config with `from` replaced by `to`, then expects setup to revert with `reason`.
    /// An empty `from` uses the example config unchanged.
    function _assertSetupReverts(string memory name, string memory from, string memory to, string memory reason)
        internal
    {
        string memory config = vm.readFile(CONFIG);
        if (bytes(from).length > 0) config = _edit(config, from, to);
        _expectSetupRevert(_write(name, config), reason);
    }

    /// @notice Expects setup with the config at `path` to revert with `reason`, then deletes the config.
    function _expectSetupRevert(string memory path, string memory reason) internal {
        OPCMMigrateV900SetupHarness harness = new OPCMMigrateV900SetupHarness();
        vm.expectRevert(bytes(reason));
        harness.setupForTest(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice Writes the example config with its OPCM replaced by a mock reporting `version`.
    function _writeConfigWithMockOPCM(string memory name, string memory version, bool skipVersionCheck)
        internal
        returns (string memory)
    {
        MockOPCMV900 mock = new MockOPCMV900(version);
        string memory opcm = string.concat('OPCM = "', vm.toString(address(mock)), '"');
        string memory config = _edit(vm.readFile(CONFIG), EXAMPLE_OPCM, opcm);
        if (skipVersionCheck) {
            config = _edit(config, "skipOPCMVersionCheck = false", "skipOPCMVersionCheck = true");
        }
        return _write(name, config);
    }

    /// @notice Returns `config` with `from` replaced by `to`, failing if `from` is not found.
    function _edit(string memory config, string memory from, string memory to) internal pure returns (string memory) {
        string memory edited = vm.replace(config, from, to);
        assertTrue(keccak256(bytes(edited)) != keccak256(bytes(config)), "test config edit did not apply");
        return edited;
    }

    /// @notice Writes `config` to a temporary test config file and returns its path.
    function _write(string memory name, string memory config) internal returns (string memory) {
        return MultisigTaskTestHelper.createTempTomlFile(config, TESTING_DIRECTORY, name);
    }
}
