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
    uint256 internal constant CHAIN_ID = 11155420;

    address rootSafe;

    uint32 internal constant CANNON = 0;
    uint32 internal constant PERMISSIONED_CANNON = 1;
    uint32 internal constant CANNON_KONA = 8;
    uint32 internal constant ZK_DISPUTE_GAME = 10;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        string memory configTomlPath = string.concat(FIXTURES, "config.toml");
        superchainAddrRegistry = new SuperchainAddressRegistry(configTomlPath);
        _templateSetup(configTomlPath, address(0));
        address systemConfig = superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_ID);
        rootSafe = IProxyAdmin(ISystemConfigExt(systemConfig).proxyAdmin()).owner();
        _upgradeChainFirst();
    }

    function test_load_data() public view {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        assertEq(chains.length, 1);
        assertEq(chainsToMigrate.length, chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            assertEq(rootSafe, superchainAddrRegistry.getAddress("ProxyAdminOwner", chains[i].chainId));
            assertEq(chainsToMigrate[i], chains[i].chainId);
        }

        assertEq(chainsToMigrate[0], CHAIN_ID);
        assertEq(Claim.unwrap(migrations[CHAIN_ID].cannonPrestate), bytes32(uint256(0xdead) << 240));
        assertEq(Claim.unwrap(migrations[CHAIN_ID].cannonKonaPrestate), bytes32(uint256(0xdead) << 240));
        assertEq(migrateParams.expectedValidationErrors, "");
        assertEq(expectedOPCMVersion, "7.1.16");

        assertEq(migrateParams.initBond, 0.08 ether);
        assertEq(migrateParams.startingAnchorRootL2SequenceNumber, 0);
        assertEq(migrateParams.startingAnchorRootRoot, bytes32(uint256(0xdead) << 240));
        assertEq(uint256(migrateParams.startingRespectedGameType), 5);

        ISystemConfig[] memory sysCfgs = _chainSystemConfigs();
        assertEq(sysCfgs.length, chains.length);

        IOPContractsManagerV800.DisputeGameConfig[] memory configs = _buildSharedGameConfigs();
        assertEq(configs.length, 2);

        // SUPER_PERMISSIONED_CANNON (5) — permissioned triple.
        assertEq(uint256(configs[0].gameType), 5);
        assertTrue(configs[0].enabled);
        assertEq(configs[0].initBond, migrateParams.initBond);
        (bytes32 permPrestate, address proposer, address challenger) =
            abi.decode(configs[0].gameArgs, (bytes32, address, address));
        assertEq(permPrestate, Claim.unwrap(migrations[CHAIN_ID].cannonPrestate));
        assertEq(proposer, migrateParams.superProposer);
        assertEq(challenger, migrateParams.superChallenger);

        // SUPER_CANNON_KONA (9) — non-permissioned single.
        assertEq(uint256(configs[1].gameType), 9);
        assertTrue(configs[1].enabled);
        assertEq(configs[1].initBond, migrateParams.initBond);
        bytes32 konaPrestate = abi.decode(configs[1].gameArgs, (bytes32));
        assertEq(konaPrestate, Claim.unwrap(migrations[CHAIN_ID].cannonKonaPrestate));
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

        bytes32 cannonPre = Claim.unwrap(migrations[chainId].cannonPrestate);
        bytes32 cannonKonaPre = Claim.unwrap(migrations[chainId].cannonKonaPrestate);
        uint256 bond = migrateParams.initBond;

        // V2 validation requires exactly 7 entries in this fixed positional order.
        IOPContractsManagerV800.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV800.DisputeGameConfig[](7);
        uint32[7] memory gts = [
            CANNON,
            PERMISSIONED_CANNON,
            CANNON_KONA,
            SUPER_CANNON,
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
                bytes32 prestate = isKona ? cannonKonaPre : cannonPre;
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
        if (gt == SUPER_CANNON) return address(factory.gameImpls(GameType.wrap(CANNON))) != address(0);
        if (gt == SUPER_PERMISSIONED_CANNON) {
            return address(factory.gameImpls(GameType.wrap(PERMISSIONED_CANNON))) != address(0);
        }
        if (gt == SUPER_CANNON_KONA) return address(factory.gameImpls(GameType.wrap(CANNON_KONA))) != address(0);
        return false;
    }

    function _buildUpgradeExtraInstructions()
        internal
        pure
        returns (IOPContractsManagerV800.ExtraInstruction[] memory)
    {
        IOPContractsManagerV800.ExtraInstruction[] memory extras = new IOPContractsManagerV800.ExtraInstruction[](2);
        extras[0] =
            IOPContractsManagerV800.ExtraInstruction({key: "PermittedProxyDeployment", data: bytes("DelayedWETH")});
        extras[1] = IOPContractsManagerV800.ExtraInstruction({
            key: "overrides.cfg.startingRespectedGameType",
            data: abi.encode(SUPER_PERMISSIONED_CANNON)
        });
        return extras;
    }
}
