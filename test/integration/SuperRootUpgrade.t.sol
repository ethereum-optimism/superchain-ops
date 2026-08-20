// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IDisputeGameFactory, IOPContractsManagerV800, OPCMUpgradeV800} from "src/template/OPCMUpgradeV800.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
}

interface ISystemConfigExt {
    function proxyAdmin() external view returns (address);
    function superchainConfig() external view returns (address);
}

contract OPCMUpgradeV800SetupHarness is OPCMUpgradeV800 {
    function setupForTest(string memory configPath) external {
        superchainAddrRegistry = new SuperchainAddressRegistry(configPath);
        _templateSetup(configPath, address(0));
    }
}

contract SuperRootUpgradeSetupValidationTest is Test, OPCMUpgradeV800 {
    string constant FIXTURES = "test/tasks/example/sep/035-opcm-upgrade-v800/";
    string constant INVALID_CONFIG =
        "test/tasks/example/sep/035-opcm-upgrade-v800/opcm-upgrade-v800-cannon-starting-game-type.toml";
    uint256 internal constant FORK_BLOCK_NUMBER = 11_500_000;

    function test_rejects_non_super_starting_respected_game_type() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
        string memory config = vm.readFile(string.concat(FIXTURES, "config.toml"));
        config = vm.replace(config, "startingRespectedGameType = 9", "startingRespectedGameType = 8");
        vm.writeFile(INVALID_CONFIG, config);

        OPCMUpgradeV800SetupHarness harness = new OPCMUpgradeV800SetupHarness();
        vm.expectRevert("OPCMUpgradeV800: startingRespectedGameType must be a super game type (5 or 9)");
        harness.setupForTest(INVALID_CONFIG);
    }
}

