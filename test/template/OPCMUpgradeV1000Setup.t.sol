// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMUpgradeV1000} from "src/template/OPCMUpgradeV1000.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";

contract OPCMUpgradeV1000SetupHarness is OPCMUpgradeV1000 {
    function setupForTest(string memory configPath) external {
        superchainAddrRegistry = new SuperchainAddressRegistry(configPath);
        _templateSetup(configPath, address(0));
    }

    /// @dev Discovers the Sepolia chains, then runs setup as if on L1 mainnet (chain ID 1).
    function setupForTestAsMainnet(string memory configPath) external {
        superchainAddrRegistry = new SuperchainAddressRegistry(configPath);
        vm.chainId(1);
        _templateSetup(configPath, address(0));
    }
}

/// @notice Exercises the `_templateSetup` checks of OPCMUpgradeV1000 against the 048 example task.
/// @dev Forks Sepolia at the task's pinned block, where both chains are on op-contracts/v9 (9.0.3) and the
/// op-contracts/v10.0.0-rc.1 OPCM in the example config exists.
contract OPCMUpgradeV1000SetupValidationTest is Test {
    string constant CONFIG = "test/tasks/example/sep/048-opcm-upgrade-v1000/config.toml";
    string constant TESTING_DIRECTORY = "opcm-upgrade-v1000";
    uint256 internal constant FORK_BLOCK_NUMBER = 12_162_600;

    address internal constant OPCM = 0xe3D1CC898cd19F4ACE77715259eF942766c1d0D3;
    string constant EXAMPLE_OPCM = 'OPCM = "0xe3D1CC898cd19F4ACE77715259eF942766c1d0D3"';
    // op-contracts/v9.0.0 OPCM on Sepolia, version 9.0.3 (046, sep/115): the release the chains are on.
    string constant SEPOLIA_OPCM_V903 = 'OPCM = "0x160f0FE4dC1B3f4026687e8dD4b7F800879939Cc"';

    string constant EXAMPLE_PRESTATE =
        'cannonKonaPrestate = "0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9"';
    // op-program 1.9.0 `interop` prestate: listed in the registry, but not as `cannon64-kona-interop`.
    string constant OP_PROGRAM_INTEROP_PRESTATE =
        'cannonKonaPrestate = "0x03b985a286da46ca88c0a965a53942daade9ffe1ae6b854a8f2d083df1cfaf59"';

    // Unichain Sepolia's portal, SystemConfig, DisputeGameFactory and the factory's `gameImpls` mapping slot.
    address internal constant UNICHAIN_PORTAL = 0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD;
    address internal constant UNICHAIN_SYSTEM_CONFIG = 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D;
    address internal constant UNICHAIN_DISPUTE_GAME_FACTORY = 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b;
    address internal constant UNICHAIN_SUPER_CANNON_KONA_IMPL = 0x19AF533Cc2A2A55786DCB8672aA5717e64213208;
    uint256 internal constant GAME_IMPLS_SLOT = 101;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
    }

    /// @notice Setup reads each chain's SUPER_PERMISSIONED proposer from its live game: the chains have different
    /// proposers before migrating, and the upgrade must keep each one.
    function test_setup_succeeds_and_reads_live_proposers() public {
        OPCMUpgradeV1000SetupHarness harness = new OPCMUpgradeV1000SetupHarness();
        harness.setupForTest(CONFIG);
        assertEq(harness.chainsToUpgrade(0), 1301);
        assertEq(harness.chainsToUpgrade(1), 11155420);
        assertEq(address(harness.opcm()), OPCM);
        assertEq(harness.superPermissionedProposer(1301), 0x97E74f93DF7Fb8eb2542d0Cc42DFB21AaBB40800);
        assertEq(harness.superPermissionedProposer(11155420), 0x9884C33C65111DA7Bbed0e63cD2392F503b135F5);
    }

    /// @dev The upgrade re-sets the SUPER_CANNON_KONA bond from config: a value that differs from the chain's
    /// current bond is rejected, not applied.
    function test_rejects_super_cannon_kona_bond_that_differs_from_chain() public {
        _assertSetupReverts(
            "wrong-sck-bond",
            "superCannonKonaInitBond = 80000000000000000",
            "superCannonKonaInitBond = 90000000000000000",
            "OPCMUpgradeV1000: superCannonKonaInitBond must equal the chain's current SUPER_CANNON_KONA bond"
        );
    }

    function test_rejects_cannon_kona_prestate_not_in_registry_as_cannon64_kona_interop() public {
        _assertSetupReverts(
            "op-program-prestate",
            EXAMPLE_PRESTATE,
            OP_PROGRAM_INTEROP_PRESTATE,
            "OPCMUpgradeV1000: cannonKonaPrestate is not a cannon64-kona-interop prestate in the registry for chain 1301"
        );
    }

    /// @dev A cannon64-kona-interop hash in the ZK prestate field is a wrong-variant mistake the validator would not
    /// catch: it compares the on-chain args against the same input.
    function test_rejects_zk_prestate_not_in_registry_as_kona_sp1() public {
        string memory config =
            _enableZK(vm.readFile(CONFIG), "0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9");
        _expectSetupRevert(
            _write("wrong-zk-prestate", config),
            "OPCMUpgradeV1000: zkPrestate is not a kona-sp1 prestate in the registry for chain 1301"
        );
    }

    /// @dev Chains listed in `skipPrestateRegistryCheckChainIds` (custom prestates) bypass the check.
    function test_skip_list_bypasses_registry_prestate_check() public {
        string memory config = _edit(vm.readFile(CONFIG), EXAMPLE_PRESTATE, OP_PROGRAM_INTEROP_PRESTATE);
        config = _edit(
            config,
            'templateName = "OPCMUpgradeV1000"',
            'templateName = "OPCMUpgradeV1000"\nskipPrestateRegistryCheckChainIds = [1301, 11155420]'
        );
        OPCMUpgradeV1000SetupHarness harness = new OPCMUpgradeV1000SetupHarness();
        string memory path = _write("skip-prestate-check", config);
        harness.setupForTest(path);
        MultisigTaskTestHelper.removeFile(path);
        assertEq(harness.chainsToUpgrade(0), 1301);
    }

    /// @dev The template always disables CANNON_KONA (8), so a chain still running it is refused rather than losing the
    /// game silently. A fake type 0 or 1 game would fail earlier, in the address registry that reads their args.
    function test_rejects_chain_with_legacy_game() public {
        bytes32 sckSlot = keccak256(abi.encode(uint256(9), GAME_IMPLS_SLOT));
        assertEq(
            address(uint160(uint256(vm.load(UNICHAIN_DISPUTE_GAME_FACTORY, sckSlot)))),
            UNICHAIN_SUPER_CANNON_KONA_IMPL,
            "gameImpls slot"
        );
        vm.store(
            UNICHAIN_DISPUTE_GAME_FACTORY,
            keccak256(abi.encode(uint256(8), GAME_IMPLS_SLOT)),
            bytes32(uint256(uint160(UNICHAIN_SUPER_CANNON_KONA_IMPL)))
        );
        _expectSetupRevert(CONFIG, "OPCMUpgradeV1000: legacy game types (0, 1, 8) must already be retired");
    }

    /// @dev v10 cannot deploy an ETHLockbox, so a chain without one is refused.
    function test_rejects_chain_without_lockbox() public {
        vm.mockCall(UNICHAIN_PORTAL, abi.encodeWithSignature("ethLockbox()"), abi.encode(address(0)));
        _expectSetupRevert(CONFIG, "OPCMUpgradeV1000: chain has no ETHLockbox");
    }

    /// @dev With the ETH_LOCKBOX feature off, the OPCM would also move the portal's ETH.
    function test_rejects_chain_with_lockbox_feature_off() public {
        vm.mockCall(
            UNICHAIN_SYSTEM_CONFIG,
            abi.encodeWithSignature("isFeatureEnabled(bytes32)", bytes32("ETH_LOCKBOX")),
            abi.encode(false)
        );
        _expectSetupRevert(CONFIG, "OPCMUpgradeV1000: ETH_LOCKBOX feature not enabled");
    }

    /// @dev The v9 OPCM is a real contract on Sepolia, so the version gate is what rejects it.
    function test_rejects_non_v10_opcm() public {
        _assertSetupReverts("v9-opcm", EXAMPLE_OPCM, SEPOLIA_OPCM_V903, "OPCMUpgradeV1000: incorrect OPCM version");
    }

    /// @dev Only the exact release version is accepted: a dev build with a higher patch passes the on-chain sequence
    /// gate and would lock the chains out of the release OPCM.
    function test_rejects_other_v10_opcm_version() public {
        vm.mockCall(OPCM, abi.encodeWithSignature("version()"), abi.encode("10.0.1"));
        _expectSetupRevert(CONFIG, "OPCMUpgradeV1000: incorrect OPCM version");
    }

    function test_rejects_opcm_with_dev_features() public {
        vm.mockCall(OPCM, abi.encodeWithSignature("devFeatureBitmap()"), abi.encode(bytes32(uint256(1))));
        _expectSetupRevert(CONFIG, "OPCMUpgradeV1000: OPCM has dev features enabled");
    }

    function test_rejects_skip_version_check_on_mainnet() public {
        string memory path = _write(
            "skip-version-check-mainnet",
            _edit(vm.readFile(CONFIG), "skipOPCMVersionCheck = false", "skipOPCMVersionCheck = true")
        );
        OPCMUpgradeV1000SetupHarness harness = new OPCMUpgradeV1000SetupHarness();
        vm.expectRevert(bytes("OPCMUpgradeV1000: skipOPCMVersionCheck is not allowed on mainnet"));
        harness.setupForTestAsMainnet(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice Turns ZK_DISPUTE_GAME on in every entry of the 048 config, with the 050 example's values and `prestate`.
    function _enableZK(string memory config, string memory prestate) internal pure returns (string memory) {
        config = _edit(config, "zkChallengerBond = 0\n", "zkChallengerBond = 1000000000000000000\n");
        config = _edit(config, "zkEnabled = false", "zkEnabled = true");
        config = _edit(config, "zkInitBond = 0\n", "zkInitBond = 80000000000000000\n");
        config = _edit(config, "zkMaxChallengeDuration = 0\n", "zkMaxChallengeDuration = 604800\n");
        config = _edit(config, "zkMaxProveDuration = 0\n", "zkMaxProveDuration = 259200\n");
        return _edit(
            config,
            'zkPrestate = "0x0000000000000000000000000000000000000000000000000000000000000000"',
            string.concat('zkPrestate = "', prestate, '"')
        );
    }

    /// @notice Writes the example config with `from` replaced by `to`, then expects setup to revert with `reason`.
    function _assertSetupReverts(string memory name, string memory from, string memory to, string memory reason)
        internal
    {
        _expectSetupRevert(_write(name, _edit(vm.readFile(CONFIG), from, to)), reason);
    }

    /// @notice Expects setup with the config at `path` to revert with `reason`, then deletes a temporary config.
    function _expectSetupRevert(string memory path, string memory reason) internal {
        OPCMUpgradeV1000SetupHarness harness = new OPCMUpgradeV1000SetupHarness();
        vm.expectRevert(bytes(reason));
        harness.setupForTest(path);
        if (keccak256(bytes(path)) != keccak256(bytes(CONFIG))) MultisigTaskTestHelper.removeFile(path);
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
