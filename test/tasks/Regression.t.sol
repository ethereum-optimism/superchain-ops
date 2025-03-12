pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {GasConfigTemplate} from "test/tasks/mock/template/GasConfigTemplate.sol";
import {SetGameTypeTemplate} from "test/tasks/mock/template/SetGameTypeTemplate.sol";
import {DisputeGameUpgradeTemplate} from "test/tasks/mock/template/DisputeGameUpgradeTemplate.sol";
import {EnableDeputyPauseModuleTemplate} from "src/improvements/template/EnableDeputyPauseModuleTemplate.sol";
import {OPCMUpgradeV200} from "src/improvements/template/OPCMUpgradeV200.sol";

/// @notice test that the call data and data to sign generated in simulateRun for the multisigs
/// are always the same. This means that if there were any bug introduced in the multisig task, or opcm base task,
/// same call data or data to sign will not be generated at the same block and these tests will fail.
contract RegressionTest is Test {
    /// @notice expected call data and data to sign generated by manually running the GasConfigTemplate at block 21724199 on mainnet
    /// using script:
    /// forge script test/template/GasConfigTemplate.sol
    /// --sig "simulateRun(string)" test/tasks/mock/configs/SingleMultisigGasConfigTemplate.toml
    /// --rpc-url mainnet
    /// --fork-block-number 21724199
    /// -vv
    function testRegressionCallDataMatches_SingleMultisigGasConfigTemplate() public {
        string memory taskConfigFilePath = "test/tasks/mock/configs/SingleMultisigGasConfigTemplate.toml";
        // call data generated by manually running the gas config template at block 21724199 on mainnet
        string memory expectedCallData =
            "0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000005e6432f18bc5d497b1ab2288a025fbf9d69e22210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024b40a817c0000000000000000000000000000000000000000000000000000000005f5e100000000000000000000000000000000000000000000000000000000000000000000000000000000007bd909970b0eedcf078de6aeff23ce571663b8aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024b40a817c0000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000000000000";
        MultisigTask multisigTask = new GasConfigTemplate();

        MultisigTask.Action[] memory actions =
            _setupAndSimulateRun(taskConfigFilePath, 21724199, "mainnet", multisigTask);

        _assertCallData(multisigTask, actions, expectedCallData);

        // data to sign generated by manually running the gas config template at block 21724199 on mainnet
        string memory expectedDataToSign =
            "0x19010f634ad56005ddbd68dc52233931a858f740b8ab706671c42b055efef561257e5ba28ec1e58ea69211eb8e875f10ae165fb3fb4052b15ca2516486f4b059135f";
        string memory dataToSign = vm.toString(
            multisigTask.getEncodedTransactionData(
                multisigTask.parentMultisig(), multisigTask.getMulticall3Calldata(actions)
            )
        );
        // assert that the data to sign generated in simulateRun is the same as the expected data to sign
        assertEq(keccak256(bytes(dataToSign)), keccak256(bytes(expectedDataToSign)));
        _assertDataToSignSingleMultisig(multisigTask, actions, expectedDataToSign);
    }

    /// @notice expected call data and data to sign generated by manually running the DisputeGameUpgradeTemplate at block 21724199 on mainnet
    /// using script:
    /// forge script test/template/DisputeGameUpgradeTemplate.sol
    /// --sig "simulateRun(string)" test/tasks/mock/configs/NestedMultisigDisputeGameUpgradeTemplate.toml
    /// --rpc-url mainnet
    /// --fork-block-number 21724199
    /// -vv
    function testRegressionCallDataMatches_NestedMultisigDisputeGameUpgradeTemplate() public {
        string memory taskConfigFilePath = "test/tasks/mock/configs/NestedMultisigDisputeGameUpgradeTemplate.toml";
        // call data generated by manually running the dispute game upgrade template at block 21724199 on mainnet
        string memory expectedCallData =
            "0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004414f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f691f8a6d908b58c534b624cf16495b491e633ba00000000000000000000000000000000000000000000000000000000";

        MultisigTask multisigTask = new DisputeGameUpgradeTemplate();
        MultisigTask.Action[] memory actions =
            _setupAndSimulateRun(taskConfigFilePath, 21724199, "mainnet", multisigTask);

        _assertCallData(multisigTask, actions, expectedCallData);

        // data to sign generated by manually running the dispute game upgrade template at block 21724199 on mainnet
        // for each child multisig
        string[] memory expectedDataToSign = new string[](2);
        expectedDataToSign[0] =
            "0x1901a4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672032d168a6a75092d06448c977c02a33ee3890827ab9cc8a14a57e62494214746";
        expectedDataToSign[1] =
            "0x1901df53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce9677607901a3c2502aa70a9dcd2fa190c27cdd30d74058e9b807c3d32f1ee46100f";

        _assertDataToSignNestedMultisig(multisigTask, actions, expectedDataToSign);
    }

    /// @notice expected call data and data to sign generated by manually running the SetGameTypeTemplate at block 21724199 on mainnet
    /// using script:
    /// forge script test/template/SetGameTypeTemplate.sol
    /// --sig "simulateRun(string)" test/tasks/mock/configs/OPMainnetSetGameTypeTemplate.toml
    /// --rpc-url mainnet
    /// --fork-block-number 21724199
    /// -vv
    function testRegressionCallDataMatches_OPMainnetSetGameTypeTemplate() public {
        string memory taskConfigFilePath = "test/tasks/mock/configs/OPMainnetSetGameTypeTemplate.toml";
        // call data generated by manually running the set game type template at block 21724199 on mainnet
        string memory expectedCallData =
            "0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000c6901f65369fc59fc1b4d6d6be7a2318ff38db5b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000044a1155ed9000000000000000000000000beb5fc579115071764c7423a4f12edde41f106ed000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000";

        MultisigTask multisigTask = new SetGameTypeTemplate();
        MultisigTask.Action[] memory actions =
            _setupAndSimulateRun(taskConfigFilePath, 21724199, "mainnet", multisigTask);

        _assertCallData(multisigTask, actions, expectedCallData);

        // data to sign generated by manually running the set game type template at block 21724199
        string memory expectedDataToSign =
            "0x19014e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c70389084af4d0fecafda1f7bfcaf76684bbec959187b61160bdf1d1ab14045664fe412";

        _assertDataToSignSingleMultisig(multisigTask, actions, expectedDataToSign);
    }

    /// @notice expected call data and data to sign generated by manually running the GasConfigTemplate at block 21724199 on mainnet
    /// using script:
    /// forge script test/template/GasConfigTemplate.sol
    /// --sig "simulateRun(string)" test/tasks/mock/configs/OPMainnetGasConfigTemplate.toml
    /// --rpc-url mainnet
    /// --fork-block-number 21724199
    /// -vv
    function testRegressionCallDataMatches_OPMainnetGasConfigTemplate() public {
        string memory taskConfigFilePath = "test/tasks/mock/configs/OPMainnetGasConfigTemplate.toml";
        // call data generated by manually running the gas config template at block 21724199 on mainnet
        string memory expectedCallData =
            "0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb2900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024b40a817c000000000000000000000000000000000000000000000000000000000393870000000000000000000000000000000000000000000000000000000000";
        MultisigTask multisigTask = new GasConfigTemplate();
        MultisigTask.Action[] memory actions =
            _setupAndSimulateRun(taskConfigFilePath, 21724199, "mainnet", multisigTask);

        _assertCallData(multisigTask, actions, expectedCallData);

        // data to sign generated by manually running the gas config template at block 21724199 on mainnet
        string memory expectedDataToSign =
            "0x1901a4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672c98bc9c1761f2e403be0ad32b16d9c5fedf228f97eb0420c722b511129ebc803";

        _assertDataToSignSingleMultisig(multisigTask, actions, expectedDataToSign);
    }

    /// @notice expected call data and data to sign generated by manually running the EnableDeputyPauseModuleTemplate at block 7745524 on sepolia
    /// using script:
    /// forge script src/improvements/template/EnableDeputyPauseModuleTemplate.sol
    /// --sig "simulateRun(string)" test/tasks/mock/configs/EnableDeputyPauseModuleTemplate.toml
    /// --rpc-url sepolia
    /// --fork-block-number 7745524
    /// -vv
    function testRegressionCallDataMatches_EnableDeputyPauseModuleTemplate() public {
        string memory taskConfigFilePath = "test/tasks/mock/configs/EnableDeputyPauseModuleTemplate.toml";
        string memory expectedCallData =
            "0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000837de453ad5f21e89771e3c06239d8236c0efd5e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024610b592500000000000000000000000062f3972c56733ab078f0764d2414dfcaa99d574c00000000000000000000000000000000000000000000000000000000";
        MultisigTask multisigTask = new EnableDeputyPauseModuleTemplate();
        MultisigTask.Action[] memory actions =
            _setupAndSimulateRun(taskConfigFilePath, 7745524, "sepolia", multisigTask);

        _assertCallData(multisigTask, actions, expectedCallData);

        string memory expectedDataToSign =
            "0x1901e84ad8db37faa1651b140c17c70e4c48eaa47a635e0db097ddf4ce1cc14b9ecbf55e2ed894ddff4c0045537c8239db1c4b3ac5700049164b5823ecaa045d7334";

        _assertDataToSignSingleMultisig(multisigTask, actions, expectedDataToSign);
    }

    /// @notice Expected call data and data to sign generated by manually running the OPCMUpgradeV200 template at block 7757671 on sepolia
    /// Using script:
    /// forge script OPCMUpgradeV200 --sig "simulateRun(string)" test/tasks/example/sep/002-opcm-upgrade-v200/config.toml --rpc-url sepolia --fork-block-number 7826712 -vv
    function testRegressionCallDataMatches_OPCMUpgradeV200() public {
        string memory taskConfigFilePath = "test/tasks/example/sep/002-opcm-upgrade-v200/config.toml";
        // Call data generated by manually running the OPCMUpgradeV200 template at block 7826712 on sepolia
        string memory expectedCallData =
            "0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001b25f566336f47bc5e0036d66e142237dcf4640b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd00000000000000000000000000000000000000000000000000000000";
        MultisigTask multisigTask = new OPCMUpgradeV200();
        MultisigTask.Action[] memory actions =
            _setupAndSimulateRun(taskConfigFilePath, 7826712, "sepolia", multisigTask);

        _assertCallData(multisigTask, actions, expectedCallData);

        // Data to sign generated by manually running the OPCMUpgradeV200 template at block 7826712 on sepolia
        // for each child multisig
        string[] memory expectedDataToSign = new string[](2);
        expectedDataToSign[0] =
            "0x190137e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbbc4308e7f6e5e57b1527f2a53444553ecad29ae331fa07bbc0c91e6e73986e250";
        expectedDataToSign[1] =
            "0x1901be081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533efa681cff20329f64ecd2a4ec88d618f5e3aaee370a9a4550df3cda85e94352e";

        _assertDataToSignNestedMultisig(multisigTask, actions, expectedDataToSign);
    }

    /// @notice Internal function to set up the fork and run the simulateRun method
    function _setupAndSimulateRun(
        string memory taskConfigFilePath,
        uint256 blockNumber,
        string memory network,
        MultisigTask multisigTask
    ) internal returns (MultisigTask.Action[] memory actions) {
        vm.createSelectFork(network, blockNumber);
        (, actions) = multisigTask.simulateRun(taskConfigFilePath);
    }

    /// @notice assert that the call data generated by the multisig task matches the expected call data
    function _assertCallData(
        MultisigTask multisigTask,
        MultisigTask.Action[] memory actions,
        string memory expectedCallData
    ) internal view {
        string memory callData = vm.toString(multisigTask.getMulticall3Calldata(actions));
        assertEq(keccak256(bytes(callData)), keccak256(bytes(expectedCallData)));
    }

    /// @notice assert that the data to sign generated by the single multisig task matches the expected data to sign
    function _assertDataToSignSingleMultisig(
        MultisigTask multisigTask,
        MultisigTask.Action[] memory actions,
        string memory expectedDataToSign
    ) internal view {
        string memory dataToSign = vm.toString(
            multisigTask.getEncodedTransactionData(
                multisigTask.parentMultisig(), multisigTask.getMulticall3Calldata(actions)
            )
        );
        assertEq(keccak256(bytes(dataToSign)), keccak256(bytes(expectedDataToSign)));
    }

    /// @notice assert that the data to sign generated by the nested multisig task matches the expected data to sign
    /// for each child multisig
    function _assertDataToSignNestedMultisig(
        MultisigTask multisigTask,
        MultisigTask.Action[] memory actions,
        string[] memory expectedDataToSign
    ) internal view {
        address[] memory owners = IGnosisSafe(multisigTask.parentMultisig()).getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            string memory dataToSign = vm.toString(
                multisigTask.getEncodedTransactionData(owners[i], multisigTask.generateApproveMulticallData(actions))
            );
            assertEq(keccak256(bytes(dataToSign)), keccak256(bytes(expectedDataToSign[i])));
        }
    }
}
