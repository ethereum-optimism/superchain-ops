// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMMigrateV1000, IOptimismPortalV1000, ISystemConfigV1000} from "src/template/OPCMMigrateV1000.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";

contract OPCMMigrateV1000SetupHarness is OPCMMigrateV1000 {
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

/// @notice Reports a configurable version, so setup can be tested against OPCM versions that are not deployed.
contract MockOPCMV1000 {
    string public version;

    constructor(string memory _version) {
        version = _version;
    }

    function devFeatureBitmap() external pure returns (bytes32) {
        return bytes32(0);
    }

    function opcmStandardValidator() external view returns (address) {
        return address(this);
    }

    function isPermittedMigrateSequence(address) external pure returns (bool) {
        return true;
    }
}

/// @notice Exercises the `_templateSetup` checks of OPCMMigrateV1000 against the 049 example task.
/// @dev At FORK_BLOCK_NUMBER the example's chains are still on 9.0.3, last upgraded by the v9 OPCM, so the OPCM checks
/// reject the example's v10 OPCM unless the test stubs the chains' `lastUsedOPCM`. OPCMMigrateV1000.t.sol runs the 048
/// upgrade example first and then the whole task.
contract OPCMMigrateV1000SetupValidationTest is Test {
    string constant CONFIG = "test/tasks/example/sep/049-opcm-migrate-v1000/config.toml";
    string constant TESTING_DIRECTORY = "opcm-migrate-v1000";
    uint256 internal constant FORK_BLOCK_NUMBER = 12_162_600;

    address internal constant OPCM = 0xe3D1CC898cd19F4ACE77715259eF942766c1d0D3;
    string constant EXAMPLE_OPCM = 'OPCM = "0xe3D1CC898cd19F4ACE77715259eF942766c1d0D3"';
    // op-contracts/v9.0.0 OPCM on Sepolia, version 9.0.3: the OPCM that last upgraded both chains (sep/115).
    address internal constant SEPOLIA_OPCM_V903 = 0x160f0FE4dC1B3f4026687e8dD4b7F800879939Cc;

    address internal constant UNICHAIN_SEPOLIA_SYSTEM_CONFIG = 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D;
    address internal constant OP_SEPOLIA_PORTAL = 0x16Fc5058F25648194471939df75CF27A2fdC48BC;
    address internal constant OP_SEPOLIA_SYSTEM_CONFIG = 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538;

    string constant EXAMPLE_PRESTATE =
        'cannonKonaPrestate = "0x03e5a54835d39c1d83b198314473e1f111c3539c04f65c3e8a9b8ccebe3737c9"';
    string constant UNKNOWN_PRESTATE =
        'cannonKonaPrestate = "0x0300000000000000000000000000000000000000000000000000000000000001"';
    string constant PRESTATE_NOT_IN_REGISTRY =
        "OPCMMigrateV1000: cannonKonaPrestate is not a cannon64-kona-interop prestate in the registry";

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
    }

    function test_rejects_zero_cannon_kona_prestate() public {
        _assertSetupReverts(
            "zero-prestate",
            EXAMPLE_PRESTATE,
            'cannonKonaPrestate = "0x0000000000000000000000000000000000000000000000000000000000000000"',
            "OPCMMigrateV1000: cannonKonaPrestate is zero"
        );
    }

    function test_rejects_zero_proposer() public {
        _assertSetupReverts(
            "zero-proposer",
            'proposer = "0x9884C33C65111DA7Bbed0e63cD2392F503b135F5"',
            'proposer = "0x0000000000000000000000000000000000000000"',
            "OPCMMigrateV1000: proposer is zero"
        );
    }

    function test_rejects_zero_super_cannon_kona_init_bond() public {
        _assertSetupReverts(
            "zero-bond",
            "superCannonKonaInitBond = 80000000000000000",
            "superCannonKonaInitBond = 0",
            "OPCMMigrateV1000: superCannonKonaInitBond is zero"
        );
    }

    function test_rejects_zero_starting_anchor_root() public {
        _assertSetupReverts(
            "zero-anchor",
            'startingAnchorRootRoot = "0xdead000000000000000000000000000000000000000000000000000000000000"',
            'startingAnchorRootRoot = "0x0000000000000000000000000000000000000000000000000000000000000000"',
            "OPCMMigrateV1000: startingAnchorRootRoot is zero"
        );
    }

    /// @dev A timestamp in milliseconds instead of seconds.
    function test_rejects_future_starting_anchor() public {
        _assertSetupReverts(
            "future-anchor",
            "startingAnchorRootL2SequenceNumber = 1794412446",
            "startingAnchorRootL2SequenceNumber = 1794412446000",
            "OPCMMigrateV1000: startingAnchorRootL2SequenceNumber is in the future"
        );
    }

    function test_rejects_wrong_expected_chain_validation_errors_length() public {
        _assertSetupReverts(
            "chain-errors-length",
            'expectedChainValidationErrors = ["", ""]',
            'expectedChainValidationErrors = [""]',
            "OPCMMigrateV1000: expectedChainValidationErrors must have one entry per chain"
        );
    }

    function test_rejects_chains_out_of_order() public {
        _assertSetupReverts(
            "out-of-order",
            '{name = "Unichain Sepolia Testnet", chainId = 1301},\n    {name = "OP Sepolia Testnet", chainId = 11155420}',
            '{name = "OP Sepolia Testnet", chainId = 11155420},\n    {name = "Unichain Sepolia Testnet", chainId = 1301}',
            "OPCMMigrateV1000: l2chains must be in strictly ascending chainId order"
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
            "OPCMMigrateV1000: all chains must share the same SuperchainConfig"
        );
    }

    function test_rejects_mismatched_finality_delay() public {
        vm.mockCall(
            IOptimismPortalV1000(OP_SEPOLIA_PORTAL).anchorStateRegistry(),
            abi.encodeWithSignature("disputeGameFinalityDelaySeconds()"),
            abi.encode(uint256(1))
        );
        _expectSetupRevert(CONFIG, "OPCMMigrateV1000: all chains must have the same dispute game finality delay");
    }

    function test_rejects_mismatched_delayed_weth_delay() public {
        vm.mockCall(
            ISystemConfigV1000(OP_SEPOLIA_SYSTEM_CONFIG).delayedWETH(),
            abi.encodeWithSignature("delay()"),
            abi.encode(uint256(1))
        );
        _expectSetupRevert(CONFIG, "OPCMMigrateV1000: all chains must have the same DelayedWETH delay");
    }

    /// @dev migrate() re-sets the SUPER_CANNON_KONA bond on the shared game: a value that differs from the chains'
    /// current bond is rejected, not applied.
    function test_rejects_super_cannon_kona_bond_that_differs_from_chains() public {
        _assertSetupReverts(
            "wrong-bond",
            "superCannonKonaInitBond = 80000000000000000",
            "superCannonKonaInitBond = 90000000000000000",
            "OPCMMigrateV1000: superCannonKonaInitBond must equal every chain's current SUPER_CANNON_KONA bond"
        );
    }

    function test_rejects_prestate_not_in_registry() public {
        _assertSetupReverts("unknown-prestate", EXAMPLE_PRESTATE, UNKNOWN_PRESTATE, PRESTATE_NOT_IN_REGISTRY);
    }

    /// @dev The skip list only exempts a set made entirely of chains with custom prestates.
    function test_partial_skip_list_still_checks_prestate() public {
        string memory config = _edit(vm.readFile(CONFIG), EXAMPLE_PRESTATE, UNKNOWN_PRESTATE);
        config = _edit(
            config,
            'templateName = "OPCMMigrateV1000"',
            'templateName = "OPCMMigrateV1000"\nskipPrestateRegistryCheckChainIds = [1301]'
        );
        _expectSetupRevert(_write("partial-skip-list", config), PRESTATE_NOT_IN_REGISTRY);
    }

    function test_rejects_opcm_without_code() public {
        _assertSetupReverts(
            "no-code-opcm",
            EXAMPLE_OPCM,
            'OPCM = "0x000000000000000000000000000000000000dEaD"',
            "OPCMMigrateV1000: OPCM has no code"
        );
    }

    function test_rejects_skip_version_check_on_mainnet() public {
        string memory path = _write(
            "skip-version-check-mainnet",
            _edit(vm.readFile(CONFIG), "skipOPCMVersionCheck = false", "skipOPCMVersionCheck = true")
        );
        OPCMMigrateV1000SetupHarness harness = new OPCMMigrateV1000SetupHarness();
        vm.expectRevert(bytes("OPCMMigrateV1000: skipOPCMVersionCheck is not allowed on mainnet"));
        harness.setupForTestAsMainnet(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @dev The v9 OPCM is a real contract on Sepolia, so the version gate is what rejects it.
    function test_rejects_non_v10_opcm() public {
        _assertSetupReverts(
            "v9-opcm",
            EXAMPLE_OPCM,
            string.concat('OPCM = "', vm.toString(SEPOLIA_OPCM_V903), '"'),
            "OPCMMigrateV1000: incorrect OPCM major version"
        );
    }

    function test_rejects_opcm_with_dev_features() public {
        vm.mockCall(OPCM, abi.encodeWithSignature("devFeatureBitmap()"), abi.encode(bytes32(uint256(1))));
        _expectSetupRevert(CONFIG, "OPCMMigrateV1000: OPCM has dev features enabled");
    }

    /// @dev migrate() keeps each chain's `lastUsedOPCM`, so a set the example's OPCM did not upgrade would be stuck on
    /// the old OPCM afterwards. At FORK_BLOCK_NUMBER both chains were last upgraded by the v9 OPCM.
    function test_rejects_opcm_that_did_not_upgrade_every_chain() public {
        assertEq(ISystemConfigV1000(OP_SEPOLIA_SYSTEM_CONFIG).lastUsedOPCM(), SEPOLIA_OPCM_V903);
        _expectSetupRevert(CONFIG, "OPCMMigrateV1000: OPCM must be the one that upgraded every chain");
    }

    /// @dev Skipping the template's OPCM checks leaves the OPCM's own sequence gate, which requires every chain on v10.
    function test_rejects_chains_not_upgraded_with_opcm_release() public {
        _assertSetupReverts(
            "not-upgraded",
            "skipOPCMVersionCheck = false",
            "skipOPCMVersionCheck = true",
            "OPCMMigrateV1000: chain must be upgraded with this OPCM's release before migrating"
        );
    }

    /// @dev The version gate accepts any 10.x OPCM that upgraded every chain.
    function test_accepts_newer_v10_minor_opcm() public {
        MockOPCMV1000 mock = new MockOPCMV1000("10.1.0");
        _mockLastUsedOPCM(address(mock));
        string memory path = _writeConfigWithOPCM("v1010-opcm", address(mock), false);
        OPCMMigrateV1000SetupHarness harness = new OPCMMigrateV1000SetupHarness();
        harness.setupForTest(path);
        MultisigTaskTestHelper.removeFile(path);
        assertEq(harness.opcm().version(), "10.1.0");
    }

    function test_skip_version_check_accepts_non_v10_opcm() public {
        MockOPCMV1000 mock = new MockOPCMV1000("9.0.3");
        string memory path = _writeConfigWithOPCM("skip-version-check", address(mock), true);
        OPCMMigrateV1000SetupHarness harness = new OPCMMigrateV1000SetupHarness();
        harness.setupForTest(path);
        MultisigTaskTestHelper.removeFile(path);
        assertTrue(harness.skipOPCMVersionCheck());
        assertEq(harness.opcm().version(), "9.0.3");
    }

    function _mockLastUsedOPCM(address opcm) internal {
        address[2] memory systemConfigs = [UNICHAIN_SEPOLIA_SYSTEM_CONFIG, OP_SEPOLIA_SYSTEM_CONFIG];
        for (uint256 i = 0; i < 2; i++) {
            vm.mockCall(systemConfigs[i], abi.encodeWithSignature("lastUsedOPCM()"), abi.encode(opcm));
        }
    }

    /// @notice Writes the example config with its OPCM replaced by `opcm`.
    function _writeConfigWithOPCM(string memory name, address opcm, bool skipVersionCheck)
        internal
        returns (string memory)
    {
        string memory config =
            _edit(vm.readFile(CONFIG), EXAMPLE_OPCM, string.concat('OPCM = "', vm.toString(opcm), '"'));
        if (skipVersionCheck) {
            config = _edit(config, "skipOPCMVersionCheck = false", "skipOPCMVersionCheck = true");
        }
        return _write(name, config);
    }

    /// @notice Writes the example config with `from` replaced by `to`, then expects setup to revert with `reason`.
    function _assertSetupReverts(string memory name, string memory from, string memory to, string memory reason)
        internal
    {
        _expectSetupRevert(_write(name, _edit(vm.readFile(CONFIG), from, to)), reason);
    }

    /// @notice Expects setup with the config at `path` to revert with `reason`, then deletes a temporary config.
    function _expectSetupRevert(string memory path, string memory reason) internal {
        OPCMMigrateV1000SetupHarness harness = new OPCMMigrateV1000SetupHarness();
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
