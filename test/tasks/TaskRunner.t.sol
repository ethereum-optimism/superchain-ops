// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {TaskRunner} from "src/improvements/tasks/TaskRunner.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {StateOverrideManager} from "src/improvements/tasks/StateOverrideManager.sol";

contract TaskRunnerUnitTest is StateOverrideManager, Test {
    using LibString for string;

    string constant commonToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
        "templateName = \"DisputeGameUpgradeTemplate\"\n" "\n"
        "implementations = [{gameType = 0, implementation = \"0xf691F8A6d908B58C534B624cF16495b491E633BA\", l2ChainId = 10}]\n";

    function setUp() public {}

    function testSetTenderlyGasEnv() public {
        TaskRunner tr = new TaskRunner();

        tr.setTenderlyGasEnv("./src/improvements/tasks/sep/000-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "30000000");

        tr.setTenderlyGasEnv("./src/improvements/tasks/sep/001-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "16000000");

        tr.setTenderlyGasEnv("./src/improvements/tasks/sep/002-unichain-superchain-config-fix/");
        assertEq(vm.envString("TENDERLY_GAS"), "");

        tr.setTenderlyGasEnv("./src/improvements/tasks/sep/003-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "16000000");

        tr.setTenderlyGasEnv("./src/improvements/tasks/eth/000-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "30000000");

        tr.setTenderlyGasEnv("./src/improvements/tasks/eth/002-opcm-upgrade-v200/");
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
}
