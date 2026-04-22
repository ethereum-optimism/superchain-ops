// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IOPContractsManagerV700} from "src/template/OPCMUpgradeV700.sol";
import {OPCMMigrateV700} from "src/template/OPCMMigrateV700.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
}

interface ISystemConfigExt {
    function proxyAdmin() external view returns (address);
}

contract SuperRootMigrateTest is Test, OPCMMigrateV700 {
    using stdToml for string;

    string constant FIXTURES = "test/tasks/example/sep/036-opcm-migrate-v700/";
    uint256 internal constant CHAIN_ID = 11155420;

    address rootSafe;
    bool internal _scaffoldingSkipped;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        string memory configTomlPath = string.concat(FIXTURES, "config.toml");

        // SCAFFOLDING GUARD: the fixture ships with OPCM=0 placeholder. Skip every test here
        // until a v7.1.16 OPCM with migrator is wired in.
        string memory tomlContent = vm.readFile(configTomlPath);
        address configOPCM = tomlContent.readAddress(".addresses.OPCM");
        if (configOPCM == address(0)) {
            _scaffoldingSkipped = true;
            return;
        }

        superchainAddrRegistry = new SuperchainAddressRegistry(configTomlPath);
        _templateSetup(configTomlPath, address(0));
        address systemConfig = superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_ID);
        rootSafe = IProxyAdmin(ISystemConfigExt(systemConfig).proxyAdmin()).owner();
    }

    function test_load_data() public view {
        if (_scaffoldingSkipped) return;

        assertEq(rootSafe, superchainAddrRegistry.getAddress("ProxyAdminOwner", CHAIN_ID));
        assertEq(chainsToMigrate.length, 1);
        assertEq(chainsToMigrate[0], CHAIN_ID);
        assertEq(Claim.unwrap(migrations[CHAIN_ID].cannonPrestate), bytes32(uint256(0xdead) << 240));
        assertEq(Claim.unwrap(migrations[CHAIN_ID].cannonKonaPrestate), bytes32(uint256(0xdead) << 240));
        assertEq(migrations[CHAIN_ID].expectedValidationErrors, "");

        assertEq(migrateParams.initBond, 0.08 ether);
        assertEq(migrateParams.startingAnchorRootL2SequenceNumber, 0);
        assertEq(migrateParams.startingAnchorRootRoot, bytes32(uint256(0xdead) << 240));
        assertEq(uint256(migrateParams.startingRespectedGameType), 5);

        IOPContractsManagerV700.DisputeGameConfig[] memory configs = _buildSharedGameConfigs();
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
        // TODO: enable once a v7.1.16 OPCM with migrator, real prestates, anchor root,
        // proposer/challenger, and a second Sepolia interop chain are wired into the fixture.
        vm.skip(true);

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
