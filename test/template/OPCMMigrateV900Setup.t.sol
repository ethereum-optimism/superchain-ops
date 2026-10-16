// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMMigrateV900} from "src/template/OPCMMigrateV900.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";

contract OPCMMigrateV900SetupHarness is OPCMMigrateV900 {
    function setupForTest(string memory configPath) external {
        superchainAddrRegistry = new SuperchainAddressRegistry(configPath);
        _templateSetup(configPath, address(0));
    }
}

/// @notice Exercises the `_templateSetup` checks of OPCMMigrateV900 against the 044 example task.
/// @dev No v9 OPCM is deployed yet, so these tests stop at setup.
contract OPCMMigrateV900SetupValidationTest is Test {
    string constant CONFIG = "test/tasks/example/sep/044-opcm-migrate-v900/config.toml";
    // This directory is in the .gitignore file.
    string constant TEST_CONFIG_DIR = "test-config-files";
    uint256 internal constant FORK_BLOCK_NUMBER = 11_920_727;

    // op-contracts/v8.0.0-rc.3 OPCM on Sepolia, version 8.0.1 (sep/108).
    address internal constant SEPOLIA_OPCM_V801 = 0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca;

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
        _assertSetupReverts(
            "mismatched-superchain-config",
            '{name = "OP Sepolia Testnet", chainId = 11155420}\n]',
            '{name = "OP Sepolia Testnet", chainId = 11155420},\n    {name = "sepolia-devnet-2", chainId = 420130015}\n]',
            "OPCMMigrateV900: all chains must share the same SuperchainConfig"
        );
    }

    /// @dev The example's OPCM is a code-less placeholder until a v9 OPCM is deployed.
    function test_rejects_opcm_without_code() public {
        _assertSetupReverts("example", "", "", "OPCMMigrateV900: OPCM has no code");
    }

    function test_rejects_non_v9_opcm() public {
        _assertSetupReverts(
            "v801-opcm",
            'OPCM = "0x000000000000000000000000000000000000dEaD"',
            string.concat('OPCM = "', vm.toString(SEPOLIA_OPCM_V801), '"'),
            "OPCMMigrateV900: incorrect OPCM major/minor version"
        );
    }

    /// @notice Writes the example config with `from` replaced by `to`, then expects setup to revert with `reason`.
    /// An empty `from` uses the example config unchanged.
    function _assertSetupReverts(string memory name, string memory from, string memory to, string memory reason)
        internal
    {
        string memory config = vm.readFile(CONFIG);
        if (bytes(from).length > 0) {
            string memory edited = vm.replace(config, from, to);
            assertTrue(keccak256(bytes(edited)) != keccak256(bytes(config)), "test config edit did not apply");
            config = edited;
        }
        vm.createDir(TEST_CONFIG_DIR, true);
        string memory path = string.concat(TEST_CONFIG_DIR, "/opcm-migrate-v900-", name, ".toml");
        vm.writeFile(path, config);

        OPCMMigrateV900SetupHarness harness = new OPCMMigrateV900SetupHarness();
        vm.expectRevert(bytes(reason));
        harness.setupForTest(path);
    }
}
