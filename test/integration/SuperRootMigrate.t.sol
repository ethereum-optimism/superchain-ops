// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim, GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {
    IOPContractsManagerV800,
    ISuperchainConfig,
    IDisputeGameFactory,
    ISystemConfig,
    ISystemConfigV800
} from "src/template/OPCMUpgradeV800.sol";
import {OPCMMigrateV800} from "src/template/OPCMMigrateV800.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

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
    bytes32 internal constant ANCHOR_STATE_REGISTRY_SLOT = bytes32(uint256(62));
    bytes32 internal constant ETH_LOCKBOX_SLOT = bytes32(uint256(63));

    address rootSafe;

    uint32 internal constant CANNON = 0;
    uint32 internal constant PERMISSIONED_CANNON = 1;
    uint32 internal constant CANNON_KONA = 8;
    uint32 internal constant RESERVED_SUPER_CANNON_GAME_TYPE = 4;
    uint32 internal constant ZK_DISPUTE_GAME = 10;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        string memory configTomlPath = string.concat(FIXTURES, "config.toml");
        superchainAddrRegistry = new SuperchainAddressRegistry(configTomlPath);
        _restoreTaskEthLockboxPointers();
        _templateSetup(configTomlPath, address(0));
        address systemConfig = superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_A);
        rootSafe = IProxyAdmin(ISystemConfigExt(systemConfig).proxyAdmin()).owner();
        _upgradeChainFirst();
    }

    function test_load_data() public view {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        assertEq(chains.length, 2);
        assertEq(chains[0].chainId, CHAIN_A);
        assertEq(chains[1].chainId, CHAIN_B);
        assertEq(chainsToMigrate.length, chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            assertEq(rootSafe, superchainAddrRegistry.getAddress("ProxyAdminOwner", chains[i].chainId));
            assertEq(chainsToMigrate[i], chains[i].chainId);
        }

        assertEq(rootSafe, ROOT_SAFE);
        assertEq(chainsToMigrate[0], CHAIN_A);
        assertEq(chainsToMigrate[1], CHAIN_B);
        assertEq(superchainAddrRegistry.getAddress("SuperchainConfig", CHAIN_A), SUPERCHAIN_CONFIG);
        assertEq(superchainAddrRegistry.getAddress("SuperchainConfig", CHAIN_B), SUPERCHAIN_CONFIG);
        assertEq(
            superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_A), 0x811a0Bf7d84a717E3b21C47e9E44e34447F5Ce6f
        );
        assertEq(
            superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_B), 0x822AeD4EBe81A7d626b75B6074110985d61f6dE1
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
        assertEq(migrateParams.expectedValidationErrors, "");
        assertEq(expectedOPCMVersion, "7.1.17");

        assertEq(migrateParams.initBond, 0.08 ether);
        assertEq(migrateParams.startingAnchorRootL2SequenceNumber, 1778004858);
        assertEq(
            migrateParams.startingAnchorRootRoot, 0xc212da871d761b597a3c1531bff571351c974432bdedd1eb67f4e181eb9f49ef
        );
        assertEq(uint256(migrateParams.startingRespectedGameType), 9);

        ISystemConfig[] memory sysCfgs = _chainSystemConfigs();
        assertEq(sysCfgs.length, chains.length);

        IOPContractsManagerV800.DisputeGameConfig[] memory configs = _buildSharedGameConfigs();
        assertEq(configs.length, 2);

        // SUPER_PERMISSIONED_CANNON (5) - permissioned triple.
        assertEq(uint256(configs[0].gameType), 5);
        assertTrue(configs[0].enabled);
        assertEq(configs[0].initBond, migrateParams.initBond);
        (bytes32 permPrestate, address proposer, address challenger) =
            abi.decode(configs[0].gameArgs, (bytes32, address, address));
        assertEq(permPrestate, Claim.unwrap(migrations[CHAIN_A].cannonPrestate));
        assertEq(proposer, migrateParams.superProposer);
        assertEq(challenger, migrateParams.superChallenger);

        // SUPER_CANNON_KONA (9) - non-permissioned single.
        assertEq(uint256(configs[1].gameType), 9);
        assertTrue(configs[1].enabled);
        assertEq(configs[1].initBond, migrateParams.initBond);
        bytes32 konaPrestate = abi.decode(configs[1].gameArgs, (bytes32));
        assertEq(konaPrestate, Claim.unwrap(migrations[CHAIN_A].cannonKonaPrestate));
    }

    function test_migrate_sepolia() public {
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

    function _upgradeChainFirst() internal {
        IOPContractsManagerV800 upgradeOpcm = opcm;

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            ISystemConfigV800 sysCfg =
                ISystemConfigV800(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId));
            address[4] memory candidates = [
                sysCfg.owner(),
                sysCfg.unsafeBlockSigner(),
                sysCfg.batchInbox(),
                address(uint160(uint256(sysCfg.batcherHash())))
            ];
            for (uint256 j = 0; j < candidates.length; j++) {
                if (candidates[j] != address(0) && candidates[j].code.length == 0) {
                    vm.etch(candidates[j], hex"01");
                }
            }
        }
        vm.etch(address(0x0002b8639730E2F4dc88Dfd5Bbd0352E5518A758), hex"01");

        uint256 numCalls = 1 + chains.length;
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](numCalls);

        address sc = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        calls[0] = IMulticall3.Call3({
            target: address(upgradeOpcm),
            allowFailure: false,
            callData: abi.encodeCall(
                IOPContractsManagerV800.upgradeSuperchain,
                (
                    IOPContractsManagerV800.SuperchainUpgradeInput({
                        superchainConfig: ISuperchainConfig(sc),
                        extraInstructions: new IOPContractsManagerV800.ExtraInstruction[](0)
                    })
                )
            )
        });

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            calls[1 + i] = IMulticall3.Call3({
                target: address(upgradeOpcm),
                allowFailure: false,
                callData: abi.encodeWithSelector(
                    IOPContractsManagerV800.upgrade.selector,
                    IOPContractsManagerV800.UpgradeInput({
                        systemConfig: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                        disputeGameConfigs: _buildUpgradeGameConfigs(chainId),
                        extraInstructions: _buildUpgradeExtraInstructions()
                    })
                )
            });
        }

        bytes memory multicallData = abi.encodeCall(IMulticall3.aggregate3, (calls));

        IGnosisSafe safe = IGnosisSafe(rootSafe);
        address[] memory owners = safe.getOwners();
        uint256 threshold = safe.getThreshold();

        bytes32 txHash = safe.getTransactionHash(
            MULTICALL3_DELEGATECALL_ADDRESS,
            0,
            multicallData,
            Enum.Operation.DelegateCall,
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
        bool success = safe.execTransaction(
            MULTICALL3_DELEGATECALL_ADDRESS,
            0,
            multicallData,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            signatures
        );
        require(success, "V800 upgrade failed");
    }

    function _buildUpgradeGameConfigs(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV800.DisputeGameConfig[] memory)
    {
        IDisputeGameFactory factory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));
        address proposer = superchainAddrRegistry.getAddress("Proposer", chainId);
        address challenger = superchainAddrRegistry.getAddress("Challenger", chainId);

        bytes32 cannonKonaPre = Claim.unwrap(migrations[chainId].cannonKonaPrestate);
        uint256 bond = migrateParams.initBond;

        // V2 validation requires exactly 7 entries in this fixed positional order.
        IOPContractsManagerV800.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV800.DisputeGameConfig[](7);
        uint32[7] memory gts = [
            CANNON,
            PERMISSIONED_CANNON,
            CANNON_KONA,
            RESERVED_SUPER_CANNON_GAME_TYPE,
            SUPER_PERMISSIONED_CANNON,
            SUPER_CANNON_KONA,
            ZK_DISPUTE_GAME
        ];

        for (uint256 i = 0; i < 7; i++) {
            uint32 gt = gts[i];
            bool enabled = _isUpgradeGameTypeEnabled(factory, gt);
            bytes memory gameArgs;
            if (enabled) {
                bool isPermissioned = gt == PERMISSIONED_CANNON || gt == SUPER_PERMISSIONED_CANNON;
                bool isKona = gt == CANNON_KONA || gt == SUPER_CANNON_KONA;
                bytes32 prestate = isKona || isPermissioned ? cannonKonaPre : bytes32(0);
                gameArgs = isPermissioned ? abi.encode(prestate, proposer, challenger) : abi.encode(prestate);
            }
            cfgs[i] = IOPContractsManagerV800.DisputeGameConfig({
                enabled: enabled,
                initBond: enabled ? bond : 0,
                gameType: gt,
                gameArgs: gameArgs
            });
        }
        return cfgs;
    }

    function _isUpgradeGameTypeEnabled(IDisputeGameFactory factory, uint32 gt) internal view returns (bool) {
        if (gt == CANNON || gt == PERMISSIONED_CANNON || gt == CANNON_KONA || gt == ZK_DISPUTE_GAME) return false;
        if (gt == RESERVED_SUPER_CANNON_GAME_TYPE) return false;
        if (gt == migrateParams.startingRespectedGameType) return true;
        if (gt == SUPER_PERMISSIONED_CANNON) {
            return address(factory.gameImpls(GameType.wrap(PERMISSIONED_CANNON))) != address(0);
        }
        if (gt == SUPER_CANNON_KONA) return address(factory.gameImpls(GameType.wrap(CANNON_KONA))) != address(0);
        return false;
    }

    function _buildUpgradeExtraInstructions()
        internal
        view
        returns (IOPContractsManagerV800.ExtraInstruction[] memory)
    {
        IOPContractsManagerV800.ExtraInstruction[] memory extras = new IOPContractsManagerV800.ExtraInstruction[](2);
        extras[0] =
            IOPContractsManagerV800.ExtraInstruction({key: "PermittedProxyDeployment", data: bytes("DelayedWETH")});
        extras[1] = IOPContractsManagerV800.ExtraInstruction({
            key: "overrides.cfg.startingRespectedGameType",
            data: abi.encode(migrateParams.startingRespectedGameType)
        });
        return extras;
    }

    function _restoreTaskEthLockboxPointers() internal {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[i].chainId);
            address anchorStateRegistry =
                superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chains[i].chainId);
            address ethLockbox = superchainAddrRegistry.getAddress("EthLockboxProxy", chains[i].chainId);
            vm.store(portal, ANCHOR_STATE_REGISTRY_SLOT, bytes32(uint256(uint160(anchorStateRegistry))));
            vm.store(portal, ETH_LOCKBOX_SLOT, bytes32(uint256(uint160(ethLockbox))));
        }
    }
}
