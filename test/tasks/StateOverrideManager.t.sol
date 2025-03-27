// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

import {MockMultisigTask} from "test/tasks/mock/MockMultisigTask.sol";
import {MockDisputeGameTask} from "test/tasks/mock/MockDisputeGameTask.sol";
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";

contract StateOverrideManagerUnitTest is Test {
    function setUp() public {
        vm.createSelectFork("mainnet");
    }

    string constant commonToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
        "templateName = \"DisputeGameUpgradeTemplate\"\n" "\n"
        "implementations = [{gameType = 0, implementation = \"0xf691F8A6d908B58C534B624cF16495b491E633BA\", l2ChainId = 10}]\n";
    address constant SECURITY_COUNCIL_CHILD_MULTISIG = 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03;

    function createTempTomlFile(string memory tomlContent) public returns (string memory) {
        string memory randomBytes = LibString.toHexString(uint256(bytes32(vm.randomBytes(32))));
        string memory fileName = string.concat(randomBytes, ".toml");
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
        MultisigTask task = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
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
        MultisigTask task = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
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
        MultisigTask task = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
        assertNonceIncremented(1, task);
        vm.removeFile(fileName);
    }

    function testAddressValueInConfigForStateOverridePasses() public {
        // value is a string representation of an address
        address expectedImplAddr = 0x4da82a327773965b8d4D85Fa3dB8249b387458E7;
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0xC2Be75506d5724086DEB7245bd260Cc9753911Be = [\n",
            "    {key = \"",
            LibString.toHexString(uint256(Constants.PROXY_IMPLEMENTATION_ADDRESS)),
            "\", value = \"",
            LibString.toHexString(expectedImplAddr),
            "\"}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
        address actualImplAddr = address(
            uint160(
                uint256(vm.load(0xC2Be75506d5724086DEB7245bd260Cc9753911Be, Constants.PROXY_IMPLEMENTATION_ADDRESS))
            )
        );
        assertEq(actualImplAddr, expectedImplAddr, "Implementation address is not correct");
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
        MultisigTask task = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
        assertNonceIncremented(101, task);
        vm.removeFile(fileName);
    }

    function testOnlyDefaultTenderlyStateOverridesApplied() public {
        string memory fileName = createTempTomlFile(commonToml);
        MultisigTask task = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);

        uint256 expectedNonce = task.nonce();
        assertDefaultStateOverrides(expectedNonce, 2, task, SECURITY_COUNCIL_CHILD_MULTISIG, 0);
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
        MultisigTask task = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);

        uint256 expectedNonce = 100;
        Simulation.StateOverride[] memory allOverrides =
            assertDefaultStateOverrides(expectedNonce, 3, task, SECURITY_COUNCIL_CHILD_MULTISIG, 0);
        // User defined override must be applied last
        assertEq(allOverrides[2].overrides[0].key, bytes32(uint256(5)), "User defined override key must be 5");
        assertEq(
            allOverrides[2].overrides[0].value,
            bytes32(uint256(expectedNonce)),
            "User defined override must be applied last"
        );
        vm.removeFile(fileName);
    }

    function testAdditionalUserStateOverridesApplied() public {
        bytes32 overrideKey = bytes32(uint256(keccak256("random.slot.testAdditionalUserStateOverridesApplied")) - 1);
        string memory overrideKeyString = LibString.toHexString(uint256(overrideKey));
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = \"",
            overrideKeyString,
            "\", value = 9999}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);

        uint256 expectedParentNonce = task.nonce();
        uint256 expectedTotalOverrides = 3;
        Simulation.StateOverride[] memory allOverrides = assertDefaultStateOverrides(
            expectedParentNonce, expectedTotalOverrides, task, SECURITY_COUNCIL_CHILD_MULTISIG, 0
        );
        assertEq(allOverrides[2].overrides[0].key, overrideKey, "User override key must match expected value");
        assertEq(allOverrides[2].overrides[0].value, bytes32(uint256(9999)), "User override must be applied last");
        vm.removeFile(fileName);
    }

    function testMultipleAddressStateOverridesApplied() public {
        bytes32 overrideKey = bytes32(uint256(keccak256("random.slot.testMultipleAddressStateOverridesApplied")) - 1);
        string memory overrideKeyString = LibString.toHexString(uint256(overrideKey));
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = \"",
            overrideKeyString,
            "\", value = 9999}\n",
            "]\n",
            "0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 = [\n",
            "    {key = \"",
            overrideKeyString,
            "\", value = 8888}\n",
            "]"
        );
        string memory fileName = createTempTomlFile(toml);
        MultisigTask task = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);

        uint256 expectedNonce = task.nonce();
        uint256 expectedTotalOverrides = 4; // i.e. (2 default + 2 user defined)
        Simulation.StateOverride[] memory allOverrides =
            assertDefaultStateOverrides(expectedNonce, expectedTotalOverrides, task, SECURITY_COUNCIL_CHILD_MULTISIG, 0);
        assertEq(
            allOverrides[2].overrides[0].key, overrideKey, "First address user override key must match expected value"
        );
        assertEq(
            allOverrides[2].overrides[0].value, bytes32(uint256(9999)), "First address user override must be applied"
        );
        assertEq(
            allOverrides[3].overrides.length,
            1,
            "Second address is not the parent multisig so it should only have 1 override"
        );
        assertEq(
            allOverrides[3].overrides[0].key, overrideKey, "Second address user override key must match expected value"
        );
        assertEq(
            allOverrides[3].overrides[0].value, bytes32(uint256(8888)), "Second address user override must be applied"
        );
        vm.removeFile(fileName);
    }

    /// @notice This test uses the 'Base Sepolia Testnet' at a block where the ProxyAdminOwner is known to be a single safe.
    /// It verifies that the StateOverrideManager applies only the parent overrides when the child multisig is not set.
    function testOnlyParentOverridesAppliedWhenSingleMultisig() public {
        vm.createSelectFork("sepolia", 7944829);
        string memory nonNestedSafeToml = "l2chains = [{name = \"Base Sepolia Testnet\", chainId = 84532}]\n" "\n"
            "templateName = \"DisputeGameUpgradeTemplate\"\n" "\n"
            "implementations = [{gameType = 0, implementation = \"0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf\", l2ChainId = 84532}]\n";
        string memory fileName = createTempTomlFile(nonNestedSafeToml);
        MockDisputeGameTask dgt = new MockDisputeGameTask();
        dgt.simulateRun(fileName);
        uint256 expectedNonce = dgt.nonce();
        // Only parent overrides will be checked because child multisig is not set.
        Simulation.StateOverride[] memory allOverrides =
            assertDefaultStateOverrides(expectedNonce, 1, dgt, address(0), 0);
        assertEq(allOverrides.length, 1, "Only parent overrides should be applied");
        vm.removeFile(fileName);
    }

    function createAndRunTask(string memory fileName, address childMultisig) internal returns (MultisigTask) {
        MultisigTask task = new MockMultisigTask();
        task.signFromChildMultisig(fileName, childMultisig);
        return task;
    }

    function assertNonceIncremented(uint256 expectedNonce, MultisigTask task) internal view {
        assertEq(task.nonce(), expectedNonce, string.concat("Expected nonce ", LibString.toString(expectedNonce)));
        uint256 actualNonce = uint256(vm.load(address(task.parentMultisig()), bytes32(uint256(0x5))));
        assertEq(actualNonce, expectedNonce + 1, "Nonce must be incremented by 1 in memory after task is run");
    }

    /// @notice This function is used to assert the default state overrides for the parent multisig.
    /// Specifically, it verifies that the parent state overrides contain a threshold and nonce override.
    function assertDefaultStateOverrides(
        uint256 expectedParentNonce,
        uint256 expectedTotalOverrides,
        MultisigTask task,
        address childMultisig,
        uint256 childMultisigNonce
    ) internal view returns (Simulation.StateOverride[] memory allOverrides_) {
        allOverrides_ =
            task.getStateOverrides(address(task.parentMultisig()), task.nonce(), childMultisig, childMultisigNonce);

        assertTrue(allOverrides_.length >= 1, "Must be at least 1 override (parent default)");
        assertEq(
            allOverrides_.length,
            expectedTotalOverrides,
            string.concat("Total number of overrides must be ", LibString.toString(expectedTotalOverrides))
        );

        Simulation.StateOverride memory parentDefaultOverride = allOverrides_[0];
        assertEq(
            parentDefaultOverride.contractAddress,
            address(task.parentMultisig()),
            "Contract address must be the parent multisig"
        );
        // 5 possible overrides: <threshold>, <nonce>, [owner count], [owner mapping], [owner mapping 2]
        // 2 required overrides: <threshold>, <nonce>
        // 3 optional overrides: [owner count], [owner mapping], [owner mapping 2] (Only present for nested execution)
        if (childMultisig != address(0)) {
            // Nested execution
            assertTrue(
                parentDefaultOverride.overrides.length == 2,
                string.concat(
                    "Parent default override must have 2 overrides, found: ",
                    LibString.toString(parentDefaultOverride.overrides.length)
                )
            );
        } else {
            // Single execution
            assertTrue(
                parentDefaultOverride.overrides.length == 5,
                string.concat(
                    "Parent default override must have 5 overrides, found: ",
                    LibString.toString(parentDefaultOverride.overrides.length)
                )
            );
            // address(this) should be the owner override for the parent multisig in a single execution.
            assertOwnerOverrides(parentDefaultOverride, address(this));
        }
        assertEq(
            parentDefaultOverride.overrides[0].key,
            bytes32(uint256(0x4)),
            "ParentDefaultOverride: Must contain a threshold override"
        );
        assertEq(
            parentDefaultOverride.overrides[0].value,
            bytes32(uint256(0x1)),
            "ParentDefaultOverride: Threshold override must be 1"
        );
        assertEq(
            parentDefaultOverride.overrides[1].key,
            bytes32(uint256(0x5)),
            "ParentDefaultOverride: Must contain a nonce override"
        );
        assertEq(
            parentDefaultOverride.overrides[1].value,
            bytes32(expectedParentNonce),
            "ParentDefaultOverride: Nonce override must match expected value"
        );

        // If child multisig is not set, we don't need to assert the child overrides.
        if (childMultisig != address(0)) {
            assertDefaultChildStateOverrides(allOverrides_, childMultisig, childMultisigNonce);
        }
    }

    /// @notice This function is used to assert the default state overrides for the child multisig.
    /// Specifically, it verifies that the child state overrides contain a threshold, nonce, owner count, and owner mapping overrides.
    function assertDefaultChildStateOverrides(
        Simulation.StateOverride[] memory allOverrides,
        address childMultisig,
        uint256 childMultisigNonce
    ) internal pure {
        assertTrue(
            allOverrides.length >= 2,
            "ChildDefaultOverride: Must be at least 2 overrides (parent default + child default)"
        );
        Simulation.StateOverride memory childDefaultOverride = allOverrides[1];

        assertEq(
            childDefaultOverride.contractAddress,
            childMultisig,
            "ChildDefaultOverride: Contract address must be the child multisig"
        );
        assertTrue(
            childDefaultOverride.overrides.length == 5,
            string.concat(
                "ChildDefaultOverride: Default override must have 5 overrides, found: ",
                LibString.toString(childDefaultOverride.overrides.length)
            )
        );
        assertEq(
            childDefaultOverride.overrides[0].key,
            bytes32(uint256(0x4)),
            "ChildDefaultOverride: Must contain a threshold override"
        );
        assertEq(
            childDefaultOverride.overrides[0].value,
            bytes32(uint256(0x1)),
            "ChildDefaultOverride: Threshold override must be 1"
        );
        assertEq(
            childDefaultOverride.overrides[1].key,
            bytes32(uint256(0x5)),
            "ChildDefaultOverride: Must contain a nonce override"
        );
        assertEq(
            childDefaultOverride.overrides[1].value,
            bytes32(childMultisigNonce),
            "ChildDefaultOverride: Nonce override must match expected value"
        );
        // MULTICALL3_ADDRESS should be the owner override for the child multisig in a nested execution.
        assertOwnerOverrides(childDefaultOverride, MULTICALL3_ADDRESS);
    }

    function assertOwnerOverrides(Simulation.StateOverride memory defaultOverride, address expectedOwnerOverride)
        private
        pure
    {
        assertEq(
            defaultOverride.overrides[2].key,
            bytes32(uint256(0x3)),
            "ChildDefaultOverride: Must contain an owner count override"
        );
        assertEq(
            defaultOverride.overrides[2].value,
            bytes32(uint256(0x1)),
            "ChildDefaultOverride: Owner count override must be 1"
        );

        // Verify owner mapping overrides
        // Calculate the storage slot for owner mapping: keccak256(abi.encode(1, 2))
        // where 1 is the owner index and 2 is the mapping slot in the contract
        bytes32 ownerMappingSlot = keccak256(abi.encode(uint256(1), uint256(2)));
        assertEq(
            defaultOverride.overrides[3].key,
            ownerMappingSlot,
            "Owner Override: Must contain first owner mapping override"
        );
        assertEq(
            defaultOverride.overrides[3].value,
            bytes32(uint256(uint160(expectedOwnerOverride))), // Necessary for exhaustive tenderly debug trace.
            "Owner Override: Incorrect first owner mapping override"
        );

        // Calculate the storage slot for owner mapping: keccak256(abi.encode(MULTICALL3_ADDRESS, 2))
        // where MULTICALL3_ADDRESS is the address of the Multicall3 contract and 2 is the mapping slot in the contract
        bytes32 ownerMappingSlot2 = keccak256(abi.encode(uint256(uint160(expectedOwnerOverride)), uint256(2)));
        assertEq(
            defaultOverride.overrides[4].key,
            ownerMappingSlot2,
            "Owner Override: Must contain second owner mapping override"
        );
        assertEq(
            defaultOverride.overrides[4].value,
            bytes32(uint256(0x1)),
            "Owner Override: Must contain second owner mapping override value"
        );
    }
}
