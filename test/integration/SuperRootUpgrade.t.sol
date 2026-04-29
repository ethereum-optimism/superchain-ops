// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IOPContractsManagerV700, OPCMUpgradeV700} from "src/template/OPCMUpgradeV700.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
}

interface ISystemConfigExt {
    function proxyAdmin() external view returns (address);
    function superchainConfig() external view returns (address);
}

contract SuperRootUpgradeTest is Test, OPCMUpgradeV700 {
    string constant FIXTURES = "test/tasks/example/sep/035-opcm-upgrade-v700/";
    uint256 internal constant CHAIN_ID = 11155420;
    address rootSafe;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        string memory configTomlPath = string.concat(FIXTURES, "config.toml");
        superchainAddrRegistry = new SuperchainAddressRegistry(configTomlPath);
        _templateSetup(configTomlPath, address(0));
        address systemConfig = superchainAddrRegistry.getAddress("SystemConfigProxy", CHAIN_ID);
        rootSafe = IProxyAdmin(ISystemConfigExt(systemConfig).proxyAdmin()).owner();
    }

    function test_load_data() public view {
        assertEq(rootSafe, superchainAddrRegistry.getAddress("ProxyAdminOwner", CHAIN_ID));
        assertEq(chainsToUpgrade.length, 1);
        assertEq(chainsToUpgrade[0], CHAIN_ID);
        assertEq(Claim.unwrap(upgrades[CHAIN_ID].cannonPrestate), bytes32(uint256(0xdead) << 240));
        assertEq(Claim.unwrap(upgrades[CHAIN_ID].cannonKonaPrestate), bytes32(uint256(0xdead) << 240));
        assertEq(upgrades[CHAIN_ID].initBond, 0.08 ether);
        assertEq(upgrades[CHAIN_ID].startingRespectedGameType, 9);
        assertEq(upgrades[CHAIN_ID].expectedValidationErrors, "OVERRIDES-L1PAOMULTISIG,OVERRIDES-CHALLENGER,SYSCON-130");

        IOPContractsManagerV700.DisputeGameConfig[] memory configs = _buildGameConfigs(CHAIN_ID);
        assertEq(configs.length, 7);

        uint32[7] memory expectedGameTypes = [uint32(0), 1, 8, 4, 5, 9, 10];
        for (uint256 i = 0; i < configs.length; i++) {
            IOPContractsManagerV700.DisputeGameConfig memory config = configs[i];
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
                assertEq(config.initBond, upgrades[CHAIN_ID].initBond);
                assertEq(permPrestate, Claim.unwrap(upgrades[CHAIN_ID].cannonKonaPrestate));
                assertEq(proposer, superchainAddrRegistry.getAddress("Proposer", CHAIN_ID));
                assertEq(challenger, superchainAddrRegistry.getAddress("Challenger", CHAIN_ID));
            } else {
                assertEq(config.initBond, upgrades[CHAIN_ID].initBond);
                bytes32 prestate = abi.decode(config.gameArgs, (bytes32));
                if (isKona) {
                    assertEq(prestate, Claim.unwrap(upgrades[CHAIN_ID].cannonKonaPrestate));
                } else {
                    assertEq(prestate, Claim.unwrap(upgrades[CHAIN_ID].cannonPrestate));
                }
            }
        }
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
