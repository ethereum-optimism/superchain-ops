// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMUpgradeV900} from "src/template/OPCMUpgradeV900.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";

interface IOptimismPortalAnchorStateRegistry {
    function anchorStateRegistry() external view returns (address);
}

interface ISystemConfigGuardian {
    function guardian() external view returns (address);
}

interface IAnchorStateRegistryRotate {
    function setRespectedGameType(uint32) external;
}

contract OPCMUpgradeV900SetupHarness is OPCMUpgradeV900 {
    function setupForTest(string memory configPath) external {
        superchainAddrRegistry = new SuperchainAddressRegistry(configPath);
        _templateSetup(configPath, address(0));
    }
}

/// @notice Exercises the `_templateSetup` checks of OPCMUpgradeV900 against the 046 example task.
/// @dev Forks Sepolia at the task's pinned block, where the rc1 v9 OPCM in the example config exists.
contract OPCMUpgradeV900SetupValidationTest is Test {
    string constant CONFIG = "test/tasks/example/sep/046-opcm-upgrade-v900/config.toml";
    // This directory is in the .gitignore file.
    string constant TEST_CONFIG_DIR = "test-config-files";
    uint256 internal constant FORK_BLOCK_NUMBER = 12_057_300;

    // op-contracts/v9.0.0-rc.1 OPCM on Sepolia, version 9.0.3: the OPCM the example task uses.
    string constant EXAMPLE_OPCM = 'OPCM = "0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc"';
    // op-contracts/v8.0.0-rc.3 OPCM on Sepolia, version 8.0.1 (sep/108): the release the chains are on.
    string constant SEPOLIA_OPCM_V801 = 'OPCM = "0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca"';
    // Throwaway 9.0.5 OPCM built from develop: passes the on-chain sequence gate, not the release.
    string constant SEPOLIA_OPCM_DEV_905 = 'OPCM = "0xe09c417496c786abffefa676da9e11aab2c32ea9"';
    string constant OPCM_VERSION_MISMATCH = "OPCMUpgradeV900: incorrect OPCM version";
    string constant RESPECTED_GAME_TYPE_MISMATCH =
        "OPCMUpgradeV900: startingRespectedGameType must equal the chain's current respected game type";
    string constant INIT_BOND_MISMATCH =
        "OPCMUpgradeV900: initBond must equal the chain's current SUPER_CANNON_KONA bond";

    // Unichain Sepolia.
    address internal constant UNICHAIN_PORTAL = 0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD;
    address internal constant UNICHAIN_SYSTEM_CONFIG = 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D;
    address internal constant UNICHAIN_DISPUTE_GAME_FACTORY = 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b;
    address internal constant UNICHAIN_SUPER_CANNON_KONA_IMPL = 0x19AF533Cc2A2A55786DCB8672aA5717e64213208;

    // DisputeGameFactory `gameImpls` mapping slot.
    uint256 internal constant GAME_IMPLS_SLOT = 101;
    uint32 internal constant SUPER_PERMISSIONED = 5;
    uint32 internal constant SUPER_CANNON_KONA = 9;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
    }

    function test_setup_succeeds_against_v9_opcm() public {
        OPCMUpgradeV900SetupHarness harness = new OPCMUpgradeV900SetupHarness();
        harness.setupForTest(CONFIG);
        assertEq(harness.chainsToUpgrade(0), 1301);
        assertEq(harness.chainsToUpgrade(1), 11155420);
        assertEq(address(harness.opcm()), 0x160f0FE4dC1B3f4026687e8dD4b7F800879939Cc);
    }

    function test_rejects_zero_cannon_kona_prestate() public {
        _assertSetupReverts(
            "zero-prestate",
            'cannonKonaPrestate = "0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df"',
            'cannonKonaPrestate = "0x0000000000000000000000000000000000000000000000000000000000000000"',
            "OPCMUpgradeV900: cannonKonaPrestate is zero"
        );
    }

    /// @dev 0x03b985a2… is the op-program 1.9.0 `interop` prestate, listed under the same "1.9.0"
    /// version key as kona-client: not a `cannon64-kona-interop` entry, so setup must reject it.
    function test_rejects_prestate_not_in_registry_as_cannon64_kona_interop() public {
        _assertSetupReverts(
            "op-program-prestate",
            'cannonKonaPrestate = "0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df"',
            'cannonKonaPrestate = "0x03b985a286da46ca88c0a965a53942daade9ffe1ae6b854a8f2d083df1cfaf59"',
            "OPCMUpgradeV900: cannonKonaPrestate is not a cannon64-kona-interop prestate in the registry for chain 1301"
        );
    }

    /// @dev Chains listed in `skipPrestateRegistryCheckChainIds` (custom prestates) bypass the check.
    function test_skip_list_bypasses_registry_prestate_check() public {
        string memory config = _edit(
            vm.readFile(CONFIG),
            'cannonKonaPrestate = "0x031ac6f15c19010da258f5cb633ef6ca9318c2d0f244bea6b2045ce6b790e1df"',
            'cannonKonaPrestate = "0x03b985a286da46ca88c0a965a53942daade9ffe1ae6b854a8f2d083df1cfaf59"'
        );
        config = _edit(
            config,
            'templateName = "OPCMUpgradeV900"',
            'templateName = "OPCMUpgradeV900"\nskipPrestateRegistryCheckChainIds = [1301, 11155420]'
        );
        OPCMUpgradeV900SetupHarness harness = new OPCMUpgradeV900SetupHarness();
        harness.setupForTest(_write("skip-prestate-check", config));
        assertEq(harness.chainsToUpgrade(0), 1301);
    }

    function test_rejects_non_super_starting_respected_game_type() public {
        _assertSetupReverts(
            "cannon-kona-respected",
            "startingRespectedGameType = 9 # SUPER_CANNON_KONA, unchanged",
            "startingRespectedGameType = 8",
            "OPCMUpgradeV900: startingRespectedGameType must be a super game type (5 or 9)"
        );
    }

    /// @dev The upgrade carries the respected game type forward: a config that differs from the
    /// chain's current value is rejected, not applied.
    function test_rejects_starting_respected_game_type_that_differs_from_chain() public {
        _assertSetupReverts(
            "rotated-respected",
            "startingRespectedGameType = 9 # SUPER_CANNON_KONA, unchanged",
            "startingRespectedGameType = 5",
            RESPECTED_GAME_TYPE_MISMATCH
        );
    }

    /// @dev The upgrade re-sets the SUPER_CANNON_KONA bond from config: a value that differs from
    /// the chain's current bond is rejected, not applied.
    function test_rejects_init_bond_that_differs_from_chain() public {
        _assertSetupReverts(
            "wrong-bond",
            "initBond = 80000000000000000 # 0.08 ETH, the chain's current SUPER_CANNON_KONA bond",
            "initBond = 8000000000000000",
            INIT_BOND_MISMATCH
        );
    }

    /// @dev Shapes Unichain Sepolia like a SUPER_PERMISSIONED-only chain (no SUPER_CANNON_KONA game,
    /// AnchorStateRegistry respecting 5). The unmodified example config says 9, which would enable a
    /// permissionless game the chain does not have and rotate onto it with a clean validator run.
    function test_rejects_super_cannon_kona_config_on_super_permissioned_only_chain() public {
        bytes32 slot = keccak256(abi.encode(uint256(SUPER_CANNON_KONA), GAME_IMPLS_SLOT));
        assertEq(
            address(uint160(uint256(vm.load(UNICHAIN_DISPUTE_GAME_FACTORY, slot)))),
            UNICHAIN_SUPER_CANNON_KONA_IMPL,
            "impl slot"
        );
        vm.store(UNICHAIN_DISPUTE_GAME_FACTORY, slot, bytes32(0));
        address asr = IOptimismPortalAnchorStateRegistry(UNICHAIN_PORTAL).anchorStateRegistry();
        vm.prank(ISystemConfigGuardian(UNICHAIN_SYSTEM_CONFIG).guardian());
        IAnchorStateRegistryRotate(asr).setRespectedGameType(SUPER_PERMISSIONED);

        OPCMUpgradeV900SetupHarness harness = new OPCMUpgradeV900SetupHarness();
        vm.expectRevert(bytes(RESPECTED_GAME_TYPE_MISMATCH));
        harness.setupForTest(CONFIG);
    }

    /// @dev The v8 OPCM is a real contract on Sepolia, so the version gate is what rejects it.
    function test_rejects_non_v9_opcm() public {
        _assertSetupReverts("v8-opcm", EXAMPLE_OPCM, SEPOLIA_OPCM_V801, OPCM_VERSION_MISMATCH);
    }

    /// @dev A dev build with a higher patch version passes the on-chain sequence gate and would
    /// lock the chain out of the release OPCM; only the exact release version is accepted.
    function test_rejects_dev_build_opcm() public {
        _assertSetupReverts("dev-opcm", EXAMPLE_OPCM, SEPOLIA_OPCM_DEV_905, OPCM_VERSION_MISMATCH);
    }

    function test_rejects_opcm_with_dev_features() public {
        vm.mockCall(
            0x160f0FE4dC1B3f4026687e8dD4b7F800879939Cc,
            abi.encodeWithSignature("devFeatureBitmap()"),
            abi.encode(bytes32(uint256(1)))
        );
        OPCMUpgradeV900SetupHarness harness = new OPCMUpgradeV900SetupHarness();
        vm.expectRevert(bytes("OPCMUpgradeV900: OPCM has dev features enabled"));
        harness.setupForTest(CONFIG);
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
