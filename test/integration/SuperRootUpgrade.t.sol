// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IOPContractsManagerV700, ISystemConfig} from "src/template/OPCMUpgradeV700.sol";

/// @notice Etched at admin address so delegatecall to OPCM runs in admin's context.
contract DelegateCallForwarder {
    function forward(address target, bytes memory data) external {
        (bool ok, bytes memory ret) = target.delegatecall(data);
        if (!ok) {
            assembly { revert(add(ret, 0x20), mload(ret)) }
        }
    }
}

contract SuperRootUpgradeTest is Test {
    string constant FIXTURES = "test/fixtures/super-root-upgrade/";
    string constant ADDRESSES = "src/tasks/sep/053-U18-op-betanets-v3/addresses.json";

    function setUp() public {}

    function test_upgrade_sepolia() public {
        // Parse intent.toml — just the chain ID
        string memory intent = vm.readFile(string.concat(FIXTURES, "intent.toml"));
        uint256 l1ChainId = stdToml.readUint(intent, ".l1ChainID");

        // Parse state.json — OPCM address
        string memory state = vm.readFile(string.concat(FIXTURES, "state.json"));
        address opcm = stdJson.readAddress(state, ".implementationsDeployment.OpcmImpl");

        // Parse addresses.json — betanet chain to upgrade
        string memory addrs = vm.readFile(ADDRESSES);
        address sysConfig = stdJson.readAddress(addrs, ".420110021.SystemConfigProxy");
        address admin = stdJson.readAddress(addrs, ".420110021.ProxyAdminOwner");

        // Fork sepolia
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        assertEq(block.chainid, l1ChainId);

        // Etch forwarder at admin address so delegatecall runs in admin's context
        DelegateCallForwarder forwarder = new DelegateCallForwarder();
        vm.etch(admin, address(forwarder).code);

        // OPCM requires all 6 game types in order. Only PERMISSIONED_CANNON (gameType=1)
        // is enabled since it's the chain's respectedGameType. Others disabled with initBond=0.
        // Order: CANNON(0), PERMISSIONED_CANNON(1), CANNON_KONA(8), SUPER_CANNON(4),
        //        SUPER_PERMISSIONED_CANNON(5), SUPER_CANNON_KONA(9)
        IOPContractsManagerV700.DisputeGameConfig[] memory dgConfigs =
            new IOPContractsManagerV700.DisputeGameConfig[](6);
        uint32[6] memory gameTypes = [uint32(0), 1, 8, 4, 5, 9];
        for (uint256 i = 0; i < 6; i++) {
            dgConfigs[i] = IOPContractsManagerV700.DisputeGameConfig({
                enabled: gameTypes[i] == 1, // only PERMISSIONED_CANNON enabled
                initBond: gameTypes[i] == 1 ? 0.08 ether : 0,
                gameType: gameTypes[i],
                gameArgs: ""
            });
        }

        // SystemConfig doesn't have delayedWETH registered, permit OPCM to deploy it
        IOPContractsManagerV700.ExtraInstruction[] memory extraInstructions =
            new IOPContractsManagerV700.ExtraInstruction[](1);
        extraInstructions[0] = IOPContractsManagerV700.ExtraInstruction({
            key: "PermittedProxyDeployment",
            data: bytes("DelayedWETH")
        });

        // Upgrade chain via delegatecall from admin
        DelegateCallForwarder(admin).forward(
            opcm,
            abi.encodeCall(
                IOPContractsManagerV700.upgrade,
                (IOPContractsManagerV700.UpgradeInput({
                    systemConfig: ISystemConfig(sysConfig),
                    disputeGameConfigs: dgConfigs,
                    extraInstructions: extraInstructions
                }))
            )
        );
    }
}