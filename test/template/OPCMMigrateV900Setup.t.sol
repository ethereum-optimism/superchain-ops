// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMMigrateV900, IOptimismPortalV900, ISystemConfigV900} from "src/template/OPCMMigrateV900.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";

contract OPCMMigrateV900SetupHarness is OPCMMigrateV900 {
    function setupForTest(string memory configPath) external {
        superchainAddrRegistry = new SuperchainAddressRegistry(configPath);
        _templateSetup(configPath, address(0));
    }
}

/// @notice Stands in for a v9 OPCM until one is deployed.
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

/// @notice Exercises the `_templateSetup` checks of OPCMMigrateV900 against the 044 example task.
/// @dev No v9 OPCM is deployed yet, so these tests stop at setup, or use a mock OPCM.
contract OPCMMigrateV900SetupValidationTest is Test {
    string constant CONFIG = "test/tasks/example/sep/044-opcm-migrate-v900/config.toml";
    // This directory is in the .gitignore file.
    string constant TEST_CONFIG_DIR = "test-config-files";
    uint256 internal constant FORK_BLOCK_NUMBER = 11_920_727;
    string constant EXAMPLE_OPCM = 'OPCM = "0x000000000000000000000000000000000000dEaD"';

    // op-contracts/v8.0.0-rc.3 OPCM on Sepolia, version 8.0.1 (sep/108).
    address internal constant SEPOLIA_OPCM_V801 = 0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca;
    address internal constant INK_SEPOLIA_PORTAL = 0x5c1d29C6c9C8b0800692acC95D700bcb4966A1d7;
    address internal constant INK_SEPOLIA_SYSTEM_CONFIG = 0x05C993e60179f28bF649a2Bb5b00b5F4283bD525;

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
            'proposer = "0x49277EE36A024120Ee218127354c4a3591dc90A9"',
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
            'expectedChainValidationErrors = ["", "", ""]',
            'expectedChainValidationErrors = ["", ""]',
            "OPCMMigrateV900: expectedChainValidationErrors must have one entry per chain"
        );
    }

    function test_rejects_chains_out_of_order() public {
        _assertSetupReverts(
            "out-of-order",
            '{name = "Unichain Sepolia Testnet", chainId = 1301},\n    {name = "Ink Sepolia", chainId = 763373},',
            '{name = "Ink Sepolia", chainId = 763373},\n    {name = "Unichain Sepolia Testnet", chainId = 1301},',
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
        config = _edit(
            config, 'expectedChainValidationErrors = ["", "", ""]', 'expectedChainValidationErrors = ["", "", "", ""]'
        );
        _expectSetupRevert(
            _write("mismatched-superchain-config", config),
            "OPCMMigrateV900: all chains must share the same SuperchainConfig"
        );
    }

    function test_rejects_mismatched_finality_delay() public {
        vm.mockCall(
            IOptimismPortalV900(INK_SEPOLIA_PORTAL).anchorStateRegistry(),
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
            ISystemConfigV900(INK_SEPOLIA_SYSTEM_CONFIG).delayedWETH(),
            abi.encodeWithSignature("delay()"),
            abi.encode(uint256(1))
        );
        _assertSetupReverts(
            "mismatched-weth-delay", "", "", "OPCMMigrateV900: all chains must have the same DelayedWETH delay"
        );
    }

    /// @dev The example's OPCM is a code-less placeholder until a v9 OPCM is deployed.
    function test_rejects_opcm_without_code() public {
        _assertSetupReverts("example", "", "", "OPCMMigrateV900: OPCM has no code");
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
        OPCMMigrateV900SetupHarness harness = new OPCMMigrateV900SetupHarness();
        harness.setupForTest(_writeConfigWithMockOPCM("v910-opcm", "9.1.0"));
        assertEq(harness.opcm().version(), "9.1.0");
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

    /// @notice Expects setup with the config at `path` to revert with `reason`.
    function _expectSetupRevert(string memory path, string memory reason) internal {
        OPCMMigrateV900SetupHarness harness = new OPCMMigrateV900SetupHarness();
        vm.expectRevert(bytes(reason));
        harness.setupForTest(path);
    }

    /// @notice Writes the example config with its placeholder OPCM replaced by a mock reporting `version`.
    function _writeConfigWithMockOPCM(string memory name, string memory version) internal returns (string memory) {
        MockOPCMV900 mock = new MockOPCMV900(version);
        string memory opcm = string.concat('OPCM = "', vm.toString(address(mock)), '"');
        return _write(name, _edit(vm.readFile(CONFIG), EXAMPLE_OPCM, opcm));
    }

    /// @notice Returns `config` with `from` replaced by `to`, failing if `from` is not found.
    function _edit(string memory config, string memory from, string memory to) internal pure returns (string memory) {
        string memory edited = vm.replace(config, from, to);
        assertTrue(keccak256(bytes(edited)) != keccak256(bytes(config)), "test config edit did not apply");
        return edited;
    }

    /// @notice Writes `config` to a test config file and returns its path.
    function _write(string memory name, string memory config) internal returns (string memory) {
        vm.createDir(TEST_CONFIG_DIR, true);
        string memory path = string.concat(TEST_CONFIG_DIR, "/opcm-migrate-v900-", name, ".toml");
        vm.writeFile(path, config);
        return path;
    }
}
