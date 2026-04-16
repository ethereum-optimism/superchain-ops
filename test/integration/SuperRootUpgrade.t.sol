// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Test} from "forge-std/Test.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IOPContractsManagerV700, OPCMUpgradeV700} from "src/template/OPCMUpgradeV700.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

contract DelegateCallForwarder {
    function forward(address target, bytes memory data) external {
        (bool ok, bytes memory ret) = target.delegatecall(data);
        if (!ok) {
            assembly {
                revert(add(ret, 0x20), mload(ret))
            }
        }
    }
}

interface IProxyAdmin {
    function owner() external view returns (address);
}

interface ISystemConfigExt {
    function proxyAdmin() external view returns (address);
    function superchainConfig() external view returns (address);
}

contract SuperRootUpgradeTest is Test, OPCMUpgradeV700 {
    string constant FIXTURES = "test/fixtures/super-root-upgrade/";
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
        assertEq(upgrades[CHAIN_ID].expectedValidationErrors, "");

        IOPContractsManagerV700.DisputeGameConfig[] memory configs = _buildGameConfigs(CHAIN_ID);
        assertEq(configs.length, 6);

        uint32[6] memory expectedGameTypes = [uint32(0), 1, 8, 4, 5, 9];
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
    }

    function _executeActions(Action[] memory actions) internal {
        DelegateCallForwarder forwarder = new DelegateCallForwarder();
        vm.etch(rootSafe, address(forwarder).code);
        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i].operation == Enum.Operation.DelegateCall) {
                DelegateCallForwarder(rootSafe).forward(actions[i].target, actions[i].arguments);
            } else {
                vm.prank(rootSafe);
                (bool ok,) = actions[i].target.call{value: actions[i].value}(actions[i].arguments);
                require(ok, "Call failed");
            }
        }
    }
}
