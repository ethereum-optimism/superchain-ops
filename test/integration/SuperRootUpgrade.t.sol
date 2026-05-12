// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
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

contract SuperRootUpgradeTest is Test, OPCMUpgradeV800 {
    string constant FIXTURES = "test/tasks/example/sep/035-opcm-upgrade-v800/";
    uint256 internal constant FORK_BLOCK_NUMBER = 10_796_650;
    address internal constant ROOT_SAFE = 0xe934Dc97E347C6aCef74364B50125bb8689c40ff;
    uint256 internal chainA;
    uint256 internal chainB;
    address rootSafe;
    address superchainConfig;

    function setUp() public {
        vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"), FORK_BLOCK_NUMBER);
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

        assertEq(chainsToUpgrade.length, chains.length);
        assertEq(chainsToUpgrade[0], chainA);
        assertEq(chainsToUpgrade[1], chainB);

        assertEq(superchainAddrRegistry.getAddress("SuperchainConfig", chainA), superchainConfig);
        assertEq(superchainAddrRegistry.getAddress("SuperchainConfig", chainB), superchainConfig);
        assertEq(superchainAddrRegistry.getAddress("ProxyAdminOwner", chainA), ROOT_SAFE);
        assertEq(superchainAddrRegistry.getAddress("ProxyAdminOwner", chainB), ROOT_SAFE);
        assertEq(
            superchainAddrRegistry.getAddress("SystemConfigProxy", chainA), 0x811a0Bf7d84a717E3b21C47e9E44e34447F5Ce6f
        );
        assertEq(
            superchainAddrRegistry.getAddress("SystemConfigProxy", chainB), 0x822AeD4EBe81A7d626b75B6074110985d61f6dE1
        );
        assertEq(
            superchainAddrRegistry.getAddress("EthLockboxProxy", chainA), 0xC0024116b4e830920d4aF8FC9b1eD43C649b71E1
        );
        assertEq(
            superchainAddrRegistry.getAddress("EthLockboxProxy", chainB), 0x5b581A2D29E5Db7bd30DD6C597c4ba77f9f2E10F
        );

        bytes32 cannonPrestate = 0x03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef;
        bytes32 cannonKonaPrestate = 0x03a7000000000000000000000000000000000000000000000000000000000001;
        assertEq(Claim.unwrap(upgrades[chainA].cannonPrestate), cannonPrestate);
        assertEq(Claim.unwrap(upgrades[chainB].cannonPrestate), cannonPrestate);
        assertEq(Claim.unwrap(upgrades[chainA].cannonKonaPrestate), cannonKonaPrestate);
        assertEq(Claim.unwrap(upgrades[chainB].cannonKonaPrestate), cannonKonaPrestate);
        assertEq(upgrades[chainA].initBond, 0.08 ether);
        assertEq(upgrades[chainB].initBond, 0.08 ether);
        assertEq(upgrades[chainA].startingRespectedGameType, 9);
        assertEq(upgrades[chainB].startingRespectedGameType, 9);
        assertEq(upgrades[chainA].expectedValidationErrors, "OVERRIDES-CHALLENGER");
        assertEq(upgrades[chainB].expectedValidationErrors, "OVERRIDES-CHALLENGER");

        IOPContractsManagerV800.DisputeGameConfig[] memory configs = _buildGameConfigs(chainA);
        assertEq(configs.length, 7);

        uint32[7] memory expectedGameTypes = [uint32(0), 1, 8, 4, 5, 9, 10];
        for (uint256 i = 0; i < configs.length; i++) {
            IOPContractsManagerV800.DisputeGameConfig memory config = configs[i];
            uint32 gameType = expectedGameTypes[i];
            assertEq(config.gameType, gameType);

            if (!config.enabled) {
                /// Games [0,1,4,8]
                assertEq(config.initBond, 0);
                assertEq(config.gameArgs.length, 0);
                continue;
            }

            bool isKona = gameType == 8 || gameType == 9;

            if (gameType == 5) {
                (bytes32 permPrestate, address proposer, address challenger) =
                    abi.decode(config.gameArgs, (bytes32, address, address));
                assertEq(config.initBond, upgrades[chainA].initBond);
                assertEq(permPrestate, Claim.unwrap(upgrades[chainA].cannonPrestate));
                assertEq(proposer, superchainAddrRegistry.getAddress("Proposer", chainA));
                assertEq(challenger, superchainAddrRegistry.getAddress("Challenger", chainA));
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

    function test_starting_respected_game_type_overrides_disabled_guard() public {
        upgrades[chainA].startingRespectedGameType = 9;

        IOPContractsManagerV800.DisputeGameConfig[] memory configs = _buildGameConfigs(chainA);

        assertEq(configs[0].gameType, 0);
        assertFalse(configs[0].enabled);
        assertEq(configs[0].initBond, 0);
        assertEq(configs[0].gameArgs.length, 0);

        assertEq(configs[1].gameType, 1);
        assertFalse(configs[1].enabled);
        assertEq(configs[1].initBond, 0);
        assertEq(configs[1].gameArgs.length, 0);

        assertEq(configs[5].gameType, 9);
        assertTrue(configs[5].enabled);
        assertEq(configs[5].initBond, upgrades[chainA].initBond);
        bytes32 prestate = abi.decode(configs[5].gameArgs, (bytes32));
        assertEq(prestate, Claim.unwrap(upgrades[chainA].cannonKonaPrestate));
    }

    function test_super_permissioned_cannon_is_enabled_by_default() public view {
        assertTrue(_isGameTypeEnabled(IDisputeGameFactory(address(0)), 5, 0));
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
