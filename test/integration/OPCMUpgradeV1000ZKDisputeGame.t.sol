// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "solady/utils/LibString.sol";
import {OPCMUpgradeV1000} from "src/template/OPCMUpgradeV1000.sol";
import {OPCMMigrateV1000} from "src/template/OPCMMigrateV1000.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";

interface ISystemConfigZK {
    function disputeGameFactory() external view returns (address);
    function delayedWETH() external view returns (address);
    function isFeatureEnabled(bytes32) external view returns (bool);
    function lastUsedOPCMVersion() external view returns (string memory);
}

interface IOptimismPortalZK {
    function anchorStateRegistry() external view returns (address);
    function ethLockbox() external view returns (address);
}

interface IDisputeGameFactoryZK {
    function gameImpls(uint32) external view returns (address);
    function initBonds(uint32) external view returns (uint256);
    function gameArgs(uint32) external view returns (bytes memory);
}

interface IAnchorStateRegistryZK {
    function respectedGameType() external view returns (uint32);
}

interface IOPContractsManagerZK {
    function opcmStandardValidator() external view returns (address);
}

interface IStandardValidatorZK {
    function sp1PlonkAdapterImpl() external view returns (address);
}

/// @notice Runs the U22 sequence on a Sepolia fork with the 048, 049 and 050 example tasks and the v10 OPCM they
/// point at: ZK_DISPUTE_GAME on chains that are not migrated, the full upgrade -> migrate -> ZK -> SUPER_PERMISSIONED
/// fallback flow, and the guards that sit between those steps.
contract OPCMUpgradeV1000ZKDisputeGameTest is Test {
    using LibString for string;

    string constant UPGRADE_CONFIG = "test/tasks/example/sep/048-opcm-upgrade-v1000/config.toml";
    string constant MIGRATE_CONFIG = "test/tasks/example/sep/049-opcm-migrate-v1000/config.toml";
    string constant ZK_CONFIG = "test/tasks/example/sep/050-opcm-upgrade-v1000-zk/config.toml";
    string constant TESTING_DIRECTORY = "opcm-upgrade-v1000-zk";
    uint256 internal constant FORK_BLOCK_NUMBER = 12_162_600;

    address internal constant OPCM = 0xe3D1CC898cd19F4ACE77715259eF942766c1d0D3;
    address internal constant FOUNDATION_UPGRADE_SAFE = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B;

    address internal constant UNICHAIN_SEPOLIA_SYSTEM_CONFIG = 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D;
    address internal constant UNICHAIN_SEPOLIA_PORTAL = 0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD;
    address internal constant OP_SEPOLIA_SYSTEM_CONFIG = 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538;
    address internal constant OP_SEPOLIA_PORTAL = 0x16Fc5058F25648194471939df75CF27A2fdC48BC;

    uint32 internal constant SUPER_PERMISSIONED = 5;
    uint32 internal constant SUPER_CANNON_KONA = 9;
    uint32 internal constant ZK_DISPUTE_GAME = 10;
    bytes32 internal constant INTEROP = "INTEROP";

    // The 050 example's ZK_DISPUTE_GAME values.
    bytes32 internal constant ZK_PRESTATE = 0x007a57c684472769fa73877d2fae9feef79fb64a5f833f8e4fe40ed63ca4286c;
    uint64 internal constant ZK_MAX_CHALLENGE_DURATION = 604800;
    uint64 internal constant ZK_MAX_PROVE_DURATION = 259200;
    uint256 internal constant ZK_CHALLENGER_BOND = 1 ether;
    uint256 internal constant ZK_INIT_BOND = 0.08 ether;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
    }

    /// @notice upgrade (048) -> migrate (049) -> ZK (050) -> SUPER_PERMISSIONED fallback, with the guards between.
    function test_u22_flow() public {
        _simulateUpgrade(UPGRADE_CONFIG);
        for (uint256 i = 0; i < 2; i++) {
            address sysCfg = _systemConfigs()[i];
            assertEq(ISystemConfigZK(sysCfg).lastUsedOPCMVersion(), "10.0.0");
            assertFalse(ISystemConfigZK(sysCfg).isFeatureEnabled(INTEROP));
            assertEq(_respectedGameType(_portals()[i]), SUPER_CANNON_KONA);
            assertTrue(_dgf(sysCfg).gameImpls(SUPER_CANNON_KONA) != address(0));
            assertEq(_dgf(sysCfg).gameImpls(ZK_DISPUTE_GAME), address(0));
        }
        assertTrue(_dgf(UNICHAIN_SEPOLIA_SYSTEM_CONFIG) != _dgf(OP_SEPOLIA_SYSTEM_CONFIG), "dgfs shared before migrate");

        new OPCMMigrateV1000().simulate(MIGRATE_CONFIG, FOUNDATION_UPGRADE_SAFE);
        _assertMigrated();

        // Both upgrade() calls rewrite the shared factory, so the entries must agree.
        _assertSimulateReverts(
            ZK_CONFIG,
            "zkInitBond = 80000000000000000 # Placeholder: 0.08 ETH",
            "zkInitBond = 90000000000000000",
            "OPCMUpgradeV1000: chains sharing a DisputeGameFactory must use identical game configs"
        );

        _simulateUpgrade(ZK_CONFIG);
        IDisputeGameFactoryZK shared = _dgf(OP_SEPOLIA_SYSTEM_CONFIG);
        assertEq(_respectedGameType(OP_SEPOLIA_PORTAL), ZK_DISPUTE_GAME);
        assertEq(shared.gameImpls(SUPER_CANNON_KONA), address(0));
        assertEq(shared.initBonds(SUPER_CANNON_KONA), 0);
        assertEq(shared.initBonds(ZK_DISPUTE_GAME), ZK_INIT_BOND);
        _assertZKArgs(OP_SEPOLIA_SYSTEM_CONFIG, OP_SEPOLIA_PORTAL);

        // A re-run carries the live ZK bond forward; changing it takes SetDisputeGameArgs.
        _assertSimulateReverts(
            ZK_CONFIG,
            "zkInitBond = 80000000000000000",
            "zkInitBond = 90000000000000000",
            "OPCMUpgradeV1000: zkInitBond must equal the chain's current ZK_DISPUTE_GAME bond"
        );

        _simulateEditedUpgrade(
            "fallback",
            _edit(
                vm.readFile(ZK_CONFIG),
                "startingRespectedGameType = 10 # ZK_DISPUTE_GAME",
                "startingRespectedGameType = 5"
            )
        );
        assertEq(_respectedGameType(OP_SEPOLIA_PORTAL), SUPER_PERMISSIONED);
        assertEq(_respectedGameType(UNICHAIN_SEPOLIA_PORTAL), SUPER_PERMISSIONED);
        assertTrue(shared.gameImpls(ZK_DISPUTE_GAME) != address(0), "fallback removed ZK_DISPUTE_GAME");
    }

    /// @notice ZK_DISPUTE_GAME on chains that are not migrated, each on its own factory. migrate() would drop the live
    /// ZK game, so it is refused until a re-run disables ZK; ZK is then enabled again on the migrated set.
    function test_zk_before_migration() public {
        _simulateEditedUpgrade("zk-unmigrated", _enableZK(vm.readFile(UPGRADE_CONFIG)));
        for (uint256 i = 0; i < 2; i++) {
            address sysCfg = _systemConfigs()[i];
            assertFalse(ISystemConfigZK(sysCfg).isFeatureEnabled(INTEROP));
            assertEq(_respectedGameType(_portals()[i]), ZK_DISPUTE_GAME);
            assertTrue(_dgf(sysCfg).gameImpls(SUPER_CANNON_KONA) != address(0));
            assertEq(_dgf(sysCfg).initBonds(ZK_DISPUTE_GAME), ZK_INIT_BOND);
            _assertZKArgs(sysCfg, _portals()[i]);
        }
        assertTrue(_dgf(UNICHAIN_SEPOLIA_SYSTEM_CONFIG) != _dgf(OP_SEPOLIA_SYSTEM_CONFIG), "dgfs shared before migrate");

        OPCMMigrateV1000 migrate = new OPCMMigrateV1000();
        vm.expectRevert(
            bytes("OPCMMigrateV1000: chain has a live ZK_DISPUTE_GAME that migrate() would remove; disable it first")
        );
        migrate.simulate(MIGRATE_CONFIG, FOUNDATION_UPGRADE_SAFE);

        // Re-run 048 to disable ZK. Its nonce overrides only apply to the first task at FORK_BLOCK_NUMBER.
        _simulateEditedUpgrade("zk-disabled", _withoutStateOverrides(vm.readFile(UPGRADE_CONFIG)));
        for (uint256 i = 0; i < 2; i++) {
            assertEq(_dgf(_systemConfigs()[i]).gameImpls(ZK_DISPUTE_GAME), address(0));
            assertEq(_respectedGameType(_portals()[i]), SUPER_CANNON_KONA);
        }

        new OPCMMigrateV1000().simulate(MIGRATE_CONFIG, FOUNDATION_UPGRADE_SAFE);
        _assertMigrated();

        _simulateUpgrade(ZK_CONFIG);
        assertEq(_respectedGameType(UNICHAIN_SEPOLIA_PORTAL), ZK_DISPUTE_GAME);
        _assertZKArgs(UNICHAIN_SEPOLIA_SYSTEM_CONFIG, UNICHAIN_SEPOLIA_PORTAL);
    }

    /// @notice Decodes the 140-byte ZK_DISPUTE_GAME args the OPCM packs (prestate | verifier | maxChallengeDuration |
    /// maxProveDuration | challengerBond | anchorStateRegistry | weth) and checks every field against the config and
    /// the chain's own dispute contracts.
    function _assertZKArgs(address sysCfg, address portal) internal view {
        bytes memory args = _dgf(sysCfg).gameArgs(ZK_DISPUTE_GAME);
        assertEq(args.length, 140, "zk args length");
        bytes32 prestate;
        address verifier;
        uint64 maxChallenge;
        uint64 maxProve;
        uint256 challengerBond;
        address asr;
        address weth;
        assembly {
            prestate := mload(add(args, 32))
            verifier := shr(96, mload(add(args, 64)))
            maxChallenge := shr(192, mload(add(args, 84)))
            maxProve := shr(192, mload(add(args, 92)))
            challengerBond := mload(add(args, 100))
            asr := shr(96, mload(add(args, 132)))
            weth := shr(96, mload(add(args, 152)))
        }
        address validator = IOPContractsManagerZK(OPCM).opcmStandardValidator();
        assertEq(prestate, ZK_PRESTATE, "zk prestate");
        assertEq(verifier, IStandardValidatorZK(validator).sp1PlonkAdapterImpl(), "zk verifier");
        assertEq(maxChallenge, ZK_MAX_CHALLENGE_DURATION, "zk max challenge duration");
        assertEq(maxProve, ZK_MAX_PROVE_DURATION, "zk max prove duration");
        assertEq(challengerBond, ZK_CHALLENGER_BOND, "zk challenger bond");
        assertEq(asr, IOptimismPortalZK(portal).anchorStateRegistry(), "zk anchor state registry");
        assertEq(weth, ISystemConfigZK(sysCfg).delayedWETH(), "zk weth");
    }

    function _assertMigrated() internal view {
        assertEq(address(_dgf(UNICHAIN_SEPOLIA_SYSTEM_CONFIG)), address(_dgf(OP_SEPOLIA_SYSTEM_CONFIG)), "shared dgf");
        assertEq(
            IOptimismPortalZK(UNICHAIN_SEPOLIA_PORTAL).anchorStateRegistry(),
            IOptimismPortalZK(OP_SEPOLIA_PORTAL).anchorStateRegistry(),
            "shared asr"
        );
        assertEq(
            IOptimismPortalZK(UNICHAIN_SEPOLIA_PORTAL).ethLockbox(),
            IOptimismPortalZK(OP_SEPOLIA_PORTAL).ethLockbox(),
            "shared lockbox"
        );
        assertTrue(ISystemConfigZK(UNICHAIN_SEPOLIA_SYSTEM_CONFIG).isFeatureEnabled(INTEROP));
        assertTrue(ISystemConfigZK(OP_SEPOLIA_SYSTEM_CONFIG).isFeatureEnabled(INTEROP));
        assertEq(_respectedGameType(OP_SEPOLIA_PORTAL), SUPER_CANNON_KONA);
    }

    function _simulateUpgrade(string memory config) internal {
        new OPCMUpgradeV1000().simulate(config, FOUNDATION_UPGRADE_SAFE);
    }

    /// @notice Simulates an edited upgrade config from a temporary file, then deletes the file.
    function _simulateEditedUpgrade(string memory name, string memory config) internal {
        string memory path = _write(name, config);
        _simulateUpgrade(path);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice Simulates `config` with `from` replaced by `to` and expects it to revert with `reason`.
    function _assertSimulateReverts(string memory config, string memory from, string memory to, string memory reason)
        internal
    {
        string memory path = _write(to, _edit(vm.readFile(config), from, to));
        OPCMUpgradeV1000 task = new OPCMUpgradeV1000();
        vm.expectRevert(bytes(reason));
        task.simulate(path, FOUNDATION_UPGRADE_SAFE);
        MultisigTaskTestHelper.removeFile(path);
    }

    /// @notice Turns ZK_DISPUTE_GAME on in every entry of the 048 config with the 050 values, and respects it. SUPER
    /// CANNON_KONA stays registered.
    function _enableZK(string memory config) internal pure returns (string memory) {
        config = _edit(config, "zkChallengerBond = 0\n", "zkChallengerBond = 1000000000000000000\n");
        config = _edit(config, "zkEnabled = false", "zkEnabled = true");
        config = _edit(config, "zkInitBond = 0\n", "zkInitBond = 80000000000000000\n");
        config = _edit(config, "zkMaxChallengeDuration = 0\n", "zkMaxChallengeDuration = 604800\n");
        config = _edit(config, "zkMaxProveDuration = 0\n", "zkMaxProveDuration = 259200\n");
        config = _edit(
            config,
            'zkPrestate = "0x0000000000000000000000000000000000000000000000000000000000000000"',
            string.concat('zkPrestate = "', vm.toString(ZK_PRESTATE), '"')
        );
        return _edit(
            config, "startingRespectedGameType = 9 # SUPER_CANNON_KONA, unchanged", "startingRespectedGameType = 10"
        );
    }

    /// @notice Drops the `[stateOverrides]` section, which pins the safe nonces at FORK_BLOCK_NUMBER.
    function _withoutStateOverrides(string memory config) internal pure returns (string memory) {
        uint256 start = config.indexOf("\n[stateOverrides]");
        assertTrue(start != LibString.NOT_FOUND, "no stateOverrides section");
        return config.slice(0, start + 1);
    }

    function _dgf(address sysCfg) internal view returns (IDisputeGameFactoryZK) {
        return IDisputeGameFactoryZK(ISystemConfigZK(sysCfg).disputeGameFactory());
    }

    function _respectedGameType(address portal) internal view returns (uint32) {
        return IAnchorStateRegistryZK(IOptimismPortalZK(portal).anchorStateRegistry()).respectedGameType();
    }

    function _systemConfigs() internal pure returns (address[2] memory) {
        return [UNICHAIN_SEPOLIA_SYSTEM_CONFIG, OP_SEPOLIA_SYSTEM_CONFIG];
    }

    function _portals() internal pure returns (address[2] memory) {
        return [UNICHAIN_SEPOLIA_PORTAL, OP_SEPOLIA_PORTAL];
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
