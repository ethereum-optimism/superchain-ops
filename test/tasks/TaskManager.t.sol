// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {TaskManager} from "src/improvements/tasks/TaskManager.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {StateOverrideManager} from "src/improvements/tasks/StateOverrideManager.sol";
import {Vm} from "forge-std/Vm.sol";

contract TaskManagerUnitTest is StateOverrideManager, Test {
    using LibString for string;

    string constant commonToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
        "templateName = \"DisputeGameUpgradeTemplate\"\n" "\n"
        "implementations = [{gameType = 0, implementation = \"0xf691F8A6d908B58C534B624cF16495b491E633BA\", l2ChainId = 10}]\n";

    function setUp() public {}

    function testSetTenderlyGasEnv() public {
        TaskManager tm = new TaskManager();

        tm.setTenderlyGasEnv("./src/improvements/tasks/sep/000-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "30000000");

        tm.setTenderlyGasEnv("./src/improvements/tasks/sep/001-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "16000000");

        tm.setTenderlyGasEnv("./src/improvements/tasks/sep/002-unichain-superchain-config-fix/");
        assertEq(vm.envString("TENDERLY_GAS"), "");

        tm.setTenderlyGasEnv("./src/improvements/tasks/sep/003-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "16000000");

        tm.setTenderlyGasEnv("./src/improvements/tasks/eth/000-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "30000000");

        tm.setTenderlyGasEnv("./src/improvements/tasks/eth/002-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "16000000");
    }

    function createStateDiff(address who, bytes32 slot, bytes32 oldValue, bytes32 newValue)
        public
        pure
        returns (AccountAccessParser.DecodedStateDiff memory)
    {
        return AccountAccessParser.DecodedStateDiff({
            who: who,
            l2ChainId: 10,
            contractName: "N/A",
            raw: AccountAccessParser.StateDiff({slot: slot, oldValue: oldValue, newValue: newValue}),
            decoded: AccountAccessParser.DecodedSlot({
                kind: "uint256",
                oldValue: "N/A",
                newValue: "N/A",
                summary: "N/A",
                detail: "N/A"
            })
        });
    }

    function testRequireSignerOnSafe_FailsIfSignerIsNotOwner() public {
        vm.createSelectFork("mainnet", 22433511); // Pinning to a block.
        TaskManager tm = new TaskManager();
        string memory errorMessage =
            "TaskManager: signer 0xEbE2cdF322646D8Aa36CED4A3072FCAe7F0a9B0b is not an owner on the safe: 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A";
        vm.expectRevert(bytes(errorMessage));
        address signer = 0xEbE2cdF322646D8Aa36CED4A3072FCAe7F0a9B0b;
        address safe = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;
        tm.requireSignerOnSafe(signer, "src/improvements/tasks/eth/011-deputy-pause-module-activation");
        vm.expectRevert(bytes(errorMessage));
        tm.requireSignerOnSafe(signer, safe);
    }

    function testRequireSignerOnSafe_PassesIfSignerIsOwner() public {
        vm.createSelectFork("mainnet", 22433511); // Pinning to a block.
        TaskManager tm = new TaskManager();
        address signer = 0xBF93D4d727F7Ba1F753E1124C3e532dCb04Ea2c8;
        address safe = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;
        tm.requireSignerOnSafe(signer, "src/improvements/tasks/eth/011-deputy-pause-module-activation");
        tm.requireSignerOnSafe(signer, safe);
    }
}
