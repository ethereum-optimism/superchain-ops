// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IOPContractsManagerV700, ISystemConfig} from "src/template/OPCMUpgradeV700.sol";

/// @notice Etched at admin address so delegatecall to OPCM runs in admin's context.
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

    function _buildGameConfigs(string memory state)
        internal
        pure
        returns (IOPContractsManagerV700.DisputeGameConfig[] memory)
    {
        // Dummy prestate — the actual value doesn't matter for validating the upgrade flow.
        bytes32 prestate = bytes32(uint256(1));
        address proposer = stdJson.readAddress(state, ".appliedIntent.chains[0].roles.proposer");
        address challenger = stdJson.readAddress(state, ".appliedIntent.chains[0].roles.challenger");

        bytes memory permArgs = abi.encode(prestate, proposer, challenger);

        // OPCM requires exactly 6 game types in this order:
        // CANNON(0), PERMISSIONED_CANNON(1), CANNON_KONA(8), SUPER_CANNON(4),
        // SUPER_PERMISSIONED_CANNON(5), SUPER_CANNON_KONA(9).
        IOPContractsManagerV700.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV700.DisputeGameConfig[](6);
        uint32[6] memory gts = [uint32(0), 1, 8, 4, 5, 9];
        for (uint256 i = 0; i < 6; i++) {
            bool perm = gts[i] == 1 || gts[i] == 5;
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
        // Parse state.json — all addresses come from here
        string memory state = vm.readFile(string.concat(FIXTURES, "state.json"));
        address opcm = stdJson.readAddress(state, ".implementationsDeployment.OpcmImpl");
        address sysConfig = stdJson.readAddress(state, ".opChainDeployments[0].SystemConfigProxy");

        // Fork sepolia
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        // Derive ProxyAdminOwner from on-chain state
        address admin = IProxyAdmin(ISystemConfigExt(sysConfig).proxyAdmin()).owner();

        // Etch forwarder at admin address so delegatecall runs in admin's context
        DelegateCallForwarder forwarder = new DelegateCallForwarder();
        vm.etch(admin, address(forwarder).code);

        // Build game configs and extra instructions
        IOPContractsManagerV700.DisputeGameConfig[] memory dgConfigs = _buildGameConfigs(state);

        IOPContractsManagerV700.ExtraInstruction[] memory extraInstructions =
            new IOPContractsManagerV700.ExtraInstruction[](1);
        extraInstructions[0] =
            IOPContractsManagerV700.ExtraInstruction({key: "PermittedProxyDeployment", data: bytes("DelayedWETH")});

        // Upgrade chain via delegatecall from admin
        DelegateCallForwarder(admin).forward(
            opcm,
            abi.encodeCall(
                IOPContractsManagerV700.upgrade,
                (
                    IOPContractsManagerV700.UpgradeInput({
                        systemConfig: ISystemConfig(sysConfig),
                        disputeGameConfigs: dgConfigs,
                        extraInstructions: extraInstructions
                    })
                )
            )
        );
    }
}
