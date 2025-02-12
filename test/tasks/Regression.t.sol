pragma solidity 0.8.15;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";

import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {GasConfigTemplate} from "src/improvements/template/GasConfigTemplate.sol";
import {SetGameTypeTemplate} from "src/improvements/template/SetGameTypeTemplate.sol";
import {DisputeGameUpgradeTemplate} from "src/improvements/template/DisputeGameUpgradeTemplate.sol";

contract RegressionTest is Test {
    function testRegressionCallDataMatchesTask00() public {
        string memory taskConfigFilePath = "test/tasks/mock/example/eth/task-00/config.toml";
        string memory expectedCallData =
            "0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000005e6432f18bc5d497b1ab2288a025fbf9d69e22210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024b40a817c0000000000000000000000000000000000000000000000000000000005f5e100000000000000000000000000000000000000000000000000000000000000000000000000000000007bd909970b0eedcf078de6aeff23ce571663b8aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024b40a817c0000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000000000000";
        vm.createSelectFork("mainnet", 21724199);
        MultisigTask multisigTask = new GasConfigTemplate();
        multisigTask.simulateRun(taskConfigFilePath);

        string memory callData = vm.toString(multisigTask.getCalldata());
        assertEq(keccak256(bytes(callData)), keccak256(bytes(expectedCallData)));

        string memory expectedDataToSign =
            "0x19010f634ad56005ddbd68dc52233931a858f740b8ab706671c42b055efef561257e5ba28ec1e58ea69211eb8e875f10ae165fb3fb4052b15ca2516486f4b059135f";
        string memory dataToSign =
            vm.toString(multisigTask.getDataToSign(multisigTask.multisig(), multisigTask.getCalldata()));
        assertEq(keccak256(bytes(dataToSign)), keccak256(bytes(expectedDataToSign)));
    }

    function testRegressionCallDataMatchesTask01() public {
        string memory taskConfigFilePath = "test/tasks/mock/example/eth/task-01/config.toml";
        string memory expectedCallData =
            "0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004414f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f691f8a6d908b58c534b624cf16495b491e633ba00000000000000000000000000000000000000000000000000000000";
        vm.createSelectFork("mainnet", 21724199);
        MultisigTask multisigTask = new DisputeGameUpgradeTemplate();
        multisigTask.simulateRun(taskConfigFilePath);

        string memory callData = vm.toString(multisigTask.getCalldata());
        assertEq(keccak256(bytes(callData)), keccak256(bytes(expectedCallData)));

        string[] memory expectedDataToSign = new string[](2);
        expectedDataToSign[0] =
            "0x1901a4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672032d168a6a75092d06448c977c02a33ee3890827ab9cc8a14a57e62494214746";
        expectedDataToSign[1] =
            "0x1901df53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce9677607901a3c2502aa70a9dcd2fa190c27cdd30d74058e9b807c3d32f1ee46100f";
        address[] memory owners = IGnosisSafe(multisigTask.multisig()).getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            string memory dataToSign =
                vm.toString(multisigTask.getDataToSign(owners[i], multisigTask.generateApproveMulticallData()));
            assertEq(keccak256(bytes(dataToSign)), keccak256(bytes(expectedDataToSign[i])));
        }
    }

    function testRegressionCallDataMatchesTask02() public {
        string memory taskConfigFilePath = "test/tasks/mock/example/eth/task-02/config.toml";
        string memory expectedCallData =
            "0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000c6901f65369fc59fc1b4d6d6be7a2318ff38db5b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000044a1155ed9000000000000000000000000beb5fc579115071764c7423a4f12edde41f106ed000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000";
        vm.createSelectFork("mainnet", 21724199);
        MultisigTask multisigTask = new SetGameTypeTemplate();
        multisigTask.simulateRun(taskConfigFilePath);

        string memory callData = vm.toString(multisigTask.getCalldata());
        assertEq(keccak256(bytes(callData)), keccak256(bytes(expectedCallData)));

        string memory expectedDataToSign =
            "0x19014e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c70389084af4d0fecafda1f7bfcaf76684bbec959187b61160bdf1d1ab14045664fe412";
        string memory dataToSign =
            vm.toString(multisigTask.getDataToSign(multisigTask.multisig(), multisigTask.getCalldata()));
        assertEq(keccak256(bytes(dataToSign)), keccak256(bytes(expectedDataToSign)));
    }

    function testRegressionCallDataMatchesTask03() public {
        string memory taskConfigFilePath = "test/tasks/mock/example/eth/task-03/config.toml";
        string memory expectedCallData =
            "0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb2900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024b40a817c000000000000000000000000000000000000000000000000000000000393870000000000000000000000000000000000000000000000000000000000";
        vm.createSelectFork("mainnet", 21724199);
        MultisigTask multisigTask = new GasConfigTemplate();
        multisigTask.simulateRun(taskConfigFilePath);

        string memory callData = vm.toString(multisigTask.getCalldata());
        assertEq(keccak256(bytes(callData)), keccak256(bytes(expectedCallData)));

        string memory expectedDataToSign =
            "0x1901a4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672c98bc9c1761f2e403be0ad32b16d9c5fedf228f97eb0420c722b511129ebc803";
        string memory dataToSign =
            vm.toString(multisigTask.getDataToSign(multisigTask.multisig(), multisigTask.getCalldata()));
        assertEq(keccak256(bytes(dataToSign)), keccak256(bytes(expectedDataToSign)));
    }
}
