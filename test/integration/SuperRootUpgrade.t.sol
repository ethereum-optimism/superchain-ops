// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IOPContractsManagerV700, ISuperchainConfig, ISystemConfig} from "src/template/OPCMUpgradeV700.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {DisputeGameFactory} from "lib/optimism/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol";
import {GameType} from "lib/optimism/packages/contracts-bedrock/src/dispute/lib/Types.sol";

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

contract SuperRootUpgradeTest is Test {
    string constant FIXTURES = "test/fixtures/super-root-upgrade/";
    string internal state;
    string internal configToml;
    SuperchainAddressRegistry internal superchainAddrRegistry;
    DisputeGameFactory internal disputeGameFactory;
    address superchainConfig;
    address systemConfig;
    address systemConfigProxyAdmin;
    address systemConfigProxyAdminOwner;
    address opcm;

    function setUp() public {
        // Fork sepolia
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        state = vm.readFile(string.concat(FIXTURES, "state.json"));
        configToml = vm.readFile(string.concat(FIXTURES, "config.toml"));
        string memory configTomlPath = string.concat(FIXTURES, "config.toml");
        superchainAddrRegistry = new SuperchainAddressRegistry(configTomlPath);
        systemConfig = superchainAddrRegistry.getAddress("SystemConfigProxy", 11155420);
        superchainConfig = superchainAddrRegistry.getAddress("SuperchainConfig", 11155420);
        systemConfigProxyAdmin = ISystemConfigExt(systemConfig).proxyAdmin();
        disputeGameFactory = DisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", 11155420));
        systemConfigProxyAdminOwner = IProxyAdmin(systemConfigProxyAdmin).owner();
        opcm = stdToml.readAddress(configToml, ".addresses.OPCM");
    }

    function isEnabled(GameType gt) internal returns (bool) {
        if (GameType.unwrap(gt) == 0) return false;
        if (GameType.unwrap(gt) == 1) return false;
        if (GameType.unwrap(gt) == 8) return false;
        if (GameType.unwrap(gt) == 4) {
            if (address(disputeGameFactory.gameImpls(GameType.wrap(0))) != address(0)) {
                return true;
            } else {
                return false;
            }
        }
        if (GameType.unwrap(gt) == 5) {
            if (address(disputeGameFactory.gameImpls(GameType.wrap(1))) != address(0)) {
                return true;
            } else {
                return false;
            }
        }
        if (GameType.unwrap(gt) == 9) {
            if (address(disputeGameFactory.gameImpls(GameType.wrap(8))) != address(0)) {
                return true;
            } else {
                return false;
            }
        }
    }

    function _buildGameConfigs(string memory state)
        internal
        returns (IOPContractsManagerV700.DisputeGameConfig[] memory)
    {
        // Dummy prestate — the actual value doesn't matter for validating the upgrade flow.
        bytes32 prestate = bytes32(uint256(1));
        address proposer = makeAddr("proposer");
        address challenger = makeAddr("challenger");

        bytes memory permArgs = abi.encode(prestate, proposer, challenger);

        // OPCM requires exactly 6 game types in this order:
        // CANNON(0), PERMISSIONED_CANNON(1), CANNON_KONA(8), SUPER_CANNON(4),
        // SUPER_PERMISSIONED_CANNON(5), SUPER_CANNON_KONA(9).
        IOPContractsManagerV700.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV700.DisputeGameConfig[](6);
        uint32[6] memory gts = [uint32(0), 1, 8, 4, 5, 9];
        for (uint256 i = 0; i < 6; i++) {
            bool perm = isEnabled(GameType.wrap(gts[i]));
            cfgs[i] = IOPContractsManagerV700.DisputeGameConfig({
                enabled: perm,
                initBond: perm ? 0.08 ether : 0,
                gameType: gts[i],
                gameArgs: perm ? permArgs : bytes("")
            });
        }
        return cfgs;
    }

    function test_upgrade_sepolia() public {
        DelegateCallForwarder forwarder = new DelegateCallForwarder();
        vm.etch(systemConfigProxyAdminOwner, address(forwarder).code);

        DelegateCallForwarder(systemConfigProxyAdminOwner).forward(
            opcm,
            abi.encodeCall(
                IOPContractsManagerV700.upgradeSuperchain,
                (
                    IOPContractsManagerV700.SuperchainUpgradeInput({
                        superchainConfig: ISuperchainConfig(superchainConfig),
                        extraInstructions: new IOPContractsManagerV700.ExtraInstruction[](0)
                    })
                )
            )
        );

        // Build game configs and extra instructions
        IOPContractsManagerV700.DisputeGameConfig[] memory dgConfigs = _buildGameConfigs(state);

        IOPContractsManagerV700.ExtraInstruction[] memory extraInstructions =
            new IOPContractsManagerV700.ExtraInstruction[](2);
        extraInstructions[0] =
            IOPContractsManagerV700.ExtraInstruction({key: "PermittedProxyDeployment", data: bytes("DelayedWETH")});
        extraInstructions[1] = IOPContractsManagerV700.ExtraInstruction({
            key: "overrides.cfg.startingRespectedGameType",
            data: abi.encode(uint32(9)) // SUPER_CANNON_KONA
        });

        // Upgrade chain via delegatecall from admin
        DelegateCallForwarder(systemConfigProxyAdminOwner).forward(
            opcm,
            abi.encodeCall(
                IOPContractsManagerV700.upgrade,
                (
                    IOPContractsManagerV700.UpgradeInput({
                        systemConfig: ISystemConfig(systemConfig),
                        disputeGameConfigs: dgConfigs,
                        extraInstructions: extraInstructions
                    })
                )
            )
        );
    }
}
