// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MockMultisigTask} from "test/tasks/mock/MockMultisigTask.sol";
import {Simulation} from "src/improvements/tasks/MultisigTask.sol";
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";

contract StateOverrideManagerUnitTest is Test {
    function setUp() public {
        vm.createSelectFork("mainnet");
    }

    string constant commonToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
        "templateName = \"DisputeGameUpgradeTemplate\"\n" "\n"
        "implementations = [{gameType = 0, implementation = \"0xf691F8A6d908B58C534B624cF16495b491E633BA\", l2ChainId = 10}]\n";

    function createTempTomlFile(string memory tomlContent) internal returns (string memory) {
        string memory fileName =
            string.concat(LibString.toHexString(uint256(keccak256(abi.encode(tomlContent)))), ".toml");
        vm.writeFile(fileName, tomlContent);
        return fileName;
    }

    function testNonceAndThresholdStateOverrideApplied() public {
        // This config includes both nonce and threshold state overrides.
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = \"0x0000000000000000000000000000000000000000000000000000000000000005\", value = \"0x0000000000000000000000000000000000000000000000000000000000000FFF\"},\n",
            "    {key = \"0x0000000000000000000000000000000000000000000000000000000000000004\", value = \"0x0000000000000000000000000000000000000000000000000000000000000002\"}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = createAndRunTask(fileName);
        assertNonceIncremented(4095, task);
        assertEq(IGnosisSafe(task.parentMultisig()).getThreshold(), 2, "Threshold must be 2");
        uint256 threshold = uint256(vm.load(address(task.parentMultisig()), bytes32(uint256(0x4))));
        assertEq(threshold, 2, "Threshold must be 2 using vm.load");
        vm.removeFile(fileName);
    }

    function testNonceStateOverrideApplied() public {
        // This config only applies a nonce override.
        // 0xAAA in hex is 2730 in decimal.
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = \"0x0000000000000000000000000000000000000000000000000000000000000005\", value = \"0x0000000000000000000000000000000000000000000000000000000000000AAA\"}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = createAndRunTask(fileName);
        assertNonceIncremented(2730, task);
        vm.removeFile(fileName);
    }

    function testInvalidAddressInStateOverrideFails() public {
        // Test with invalid address
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x1234 = [\n", // Invalid address
            "    {key = \"0x0000000000000000000000000000000000000000000000000000000000000005\", value = \"0x0000000000000000000000000000000000000000000000000000000000000001\"}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = new MockMultisigTask();
        vm.expectRevert();
        task.simulateRun(fileName);
        vm.removeFile(fileName);
    }

    function testDecimalKeyInConfigForStateOverridePasses() public {
        // key is a decimal number (important: not surrounded by quotes)
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = 5, value = \"0x0000000000000000000000000000000000000000000000000000000000000001\"}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = createAndRunTask(fileName);
        assertNonceIncremented(1, task);
        vm.removeFile(fileName);
    }

    function testDecimalValuesInConfigForStateOverridePasses() public {
        // key and value are decimal numbers (important: not surrounded by quotes)
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = 5, value = 101}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = createAndRunTask(fileName);
        assertNonceIncremented(101, task);
        vm.removeFile(fileName);
    }

    function testOnlyDefaultTenderlyStateOverridesApplied() public {
        string memory fileName = createTempTomlFile(commonToml);
        MultisigTask task = createAndRunTask(fileName);

        uint256 expectedNonce = task.nonce();
        uint256 defaultOverridesLen = 5;
        assertDefaultStateOverrides(expectedNonce, 1, defaultOverridesLen, task);

        vm.removeFile(fileName);
    }

    function testUserTenderlyStateOverridesTakePrecedence() public {
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = 5, value = 100}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = createAndRunTask(fileName);

        uint256 expectedNonce = 100;
        uint256 defaultParentMultisigOverridesLen = 5;
        assertDefaultStateOverrides(expectedNonce, 1, defaultParentMultisigOverridesLen, task);

        vm.removeFile(fileName);
    }

    function testAdditionalUserStateOverridesApplied() public {
        // bytes32(uint256(keccak256('random.slot.testAdditionalUserStateOverridesApplied')) - 1)
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = \"0x1c817c894a1443ac14bff2139acff0976be484b1fcecf627833591a0e476b5d7\", value = 9999}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = createAndRunTask(fileName);

        uint256 expectedNonce = task.nonce();
        uint256 totalParentMultisigOverridesLen = 6;
        Simulation.StateOverride[] memory combinedOverrides =
            assertDefaultStateOverrides(expectedNonce, 1, totalParentMultisigOverridesLen, task);
        assertEq(combinedOverrides[0].overrides[5].value, bytes32(uint256(9999)), "User override must be applied");

        vm.removeFile(fileName);
    }

    function testMultipleAddressStateOverridesApplied() public {
        // bytes32(uint256(keccak256('random.slot.testAdditionalUserStateOverridesApplied')) - 1)
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = \"0x1c817c894a1443ac14bff2139acff0976be484b1fcecf627833591a0e476b5d7\", value = 9999}\n",
            "]\n",
            "0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 = [\n",
            "    {key = \"0x1c817c894a1443ac14bff2139acff0976be484b1fcecf627833591a0e476b5d7\", value = 8888}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = createAndRunTask(fileName);

        uint256 expectedNonce = task.nonce();
        uint256 totalParentMultisigOverridesLen = 6;
        Simulation.StateOverride[] memory combinedOverrides =
            assertDefaultStateOverrides(expectedNonce, 2, totalParentMultisigOverridesLen, task);
        assertEq(
            combinedOverrides[0].overrides[5].value,
            bytes32(uint256(9999)),
            "First address user override must be applied"
        );
        assertEq(
            combinedOverrides[1].overrides.length,
            1,
            "Second address is not the parent multisig so it should only have 1 override"
        );
        assertEq(
            combinedOverrides[1].overrides[0].value,
            bytes32(uint256(8888)),
            "Second address user override must be applied"
        );
        vm.removeFile(fileName);
    }

    function createAndRunTask(string memory fileName) internal returns (MultisigTask) {
        MultisigTask task = new MockMultisigTask();
        task.simulateRun(fileName);
        return task;
    }

    function assertNonceIncremented(uint256 expectedNonce, MultisigTask task) internal view {
        assertEq(task.nonce(), expectedNonce, string.concat("Expected nonce ", LibString.toString(expectedNonce)));
        uint256 actualNonce = uint256(vm.load(address(task.parentMultisig()), bytes32(uint256(0x5))));
        assertEq(actualNonce, expectedNonce + 1, "Nonce must be incremented by 1 in memory after task is run");
    }

    function assertDefaultStateOverrides(
        uint256 expectedNonce,
        uint256 totalOverrides,
        uint256 totalParentMultisigOverrides,
        MultisigTask task
    ) internal view returns (Simulation.StateOverride[] memory combinedOverrides_) {
        combinedOverrides_ = task.getStateOverrides(address(task.parentMultisig()), task.nonce());

        assertEq(combinedOverrides_.length, totalOverrides, "Combined overrides must be 1");
        Simulation.StateOverride memory singleOverride = combinedOverrides_[0];
        assertEq(
            singleOverride.contractAddress,
            address(task.parentMultisig()),
            "Contract address must be the parent multisig"
        );
        assertTrue(singleOverride.overrides.length >= 5, "Overrides length must be at least 5");
        assertEq(singleOverride.overrides.length, totalParentMultisigOverrides, "Unexpected number of state overrides");
        assertEq(singleOverride.overrides[0].key, bytes32(uint256(0x4)), "Must contain a threshold override");
        assertEq(singleOverride.overrides[0].value, bytes32(uint256(0x1)), "Threshold override must be 1");
        assertEq(singleOverride.overrides[1].key, bytes32(uint256(0x5)), "Must contain a nonce override");
        assertEq(singleOverride.overrides[1].value, bytes32(expectedNonce), "Nonce override must match expected value");
        assertEq(singleOverride.overrides[2].key, bytes32(uint256(0x3)), "Must contain an owner count override");
        assertEq(singleOverride.overrides[2].value, bytes32(uint256(0x1)), "Owner count override must be 1");
        // Verify owner mapping overrides
        assertEq(
            singleOverride.overrides[3].key,
            bytes32(uint256(0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0)),
            "Must contain first owner mapping override"
        );
        assertEq(
            singleOverride.overrides[3].value,
            bytes32(uint256(0x0000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496)),
            "Incorrect first owner mapping override"
        );
        assertEq(
            singleOverride.overrides[4].key,
            bytes32(uint256(0x6e10ff27cae71a13525bd61167857e5c982b4674c8e654900e4e9d5035811f78)),
            "Must contain second owner mapping override"
        );
        assertEq(
            singleOverride.overrides[4].value, bytes32(uint256(0x1)), "Must contain second owner mapping override value"
        );
        return combinedOverrides_;
    }
}
