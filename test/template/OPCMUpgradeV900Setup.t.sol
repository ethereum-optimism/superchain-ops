// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMUpgradeV900} from "src/template/OPCMUpgradeV900.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";

contract OPCMUpgradeV900SetupHarness is OPCMUpgradeV900 {
    function setupForTest(string memory configPath) external {
        superchainAddrRegistry = new SuperchainAddressRegistry(configPath);
        _templateSetup(configPath, address(0));
    }
}

/// @notice Exercises the `_templateSetup` checks of OPCMUpgradeV900 against the 045 example task.
/// @dev Forks Sepolia at the task's pinned block, where the throwaway v9 OPCM in the example config exists.
contract OPCMUpgradeV900SetupValidationTest is Test {
    string constant CONFIG = "test/tasks/example/sep/045-opcm-upgrade-v900/config.toml";
    // This directory is in the .gitignore file.
    string constant TEST_CONFIG_DIR = "test-config-files";
    uint256 internal constant FORK_BLOCK_NUMBER = 11_999_987;

    // op-contracts/v8.0.0-rc.3 OPCM on Sepolia, version 8.0.1 (sep/108): the release the chains are on.
    string constant EXAMPLE_OPCM = 'OPCM = "0xe09c417496c786abffefa676da9e11aab2c32ea9"';
    string constant SEPOLIA_OPCM_V801 = 'OPCM = "0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca"';

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
    }

    function test_setup_succeeds_against_v9_opcm() public {
        OPCMUpgradeV900SetupHarness harness = new OPCMUpgradeV900SetupHarness();
        harness.setupForTest(CONFIG);
        assertEq(harness.chainsToUpgrade(0), 1301);
        assertEq(harness.chainsToUpgrade(1), 11155420);
        assertEq(address(harness.opcm()), 0xe09c417496C786ABFFefA676dA9e11aaB2c32eA9);
    }

    function test_rejects_zero_cannon_kona_prestate() public {
        _assertSetupReverts(
            "zero-prestate",
            'cannonKonaPrestate = "0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df"',
            'cannonKonaPrestate = "0x0000000000000000000000000000000000000000000000000000000000000000"',
            "OPCMUpgradeV900: cannonKonaPrestate is zero"
        );
    }

    function test_rejects_non_super_starting_respected_game_type() public {
        _assertSetupReverts(
            "cannon-kona-respected",
            "startingRespectedGameType = 9 # SUPER_CANNON_KONA, unchanged",
            "startingRespectedGameType = 8",
            "OPCMUpgradeV900: startingRespectedGameType must be a super game type (5 or 9)"
        );
    }

    /// @dev The v8 OPCM is a real contract on Sepolia, so the version gate is what rejects it.
    function test_rejects_non_v9_opcm() public {
        _assertSetupReverts("v8-opcm", EXAMPLE_OPCM, SEPOLIA_OPCM_V801, "OPCMUpgradeV900: incorrect OPCM major version");
    }

    function test_rejects_opcm_without_code() public {
        _assertSetupReverts(
            "no-code-opcm",
            EXAMPLE_OPCM,
            'OPCM = "0x000000000000000000000000000000000000dEaD"',
            "OPCMUpgradeV900: OPCM has no code"
        );
    }

    /// @notice Writes the example config with `from` replaced by `to`, then expects setup to revert with `reason`.
    function _assertSetupReverts(string memory name, string memory from, string memory to, string memory reason)
        internal
    {
        string memory config = _edit(vm.readFile(CONFIG), from, to);
        OPCMUpgradeV900SetupHarness harness = new OPCMUpgradeV900SetupHarness();
        vm.expectRevert(bytes(reason));
        harness.setupForTest(_write(name, config));
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
        string memory path = string.concat(TEST_CONFIG_DIR, "/opcm-upgrade-v900-", name, ".toml");
        vm.writeFile(path, config);
        return path;
    }
}