contract SuperRootUpgradeTest is Test, OPCMUpgradeV800 {
    string constant FIXTURES = "test/tasks/example/sep/035-opcm-upgrade-v800/";
    uint256 internal constant FORK_BLOCK_NUMBER = 11_500_000;
    address internal constant ROOT_SAFE = 0xe934Dc97E347C6aCef74364B50125bb8689c40ff;
    uint256 internal chainA;
    uint256 internal chainB;
    address rootSafe;
    address superchainConfig;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
        string memory configTomlPath = string.concat(FIXTURES, "config.toml");
        superchainAddrRegistry = new SuperchainAddressRegistry(configTomlPath);
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        chainA = chains[0].chainId;
        chainB = chains[1].chainId;
        superchainConfig = superchainAddrRegistry.getAddress("SuperchainConfig", chainA);
        _templateSetup(configTomlPath, address(0));
        address systemConfig = superchainAddrRegistry.getAddress("SystemConfigProxy", chainA);
        rootSafe = IProxyAdmin(ISystemConfigExt(systemConfig).proxyAdmin()).owner();
    }

    function test_load_data() public view {
        assertEq(rootSafe, ROOT_SAFE);

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        assertEq(chains.length, 2);
        assertEq(chains[0].chainId, chainA);
        assertEq(chains[1].chainId, chainB);
        assertEq(chainA, 420130015);
        assertEq(chainB, 420130018);

        assertEq(chainsToUpgrade.length, chains.length);
        assertEq(chainsToUpgrade[0], chainA);
        assertEq(chainsToUpgrade[1], chainB);

        assertEq(superchainAddrRegistry.getAddress("SuperchainConfig", chainA), superchainConfig);
        // sepolia-devnet-3 resolves through registry discovery and must share the
        // same SuperchainConfig (enforced by _templateSetup).
        assertEq(superchainAddrRegistry.getAddress("SuperchainConfig", chainB), superchainConfig);
        assertEq(superchainConfig, 0x289d2A1b1AE6E0470D8B72E53B6E3f485f251DBb);
        assertEq(superchainAddrRegistry.getAddress("ProxyAdminOwner", chainA), ROOT_SAFE);
        assertEq(superchainAddrRegistry.getAddress("ProxyAdminOwner", chainB), ROOT_SAFE);
        assertEq(
            superchainAddrRegistry.getAddress("SystemConfigProxy", chainA), 0x5F91Ea5EEA70E505b457A442Dc7A8e5D9641b937
        );
        assertEq(
            superchainAddrRegistry.getAddress("SystemConfigProxy", chainB), 0x66dac055c7cD3B3a043760521dCa840cB3E8F3FF
        );

        // op-contracts/v8.0.0-rc.2 standard prestates: cannon 1.9.0 `interop` and
        // kona 1.6.0 `cannon64-kona-interop`.
        bytes32 cannonPrestate = 0x03b985a286da46ca88c0a965a53942daade9ffe1ae6b854a8f2d083df1cfaf59;
        bytes32 cannonKonaPrestate = 0x03e3a42cf9a1d116f414206c465c6cdb74556136090e7c9556329403da0f310f;
        assertEq(Claim.unwrap(upgrades[chainA].cannonPrestate), cannonPrestate);
        assertEq(Claim.unwrap(upgrades[chainA].cannonKonaPrestate), cannonKonaPrestate);
        assertEq(upgrades[chainA].initBond, 0.08 ether);
        assertEq(upgrades[chainA].startingRespectedGameType, 9);
        assertEq(
            upgrades[chainA].startingAnchorRootRoot, 0xdead000000000000000000000000000000000000000000000000000000000000
        );
        assertEq(upgrades[chainA].startingAnchorRootL2SequenceNumber, 1786000000);
        assertEq(upgrades[chainA].expectedValidationErrors, "OVERRIDES-L1PAOMULTISIG,OVERRIDES-CHALLENGER,SYSCON-130");

        assertEq(Claim.unwrap(upgrades[chainB].cannonPrestate), cannonPrestate);
        assertEq(Claim.unwrap(upgrades[chainB].cannonKonaPrestate), cannonKonaPrestate);
        assertEq(upgrades[chainB].startingRespectedGameType, 5);

        // sepolia-devnet-3 is permissioned-only: no CANNON_KONA impl in its factory, so
        // SUPER_CANNON_KONA (9) stays disabled and only SUPER_PERMISSIONED (5) is enabled.
        // This exercises the factory-impl branch of _isGameTypeEnabled for gt=9.
        IOPContractsManagerV800.DisputeGameConfig[] memory configsB = _buildGameConfigs(chainB);
        assertEq(configsB.length, 6);
        for (uint256 i = 0; i < configsB.length; i++) {
            if (configsB[i].gameType == 5) {
                assertTrue(configsB[i].enabled);
                assertEq(configsB[i].initBond, 0);
                assertEq(configsB[i].gameArgs.length, 32);
                address proposerB = abi.decode(configsB[i].gameArgs, (address));
                assertEq(proposerB, superchainAddrRegistry.getAddress("Proposer", chainB));
            } else {
                assertFalse(configsB[i].enabled);
                assertEq(configsB[i].initBond, 0);
                assertEq(configsB[i].gameArgs.length, 0);
            }
        }

        IOPContractsManagerV800.DisputeGameConfig[] memory configs = _buildGameConfigs(chainA);
        assertEq(configs.length, 6);

        uint32[6] memory expectedGameTypes = [uint32(0), 1, 8, 5, 9, 10];
        for (uint256 i = 0; i < configs.length; i++) {
            IOPContractsManagerV800.DisputeGameConfig memory config = configs[i];
            uint32 gameType = expectedGameTypes[i];
            assertEq(config.gameType, gameType);

            if (!config.enabled) {
                /// Games [0,1,8,10]
                assertEq(config.initBond, 0);
                assertEq(config.gameArgs.length, 0);
                continue;
            }

            bool isKona = gameType == 8 || gameType == 9;

            if (gameType == 5) {
                // SUPER_PERMISSIONED does not use bonds; the v8 OPCM requires initBond == 0.
                assertEq(config.initBond, 0);
                assertEq(config.gameArgs.length, 32);
                address proposer = abi.decode(config.gameArgs, (address));
                assertEq(proposer, superchainAddrRegistry.getAddress("Proposer", chainA));
            } else {
                assertEq(config.initBond, upgrades[chainA].initBond);
                bytes32 prestate = abi.decode(config.gameArgs, (bytes32));
                if (isKona) {
                    assertEq(prestate, Claim.unwrap(upgrades[chainA].cannonKonaPrestate));
                } else {
                    assertEq(prestate, Claim.unwrap(upgrades[chainA].cannonPrestate));
                }
            }
        }
    }

    function test_super_permissioned_cannon_is_enabled_by_default() public view {
        assertTrue(_isGameTypeEnabled(IDisputeGameFactory(address(0)), 5, 0));
    }

    /// @notice Exercises the U20 rotation where a chain currently respecting
    /// CANNON_KONA (gt=8) transitions to SUPER_CANNON_KONA (gt=9): the retiring base
    /// games stay disabled (their impls get cleared), the simplified SUPER_PERMISSIONED
    /// (gt=5) game is installed as the permissioned fallback, and SUPER_CANNON_KONA is
    /// enabled both via the startingRespectedGameType override and the existing
    /// CANNON_KONA impl in the factory.
    function test_upgrade_cannon_kona_to_super_cannon_kona() public {
        upgrades[chainA].startingRespectedGameType = 9;

        IOPContractsManagerV800.DisputeGameConfig[] memory configs = _buildGameConfigs(chainA);

        // _buildGameConfigs order: [CANNON, PERMISSIONED_CANNON, CANNON_KONA,
        // SUPER_PERMISSIONED, SUPER_CANNON_KONA, ZK_DISPUTE_GAME]
        assertEq(configs.length, 6);

        // Base games stay disabled.
        assertEq(configs[0].gameType, 0);
        assertFalse(configs[0].enabled);
        assertEq(configs[0].initBond, 0);
        assertEq(configs[0].gameArgs.length, 0);

        assertEq(configs[1].gameType, 1);
        assertFalse(configs[1].enabled);
        assertEq(configs[1].initBond, 0);
        assertEq(configs[1].gameArgs.length, 0);

        // SUPER_PERMISSIONED (gt=5) is always enabled with proposer-only encoding and no bond.
        assertEq(configs[3].gameType, 5);
        assertTrue(configs[3].enabled);
        assertEq(configs[3].initBond, 0);
        assertEq(configs[3].gameArgs.length, 32);
        address proposer = abi.decode(configs[3].gameArgs, (address));
        assertEq(proposer, superchainAddrRegistry.getAddress("Proposer", chainA));

        // SUPER_CANNON_KONA (gt=9) is enabled with permissionless encoding.
        assertEq(configs[4].gameType, 9);
        assertTrue(configs[4].enabled);
        assertEq(configs[4].initBond, upgrades[chainA].initBond);
        bytes32 konaPrestate = abi.decode(configs[4].gameArgs, (bytes32));
        assertEq(konaPrestate, Claim.unwrap(upgrades[chainA].cannonKonaPrestate));
    }

    function test_upgrade_sepolia() public {
        Action[] memory actions = build(rootSafe);
        assertGt(actions.length, 0);

        _executeActions(actions);

        _validate(new VmSafe.AccountAccess[](0), actions, rootSafe);
    }

    function _executeActions(Action[] memory actions) internal {
        IGnosisSafe safe = IGnosisSafe(rootSafe);
        address[] memory owners = safe.getOwners();
        uint256 threshold = safe.getThreshold();

        for (uint256 i = 0; i < actions.length; i++) {
            bytes32 txHash = safe.getTransactionHash(
                actions[i].target,
                actions[i].value,
                actions[i].arguments,
                actions[i].operation,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                safe.nonce()
            );

            for (uint256 j = 0; j < threshold; j++) {
                vm.prank(owners[j]);
                safe.approveHash(txHash);
            }

            bytes memory signatures = _buildApprovedHashSignatures(owners, threshold);
            safe.execTransaction(
                actions[i].target,
                actions[i].value,
                actions[i].arguments,
                actions[i].operation,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                signatures
            );
        }
    }

    function _buildApprovedHashSignatures(address[] memory owners, uint256 threshold)
        internal
        pure
        returns (bytes memory)
    {
        address[] memory signers = new address[](threshold);
        for (uint256 i = 0; i < threshold; i++) {
            signers[i] = owners[i];
        }
        for (uint256 i = 0; i < threshold; i++) {
            for (uint256 j = i + 1; j < threshold; j++) {
                if (signers[i] > signers[j]) {
                    (signers[i], signers[j]) = (signers[j], signers[i]);
                }
            }
        }
        bytes memory sigs;
        for (uint256 i = 0; i < threshold; i++) {
            sigs = abi.encodePacked(sigs, bytes32(uint256(uint160(signers[i]))), bytes32(0), uint8(1));
        }
        return sigs;
    }
}
