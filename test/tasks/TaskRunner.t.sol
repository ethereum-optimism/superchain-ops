// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {TaskRunner} from "src/improvements/tasks/TaskRunner.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {StateOverrideManager} from "src/improvements/tasks/StateOverrideManager.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

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

    function testAppendStateOverrides_NoStateDiffs() public {
        TaskRunner tr = new TaskRunner();

        string memory fileName = createTempTomlFile(commonToml);
        tr.appendStateOverrides(fileName, new AccountAccessParser.DecodedStateDiff[](0));

        string memory toml = vm.readFile(fileName);
        assertTrue(!toml.contains("[stateOverrides]"));
        removeFile(fileName);
    }

    function testAppendStateOverrides_WithMultipleStateDiffs() public {
        TaskRunner tr = new TaskRunner();
        AccountAccessParser.DecodedStateDiff[] memory stateDiffs = new AccountAccessParser.DecodedStateDiff[](2);
        stateDiffs[0] =
            createStateDiff(makeAddr("first-state-diff"), bytes32(uint256(5)), bytes32(uint256(5)), bytes32(uint256(5)));
        stateDiffs[1] = createStateDiff(
            makeAddr("second-state-diff"), bytes32(uint256(6)), bytes32(uint256(6)), bytes32(uint256(6))
        );

        string memory fileName = createTempTomlFile(commonToml);
        tr.appendStateOverrides(fileName, stateDiffs);

        Simulation.StateOverride[] memory stateOverrides = _readStateOverridesFromConfig(fileName);
        assertEq(stateOverrides.length, 2);
        assertEq(stateOverrides[0].contractAddress, makeAddr("first-state-diff"));
        assertEq(stateOverrides[0].overrides.length, 1);
        assertEq(stateOverrides[0].overrides[0].key, bytes32(uint256(5)));
        assertEq(stateOverrides[0].overrides[0].value, bytes32(uint256(5)));
        assertEq(stateOverrides[1].contractAddress, makeAddr("second-state-diff"));
        assertEq(stateOverrides[1].overrides.length, 1);
        assertEq(stateOverrides[1].overrides[0].key, bytes32(uint256(6)));
        assertEq(stateOverrides[1].overrides[0].value, bytes32(uint256(6)));
        removeFile(fileName);
    }

    function testAppendStateOverrides_WithSingleStateDiff() public {
        TaskRunner tr = new TaskRunner();
        AccountAccessParser.DecodedStateDiff[] memory stateDiffs = new AccountAccessParser.DecodedStateDiff[](2);
        stateDiffs[0] =
            createStateDiff(makeAddr("first-state-diff"), bytes32(uint256(1)), bytes32(uint256(2)), bytes32(uint256(3)));

        string memory fileName = createTempTomlFile(commonToml);
        tr.appendStateOverrides(fileName, stateDiffs);

        Simulation.StateOverride[] memory stateOverrides = _readStateOverridesFromConfig(fileName);
        assertEq(stateOverrides.length, 2);
        assertEq(stateOverrides[0].contractAddress, makeAddr("first-state-diff"));
        assertEq(stateOverrides[0].overrides.length, 1);
        assertEq(stateOverrides[0].overrides[0].key, bytes32(uint256(1)));
        assertEq(stateOverrides[0].overrides[0].value, bytes32(uint256(3)));
        removeFile(fileName);
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

    function createTempTomlFile(string memory tomlContent) public returns (string memory) {
        string memory randomBytes = LibString.toHexString(uint256(bytes32(vm.randomBytes(32))));
        string memory fileName = string.concat(randomBytes, ".toml");
        vm.writeFile(fileName, tomlContent);
        return fileName;
    }

    /// @notice This function is used to remove a file. The reason we use a try catch
    /// is because sometimes the file may not exist and this leads to flaky tests.
    function removeFile(string memory fileName) internal {
        try vm.removeFile(fileName) {} catch {}
    }
}
