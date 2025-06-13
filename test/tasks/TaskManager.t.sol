// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {TaskManager} from "src/improvements/tasks/TaskManager.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {StateOverrideManager} from "src/improvements/tasks/StateOverrideManager.sol";
import {TaskConfig, L2Chain} from "src/libraries/MultisigTypes.sol";
import {Vm} from "forge-std/Vm.sol";

contract TaskManagerUnitTest is StateOverrideManager, Test {
    using LibString for string;

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

    function testNormalizedHashCheck_Passes() public {
        TaskManager tm = new TaskManager();
        TaskConfig memory config = TaskConfig({
            optionalL2Chains: new L2Chain[](0),
            basePath: "test/tasks/example/eth/004-fp-set-respected-game-type",
            configPath: "",
            templateName: "",
            parentMultisig: address(0),
            isNested: true,
            task: address(0)
        });
        // Doesn't have a VALIDATION markdown file.
        assertTrue(tm.checkNormalizedHash(bytes32(hex"1230"), config));
        assertTrue(tm.checkNormalizedHash(bytes32(hex"1234"), config));

        // Does have a VALIDATION markdown file and hash matches.
        config.basePath = "src/improvements/tasks/eth/013-gas-params-op";
        assertTrue(
            tm.checkNormalizedHash(
                bytes32(hex"2576512ad010b917c049a392e916bb02de1c168477fe29c4f8cbc4fcb016a4b0"), config
            )
        );
    }

    function testNormalizedHashCheck_Fails() public {
        TaskManager tm = new TaskManager();
        TaskConfig memory config = TaskConfig({
            optionalL2Chains: new L2Chain[](0),
            basePath: "src/improvements/tasks/eth/013-gas-params-op",
            configPath: "",
            templateName: "",
            parentMultisig: address(0),
            isNested: true,
            task: address(0)
        });
        // Does have a VALIDATION markdown file and hash does not match.
        assertFalse(tm.checkNormalizedHash(bytes32(hex"10"), config));
    }

    function testDataToSignCheck_Passes() public {
        vm.createSelectFork("mainnet"); // Pinning to a block.
        TaskManager tm = new TaskManager();
        TaskConfig memory config = TaskConfig({
            optionalL2Chains: new L2Chain[](0),
            basePath: "test/tasks/example/eth/004-fp-set-respected-game-type",
            configPath: "",
            templateName: "",
            parentMultisig: address(0x847B5c174615B1B7fDF770882256e2D3E95b9D92),
            isNested: true,
            task: address(0)
        });
        bytes memory dataToSign =
            hex"1901a4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672f654f4cec87ea0aee5f1632a35fe9184a0ab53cd9a6c3d86fdcd0fdb446abf76";

        // Doesn't have a VALIDATION markdown file.
        assertTrue(tm.checkDataToSign(dataToSign, config));

        // Does have a VALIDATION markdown file and domain and message hash matches.
        config.basePath = "src/improvements/tasks/eth/013-gas-params-op";
        assertTrue(tm.checkDataToSign(dataToSign, config));
    }

    function testDataToSignCheck_Fails() public {
        TaskManager tm = new TaskManager();
        TaskConfig memory config = TaskConfig({
            optionalL2Chains: new L2Chain[](0),
            basePath: "src/improvements/tasks/eth/013-gas-params-op",
            configPath: "",
            templateName: "",
            parentMultisig: address(0x847B5c174615B1B7fDF770882256e2D3E95b9D92),
            isNested: true,
            task: address(0)
        });
        bytes memory fakeDataToSign =
            hex"190111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000";
        // Does have a VALIDATION markdown file and data to sign does not match.
        assertFalse(tm.checkDataToSign(fakeDataToSign, config));
    }
}
