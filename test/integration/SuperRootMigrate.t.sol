// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IOPContractsManagerV800, ISystemConfig} from "src/template/OPCMUpgradeV800.sol";
import {OPCMMigrateV800} from "src/template/OPCMMigrateV800.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
}

interface ISystemConfigExt {
    function proxyAdmin() external view returns (address);
}

contract SuperRootMigrateTest is Test, OPCMMigrateV800 {
    string constant FIXTURES = "test/tasks/example/sep/036-opcm-migrate-v800/";

    uint256 internal constant CHAIN_A = 420120084;
    uint256 internal constant CHAIN_B = 420120085;

    address internal constant ROOT_SAFE = 0xe934Dc97E347C6aCef74364B50125bb8689c40ff;
    address internal constant SUPERCHAIN_CONFIG = 0xbb331C0Bf409ef6B39CF585221fa4FF73001668a;
    address rootSafe;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        string memory configTomlPath = string.concat(FIXTURES, "config.toml");
        superchainAddrRegistry = new SuperchainAddressRegistry(configTomlPath);
        _templateSetup(configTomlPath, address(0));
        address systemConfig = superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_A);
        rootSafe = IProxyAdmin(ISystemConfigExt(systemConfig).proxyAdmin()).owner();
    }

    function test_load_data_from_inline_devnet_tables() public view {
        assertEq(rootSafe, superchainAddrRegistry.getAddress("ProxyAdminOwner", CHAIN_A));

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        assertEq(chains.length, 2);
        assertEq(chains[0].chainId, CHAIN_A);
        assertEq(chains[1].chainId, CHAIN_B);

        assertEq(chainsToMigrate.length, chains.length);
        assertEq(chainsToMigrate[0], CHAIN_A);
        assertEq(chainsToMigrate[1], CHAIN_B);

        assertEq(superchainAddrRegistry.getAddress("SuperchainConfig", CHAIN_A), SUPERCHAIN_CONFIG);
        assertEq(superchainAddrRegistry.getAddress("SuperchainConfig", CHAIN_B), SUPERCHAIN_CONFIG);
        assertEq(superchainAddrRegistry.getAddress("ProxyAdminOwner", CHAIN_A), ROOT_SAFE);
        assertEq(superchainAddrRegistry.getAddress("ProxyAdminOwner", CHAIN_B), ROOT_SAFE);
        assertEq(
            superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_A), 0x811a0Bf7d84a717E3b21C47e9E44e34447F5Ce6f
        );
        assertEq(
            superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_B), 0x822AeD4EBe81A7d626b75B6074110985d61f6dE1
        );
        assertEq(
            superchainAddrRegistry.getAddress("OptimismMintableERC20FactoryProxy", CHAIN_A),
            0x116AEB72052fea90B1647F8EEaA7dfD02dbD7470
        );
        assertEq(
            superchainAddrRegistry.getAddress("OptimismMintableERC20FactoryProxy", CHAIN_B),
            0x4332eAfFE3b1Af78dd18418e9d30eB27598540Ac
        );
        assertEq(
            superchainAddrRegistry.getAddress("EthLockboxProxy", CHAIN_A), 0xC0024116b4e830920d4aF8FC9b1eD43C649b71E1
        );
        assertEq(
            superchainAddrRegistry.getAddress("EthLockboxProxy", CHAIN_B), 0x5b581A2D29E5Db7bd30DD6C597c4ba77f9f2E10F
        );

        bytes32 cannonPrestate = 0x03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef;
        bytes32 cannonKonaPrestate = 0x03a7000000000000000000000000000000000000000000000000000000000001;
        assertEq(Claim.unwrap(migrations[CHAIN_A].cannonPrestate), cannonPrestate);
        assertEq(Claim.unwrap(migrations[CHAIN_B].cannonPrestate), cannonPrestate);
        assertEq(Claim.unwrap(migrations[CHAIN_A].cannonKonaPrestate), cannonKonaPrestate);
        assertEq(Claim.unwrap(migrations[CHAIN_B].cannonKonaPrestate), cannonKonaPrestate);
        assertEq(expectedOPCMVersion, "7.1.17");

        assertEq(migrateParams.expectedValidationErrors, "");
        assertEq(migrateParams.initBond, 0.08 ether);
        assertEq(migrateParams.startingAnchorRootL2SequenceNumber, 0);
        assertEq(migrateParams.startingAnchorRootRoot, bytes32(uint256(0xdead) << 240));
        assertEq(uint256(migrateParams.startingRespectedGameType), 5);
        assertEq(migrateParams.superProposer, 0x000c245B7a2e946C9EeE6b488f1Da07aF15Ad4f4);
        assertEq(migrateParams.superChallenger, 0x293204BFA7f28C4A4275b377CcAFd525d2225D37);

        ISystemConfig[] memory sysCfgs = _chainSystemConfigs();
        assertEq(sysCfgs.length, 2);
        assertEq(address(sysCfgs[0]), superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_A));
        assertEq(address(sysCfgs[1]), superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_B));

        IOPContractsManagerV800.DisputeGameConfig[] memory configs = _buildSharedGameConfigs();
        assertEq(configs.length, 2);

        assertEq(uint256(configs[0].gameType), 5);
        assertTrue(configs[0].enabled);
        assertEq(configs[0].initBond, migrateParams.initBond);
        (bytes32 permPrestate, address proposer, address challenger) =
            abi.decode(configs[0].gameArgs, (bytes32, address, address));
        assertEq(permPrestate, cannonPrestate);
        assertEq(proposer, migrateParams.superProposer);
        assertEq(challenger, migrateParams.superChallenger);

        assertEq(uint256(configs[1].gameType), 9);
        assertTrue(configs[1].enabled);
        assertEq(configs[1].initBond, migrateParams.initBond);
        assertEq(abi.decode(configs[1].gameArgs, (bytes32)), cannonKonaPrestate);
    }

    function test_migrate_devnet() public {
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
