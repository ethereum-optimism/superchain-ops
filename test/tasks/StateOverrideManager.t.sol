// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Vm} from "forge-std/Vm.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Solarray} from "lib/optimism/packages/contracts-bedrock/scripts/libraries/Solarray.sol";

import {MockMultisigTask} from "test/tasks/mock/MockMultisigTask.sol";
import {MockSetEIP1967ImplTask} from "test/tasks/mock/MockSetEIP1967ImplTask.sol";
import {MultisigTask} from "src/tasks/MultisigTask.sol";
import {StateOverrideManager} from "src/tasks/StateOverrideManager.sol";
import {MultisigTaskTestHelper as helper} from "test/tasks/MultisigTask.t.sol";
import {console} from "forge-std/console.sol";

contract StateOverrideManagerUnitTest is Test {
    string constant TESTING_DIRECTORY = "state-override-manager-testing";

    function setUp() public {
        vm.createSelectFork("mainnet");
    }

    string constant commonToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
        "templateName = \"SetEIP1967Implementation\"\n" "\n" "contractIdentifier = \"OptimismPortalProxy\"\n" "\n"
        "newImplementation = \"0xf691F8A6d908B58C534B624cF16495b491E633BA\"\n";
    address constant ROOT_SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant SECURITY_COUNCIL_CHILD_MULTISIG = 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03;

    function testThresholdStateOverrideAppliedReverts() public {
        // This config includes both nonce and threshold state overrides.
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = \"0x0000000000000000000000000000000000000000000000000000000000000004\", value = \"0x0000000000000000000000000000000000000000000000000000000000000002\"}\n",
            "]"
        );
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "000");

        MultisigTask task = new MockMultisigTask();
        vm.expectRevert(
            "StateOverrideManager: User-defined override is attempting to overwrite an existing default override for contract: 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A"
        );
        task.simulate(fileName, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG));
        helper.removeFile(fileName);
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
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "001");
        (, address rootSafe) = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
        assertNonceIncremented(2730, rootSafe);
        helper.removeFile(fileName);
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
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "002");
        MultisigTask task = new MockMultisigTask();
        vm.expectRevert();
        task.simulate(fileName, new address[](0));
        helper.removeFile(fileName);
    }

    function testDecimalKeyInConfigForStateOverridePasses() public {
        vm.createSelectFork("mainnet", 22306974); // Pinning to a block to avoid nonce errors.
        // key is a decimal number (important: not surrounded by quotes)
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = 5, value = \"0x000000000000000000000000000000000000000000000000000000000000000c\"}\n",
            "]"
        );
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "003");
        (, address rootSafe) = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
        assertNonceIncremented(12, rootSafe);
        helper.removeFile(fileName);
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
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "004");
        createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
        address actualImplAddr = address(
            uint160(
                uint256(vm.load(0xC2Be75506d5724086DEB7245bd260Cc9753911Be, Constants.PROXY_IMPLEMENTATION_ADDRESS))
            )
        );
        assertEq(actualImplAddr, expectedImplAddr, "Implementation address is not correct");
        helper.removeFile(fileName);
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
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "005");
        (, address rootSafe) = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
        assertNonceIncremented(101, rootSafe);
        helper.removeFile(fileName);
    }

    function testOnlyDefaultTenderlyStateOverridesApplied() public {
        string memory fileName = helper.createTempTomlFile(commonToml, TESTING_DIRECTORY, "006");
        (MultisigTask task, address rootSafe) = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);
        assertDefaultStateOverrides(2, task, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG), rootSafe);
        helper.removeFile(fileName);
    }

    /// @notice This test verifies that user-defined overrides take precedence over default overrides.
    function testUserTenderlyStateOverridesTakePrecedence() public {
        string memory noStateOverridesFileName = helper.createTempTomlFile(commonToml, TESTING_DIRECTORY, "007");
        uint256 expectedNonce = IGnosisSafe(ROOT_SAFE).nonce();
        (MultisigTask noStateOverridesTask, address rootSafe) =
            createAndRunTask(noStateOverridesFileName, SECURITY_COUNCIL_CHILD_MULTISIG);
        assertDefaultStateOverrides(
            2, noStateOverridesTask, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG), rootSafe
        );

        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = 5, value = 1024},\n",
            "    {key = 6, value = 1025}\n",
            "]"
        );
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "008");
        (MultisigTask task,) = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);

        uint256 expectedUserOverrideNonce = 1024;
        uint256 expectedRandomEntry = 1025;
        Simulation.StateOverride[] memory allOverrides =
            assertDefaultStateOverrides(2, task, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG), rootSafe);
        // User defined override must be applied last
        assertEq(allOverrides.length, 2, "Incorrect number of overrides");
        assertEq(allOverrides[0].overrides[1].key, bytes32(uint256(5)), "User defined override key must be 5");
        assertEq(
            allOverrides[0].overrides[1].value,
            bytes32(uint256(expectedUserOverrideNonce)),
            "User defined override value must match expected value"
        );
        assertEq(allOverrides[0].overrides[2].key, bytes32(uint256(6)), "User defined override key must be 6");
        assertEq(
            allOverrides[0].overrides[2].value,
            bytes32(uint256(expectedRandomEntry)),
            "User defined override value must match expected value"
        );
        assertTrue(expectedNonce != expectedUserOverrideNonce, "Real nonce must not match user override nonce.");
        helper.removeFile(noStateOverridesFileName);
        helper.removeFile(fileName);
    }

    /// @notice This test verifies that additional user defined overrides (that aren't already existing e.g. nonce, threshold)
    /// are applied to the end of the array.
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
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "009");
        (MultisigTask task, address rootSafe) = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);

        uint256 expectedTotalOverrides = 2;
        Simulation.StateOverride[] memory allOverrides = assertDefaultStateOverrides(
            expectedTotalOverrides, task, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG), rootSafe
        );
        assertEq(allOverrides[0].overrides[1].key, overrideKey, "User override key must match expected value");
        assertEq(allOverrides[0].overrides[1].value, bytes32(uint256(9999)), "User override must be applied last");
        helper.removeFile(fileName);
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
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "010");
        (MultisigTask task, address rootSafe) = createAndRunTask(fileName, SECURITY_COUNCIL_CHILD_MULTISIG);

        uint256 expectedTotalOverrides = 3; // i.e. (2 default + 1 user defined)
        Simulation.StateOverride[] memory allOverrides = assertDefaultStateOverrides(
            expectedTotalOverrides, task, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG), rootSafe
        );

        assertEq(
            allOverrides[0].overrides[1].key, overrideKey, "First address user override key must match expected value"
        );
        assertEq(
            allOverrides[0].overrides[1].value, bytes32(uint256(9999)), "First address user override must be applied"
        );
        assertEq(
            allOverrides[2].overrides.length,
            1,
            "Third address is not the parent multisig so it should only have 1 override"
        );
        assertEq(
            allOverrides[0].contractAddress,
            address(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A),
            "First address must be the parent multisig"
        );
        assertEq(
            allOverrides[1].contractAddress,
            SECURITY_COUNCIL_CHILD_MULTISIG,
            "Second address must be the child multisig"
        );
        assertEq(
            allOverrides[2].contractAddress,
            address(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290),
            "Third address must be the child multisig"
        );
        assertEq(
            allOverrides[2].overrides[0].key, overrideKey, "Third address user override key must match expected value"
        );
        assertEq(
            allOverrides[2].overrides[0].value, bytes32(uint256(8888)), "Third address user override must be applied"
        );
        helper.removeFile(fileName);
    }

    /// @notice This test uses the 'Base Sepolia Testnet' at a block where the ProxyAdminOwner is known to be a single safe.
    /// It verifies that the StateOverrideManager applies only the parent overrides when the child multisig is not set.
    function testOnlyParentOverridesAppliedWhenSingleMultisig() public {
        vm.createSelectFork("sepolia", 7944829);
        string memory nonNestedSafeToml = "l2chains = [{name = \"Base Sepolia Testnet\", chainId = 84532}]\n" "\n"
            "templateName = \"SetEIP1967Implementation\"\n" "\n" "contractIdentifier = \"OptimismPortalProxy\"\n" "\n"
            "newImplementation = \"0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf\"\n";
        string memory fileName = helper.createTempTomlFile(nonNestedSafeToml, TESTING_DIRECTORY, "011");

        MockSetEIP1967ImplTask si = new MockSetEIP1967ImplTask();
        (,,, address rootSafe) = si.simulate(fileName, new address[](0));

        // Only parent overrides will be checked because child multisig is not set.
        Simulation.StateOverride[] memory allOverrides = assertDefaultStateOverrides(1, si, new address[](0), rootSafe);
        assertEq(allOverrides.length, 1, "Only parent overrides should be applied");
        helper.removeFile(fileName);
    }

    function test_appendUserDefinedOverrides_userAttemptsToOverwriteDefaultTenderlyOverrideReverts() public {
        MockStateOverrideManager som = new MockStateOverrideManager();
        Simulation.StateOverride[] memory defaults = new Simulation.StateOverride[](1);
        defaults[0] = Simulation.StateOverride({
            contractAddress: address(0x123),
            overrides: _createStorageOverrides("key1", "value1")
        });

        Simulation.StateOverride memory userOverride = Simulation.StateOverride({
            contractAddress: address(0x123),
            overrides: _createStorageOverrides("key1", "newValue")
        });

        vm.expectRevert(
            "StateOverrideManager: User-defined override is attempting to overwrite an existing default override for contract: 0x0000000000000000000000000000000000000123"
        );
        som.wrapperAppendUserDefinedOverrides(defaults, userOverride);
    }

    function test_appendUserDefinedOverrides_appendsNewKey() public {
        MockStateOverrideManager som = new MockStateOverrideManager();
        Simulation.StateOverride[] memory defaults = new Simulation.StateOverride[](1);
        defaults[0] = Simulation.StateOverride({
            contractAddress: address(0x123),
            overrides: _createStorageOverrides("key1", "value1")
        });

        Simulation.StateOverride memory userOverride = Simulation.StateOverride({
            contractAddress: address(0x123),
            overrides: _createStorageOverrides("key2", "value2")
        });

        Simulation.StateOverride[] memory updatedOverrides =
            som.wrapperAppendUserDefinedOverrides(defaults, userOverride);

        assertEq(updatedOverrides[0].overrides.length, 2);
        assertEq(updatedOverrides[0].overrides[1].key, _toBytes32("key2"));
        assertEq(updatedOverrides[0].overrides[1].value, _toBytes32("value2"));
    }

    function test_appendUserDefinedOverrides_contractNotFound() public {
        MockStateOverrideManager som = new MockStateOverrideManager();
        Simulation.StateOverride[] memory defaults = new Simulation.StateOverride[](1);
        defaults[0] = Simulation.StateOverride({
            contractAddress: address(0x123),
            overrides: _createStorageOverrides("key1", "value1")
        });

        Simulation.StateOverride memory userOverride = Simulation.StateOverride({
            contractAddress: address(0x456),
            overrides: _createStorageOverrides("key2", "value2")
        });

        Simulation.StateOverride[] memory updatedOverrides =
            som.wrapperAppendUserDefinedOverrides(defaults, userOverride);

        assertEq(updatedOverrides[0].overrides[0].value, _toBytes32("value1")); // Ensure no changes
        assertEq(updatedOverrides.length, 2);
        assertEq(updatedOverrides[0].contractAddress, address(0x123));
        assertEq(updatedOverrides[1].contractAddress, address(0x456));
    }

    function test_appendUserDefinedOverrides_mixedAppends() public {
        MockStateOverrideManager som = new MockStateOverrideManager();
        Simulation.StateOverride[] memory defaults = new Simulation.StateOverride[](1);
        defaults[0] =
            Simulation.StateOverride({contractAddress: address(0x123), overrides: new Simulation.StorageOverride[](2)});
        defaults[0].overrides[0] = Simulation.StorageOverride(_toBytes32("key1"), _toBytes32("value1"));
        defaults[0].overrides[1] = Simulation.StorageOverride(_toBytes32("key2"), _toBytes32("value2"));

        Simulation.StateOverride memory userOverride =
            Simulation.StateOverride({contractAddress: address(0x123), overrides: new Simulation.StorageOverride[](2)});
        userOverride.overrides[0] = Simulation.StorageOverride(_toBytes32("key3"), _toBytes32("value3"));
        userOverride.overrides[1] = Simulation.StorageOverride(_toBytes32("key5"), _toBytes32("newValue5"));

        Simulation.StateOverride[] memory updatedOverrides =
            som.wrapperAppendUserDefinedOverrides(defaults, userOverride);

        assertEq(updatedOverrides[0].overrides.length, 4);
        assertEq(updatedOverrides[0].overrides[0].value, _toBytes32("value1"));
        assertEq(updatedOverrides[0].overrides[1].value, _toBytes32("value2"));
        assertEq(updatedOverrides[0].overrides[2].key, _toBytes32("key3"));
        assertEq(updatedOverrides[0].overrides[2].value, _toBytes32("value3"));
        assertEq(updatedOverrides[0].overrides[3].key, _toBytes32("key5"));
        assertEq(updatedOverrides[0].overrides[3].value, _toBytes32("newValue5"));
    }

    function test_appendUserDefinedOverrides_emptyDefaults() public {
        MockStateOverrideManager som = new MockStateOverrideManager();
        Simulation.StateOverride[] memory defaults = new Simulation.StateOverride[](0);
        Simulation.StateOverride memory userOverride = Simulation.StateOverride({
            contractAddress: address(0x123),
            overrides: _createStorageOverrides("key1", "value1")
        });

        Simulation.StateOverride[] memory updatedOverrides =
            som.wrapperAppendUserDefinedOverrides(defaults, userOverride);

        assertEq(updatedOverrides.length, 1);
    }

    function test_appendUserDefinedOverrides_contractMatchOnly() public {
        MockStateOverrideManager som = new MockStateOverrideManager();
        Simulation.StateOverride[] memory defaults = new Simulation.StateOverride[](1);
        defaults[0] = Simulation.StateOverride({
            contractAddress: address(0x123),
            overrides: _createStorageOverrides("key1", "value1")
        });

        Simulation.StateOverride memory userOverride =
            Simulation.StateOverride({contractAddress: address(0x123), overrides: new Simulation.StorageOverride[](0)});

        Simulation.StateOverride[] memory updatedOverrides =
            som.wrapperAppendUserDefinedOverrides(defaults, userOverride);

        assertEq(updatedOverrides[0].overrides.length, 1); // No changes to storage overrides
        assertEq(updatedOverrides[0].overrides[0].key, _toBytes32("key1"));
        assertEq(updatedOverrides[0].overrides[0].value, _toBytes32("value1"));
    }

    function test_appendUserDefinedOverrides_userOverrideContainsMultipleOverridesForTheSameKeyReverts() public {
        MockStateOverrideManager som = new MockStateOverrideManager();
        Simulation.StateOverride[] memory defaults = new Simulation.StateOverride[](1);
        defaults[0] = Simulation.StateOverride({
            contractAddress: address(0x123),
            overrides: _createStorageOverrides("key1", "value1")
        });

        Simulation.StateOverride memory userOverride =
            Simulation.StateOverride({contractAddress: address(0x123), overrides: new Simulation.StorageOverride[](2)});
        userOverride.overrides[0] = Simulation.StorageOverride(_toBytes32("key2"), _toBytes32("newValue1"));
        userOverride.overrides[1] = Simulation.StorageOverride(_toBytes32("key2"), _toBytes32("newValue2"));

        vm.expectRevert(
            "StateOverrideManager: Duplicate keys in user-defined overrides for contract: 0x0000000000000000000000000000000000000123"
        );
        som.wrapperAppendUserDefinedOverrides(defaults, userOverride);
    }

    function testDecimalValuesInConfigForStateOverrideFails() public {
        string memory toml = string.concat(
            commonToml,
            "[stateOverrides]\n",
            "0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A = [\n",
            "    {key = 5, value = \"101\"}\n",
            "]"
        );
        string memory fileName = helper.createTempTomlFile(toml, TESTING_DIRECTORY, "012");
        MultisigTask task = new MockMultisigTask();
        vm.expectRevert(
            "StateOverrideManager: Failed to reencode overrides, ensure any decimal numbers are not in quotes"
        );
        task.simulate(fileName, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG));
        helper.removeFile(fileName);
    }

    function test_getStateOverrides_singleSafe() public {
        vm.createSelectFork("sepolia", 9181804);
        address rootSafe = address(0xd363339eE47775888Df411A163c586a8BdEA9dbf); // Unichain Sepolia ProxyAdminOwner
        MockStateOverrideManager som = new MockStateOverrideManager();
        Simulation.StateOverride[] memory allOverrides = som.wrapperGetStateOverrides(rootSafe, new address[](0));
        assertTrue(allOverrides.length == 1, "Expected 1 state override");
        assertEq(allOverrides[0].contractAddress, rootSafe, "Root safe address mismatch");
        assertEq(allOverrides[0].overrides.length, 4, "Expected 4 storage overrides");

        address rootSafeWithThresholdAlreadyOne = address(0xbefe941b3C4a6AaEe1eb050358064F0bA326975a); // Single Safe
        allOverrides = som.wrapperGetStateOverrides(rootSafeWithThresholdAlreadyOne, new address[](0));
        assertTrue(allOverrides.length == 1, "Expected 1 state override");
        assertEq(allOverrides[0].contractAddress, rootSafeWithThresholdAlreadyOne, "Root safe address mismatch");
        assertEq(allOverrides[0].overrides.length, 3, "Expected 3 storage overrides");
    }

    function test_getStateOverrides_oneLevelNesting() public {
        vm.createSelectFork("sepolia", 9181804);
        MockStateOverrideManager som = new MockStateOverrideManager();
        address baseRootSafe = address(0x0fe884546476dDd290eC46318785046ef68a0BA9); // Base Sepolia ProxyAdminOwner
        address[] memory childSafes = new address[](1);
        childSafes[0] = address(0x6AF0674791925f767060Dd52f7fB20984E8639d8); // Base Operations Safe
        Simulation.StateOverride[] memory allOverrides = som.wrapperGetStateOverrides(baseRootSafe, childSafes);
        assertTrue(allOverrides.length == 2, "Expected 2 state overrides");
        assertEq(allOverrides[0].contractAddress, baseRootSafe, "Root safe address mismatch");
        assertEq(allOverrides[0].overrides.length, 1, "Expected 1 storage overrides");
        assertEq(allOverrides[0].overrides[0].key, bytes32(uint256(0x4)), "Expected threshold override");

        assertEq(allOverrides[1].contractAddress, childSafes[0], "Child safe address mismatch");
        assertEq(allOverrides[1].overrides.length, 3, "Expected 3 storage overrides");
        // No threshold override added because it is already 1.
        assertEq(allOverrides[1].overrides[0].key, bytes32(uint256(0x3)), "Expected owner count override");
        bytes32 ownerMappingSlot = keccak256(abi.encode(uint256(1), uint256(2)));
        assertEq(allOverrides[1].overrides[1].key, ownerMappingSlot, "Expected owner mapping override");
        assertEq(
            allOverrides[1].overrides[1].value,
            bytes32(uint256(uint160(MULTICALL3_ADDRESS))),
            "Expected owner mapping override value"
        );
        assertEq(
            allOverrides[1].overrides[2].key,
            keccak256(abi.encode(MULTICALL3_ADDRESS, uint256(2))),
            "Expected owner mapping override"
        );
        assertEq(allOverrides[1].overrides[2].value, bytes32(uint256(0x1)), "Expected owner mapping override value");
    }

    function test_getStateOverrides_twoLevelNesting() public {
        vm.createSelectFork("sepolia", 9181763);
        MockStateOverrideManager som = new MockStateOverrideManager();
        address baseRootSafe = address(0x0fe884546476dDd290eC46318785046ef68a0BA9); // Base Sepolia ProxyAdminOwner
        address[] memory childSafes = new address[](2);
        childSafes[0] = address(0x6AF0674791925f767060Dd52f7fB20984E8639d8); // Base Operations Safe
        childSafes[1] = address(0x646132A1667ca7aD00d36616AFBA1A28116C770A); // Base SC Safe
        Simulation.StateOverride[] memory allOverrides = som.wrapperGetStateOverrides(baseRootSafe, childSafes);
        assertTrue(allOverrides.length == 3, "Expected 3 state overrides");
        assertEq(allOverrides[0].contractAddress, baseRootSafe, "Root safe address mismatch");
        assertEq(allOverrides[0].overrides.length, 1, "Expected 1 storage overrides");
        assertEq(allOverrides[0].overrides[0].key, bytes32(uint256(0x4)), "Expected threshold override");

        assertEq(allOverrides[1].contractAddress, childSafes[0], "Child safe address mismatch");
        assertEq(allOverrides[1].overrides.length, 3, "Expected 3 storage overrides");
        // No threshold override added because it is already 1.
        assertEq(allOverrides[1].overrides[0].key, bytes32(uint256(0x3)), "Expected owner count override");
        bytes32 ownerMappingSlot = keccak256(abi.encode(uint256(1), uint256(2)));
        assertEq(allOverrides[1].overrides[1].key, ownerMappingSlot, "Expected owner mapping override");
        assertEq(
            allOverrides[1].overrides[1].value,
            bytes32(uint256(uint160(MULTICALL3_ADDRESS))),
            "Expected owner mapping override value"
        );
        assertEq(
            allOverrides[1].overrides[2].key,
            keccak256(abi.encode(MULTICALL3_ADDRESS, uint256(2))),
            "Expected owner mapping override"
        );
        assertEq(allOverrides[1].overrides[2].value, bytes32(uint256(0x1)), "Expected owner mapping override value");

        assertEq(allOverrides[2].contractAddress, childSafes[1], "Child safe address mismatch");
        assertEq(allOverrides[2].overrides.length, 4, "Expected 4 storage overrides");
        assertEq(allOverrides[2].overrides[0].key, bytes32(uint256(0x4)), "Expected threshold override");
        assertEq(allOverrides[2].overrides[1].key, bytes32(uint256(0x3)), "Expected owner count override");
        bytes32 ownerMappingSlot2 = keccak256(abi.encode(uint256(1), uint256(2)));
        assertEq(allOverrides[2].overrides[2].key, ownerMappingSlot2, "Expected owner mapping override");
        assertEq(
            allOverrides[2].overrides[2].value,
            bytes32(uint256(uint160(MULTICALL3_ADDRESS))),
            "Expected owner mapping override value"
        );
        assertEq(
            allOverrides[2].overrides[3].key,
            keccak256(abi.encode(MULTICALL3_ADDRESS, uint256(2))),
            "Expected owner mapping override"
        );
        assertEq(allOverrides[2].overrides[3].value, bytes32(uint256(0x1)), "Expected owner mapping override value");
    }

    /// @notice Helper function to convert strings to bytes32
    function _toBytes32(string memory s) private pure returns (bytes32) {
        return bytes32(bytes(s));
    }

    /// @notice Helper function to create and run a task.
    function createAndRunTask(string memory fileName, address childMultisig)
        internal
        returns (MultisigTask task, address rootSafe)
    {
        task = new MockMultisigTask();
        (,,, rootSafe) = task.simulate(fileName, Solarray.addresses(childMultisig));
        return (task, rootSafe);
    }

    /// @notice Helper function to create storage overrides.
    function _createStorageOverrides(string memory key, string memory value)
        private
        pure
        returns (Simulation.StorageOverride[] memory)
    {
        Simulation.StorageOverride[] memory overrides = new Simulation.StorageOverride[](1);
        overrides[0] = Simulation.StorageOverride(bytes32(bytes(key)), bytes32(bytes(value)));
        return overrides;
    }

    function assertNonceIncremented(uint256 expectedNonce, address rootSafe) internal view {
        uint256 actualNonce = uint256(vm.load(rootSafe, bytes32(uint256(0x5))));
        assertEq(actualNonce, expectedNonce + 1, "Nonce must be incremented by 1 in memory after task is run");
    }

    /// @notice This function is used to assert the default state overrides for the parent multisig.
    /// Specifically, it verifies that the parent state overrides contain a threshold and nonce override.
    function assertDefaultStateOverrides(
        uint256 expectedTotalOverrides,
        MultisigTask task,
        address[] memory childSafes,
        address rootSafe
    ) internal view returns (Simulation.StateOverride[] memory allOverrides_) {
        bool isNested = childSafes.length > 0;

        allOverrides_ = task.getStateOverrides(rootSafe, childSafes);

        // Basic shape checks
        assertTrue(allOverrides_.length >= 1, "Must be at least 1 override (parent default)");
        assertEq(
            allOverrides_.length,
            expectedTotalOverrides,
            string.concat("Total number of overrides must be ", LibString.toString(expectedTotalOverrides))
        );

        // Parent assertions
        Simulation.StateOverride memory parent = allOverrides_[0];
        assertEq(parent.contractAddress, rootSafe, "Parent multisig address mismatch");

        uint256 parentLen = parent.overrides.length;
        if (isNested) {
            assertTrue(parentLen >= 1, string.concat("Parent overrides >= 1, found: ", LibString.toString(parentLen)));
        } else {
            assertTrue(parentLen == 4, string.concat("Parent overrides == 4, found: ", LibString.toString(parentLen)));
            // In single execution, the parent owner override should be address(this).
            assertOwnerOverrides(parent, address(this));
        }

        assertEq(parent.overrides[0].key, bytes32(uint256(0x4)), "Parent: threshold key");
        assertEq(parent.overrides[0].value, bytes32(uint256(0x1)), "Parent: threshold is 1");

        if (isNested) {
            for (uint256 i; i < childSafes.length; i++) {
                assertDefaultChildStateOverrides(allOverrides_, childSafes[i]);
            }
        }
    }

    /// @notice This function is used to assert the default state overrides for the child multisig.
    /// Specifically, it verifies that the child state overrides contain a threshold, nonce, owner count, and owner mapping overrides.
    function assertDefaultChildStateOverrides(Simulation.StateOverride[] memory allOverrides, address childMultisig)
        internal
        pure
    {
        assertTrue(
            allOverrides.length >= 2,
            "ChildDefaultOverride: Must be at least 2 overrides (parent default + child default)"
        );

        // Find the override entry for this child multisig
        Simulation.StateOverride memory childDefaultOverride;
        bool found;
        for (uint256 i; i < allOverrides.length; i++) {
            if (allOverrides[i].contractAddress == childMultisig) {
                childDefaultOverride = allOverrides[i];
                found = true;
                break;
            }
        }
        require(found, "ChildDefaultOverride: Child override not found");

        assertEq(
            childDefaultOverride.contractAddress,
            childMultisig,
            "ChildDefaultOverride: Contract address must be the child multisig"
        );
        assertTrue(
            childDefaultOverride.overrides.length == 4,
            string.concat(
                "ChildDefaultOverride: Default override must have 4 overrides, found: ",
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
        // MULTICALL3_ADDRESS should be the owner override for the child multisig in a nested execution.
        assertOwnerOverrides(childDefaultOverride, MULTICALL3_ADDRESS);
    }

    function assertOwnerOverrides(Simulation.StateOverride memory defaultOverride, address expectedOwnerOverride)
        private
        pure
    {
        assertEq(
            defaultOverride.overrides[1].key,
            bytes32(uint256(0x3)),
            "ChildDefaultOverride: Must contain an owner count override"
        );
        assertEq(
            defaultOverride.overrides[1].value,
            bytes32(uint256(0x1)),
            "ChildDefaultOverride: Owner count override must be 1"
        );

        // Verify owner mapping overrides
        // Calculate the storage slot for owner mapping: keccak256(abi.encode(1, 2))
        // where 1 is the owner index and 2 is the mapping slot in the contract
        bytes32 ownerMappingSlot = keccak256(abi.encode(uint256(1), uint256(2)));
        assertEq(
            defaultOverride.overrides[2].key,
            ownerMappingSlot,
            "Owner Override: Must contain first owner mapping override"
        );
        assertEq(
            defaultOverride.overrides[2].value,
            bytes32(uint256(uint160(expectedOwnerOverride))), // Necessary for exhaustive tenderly debug trace.
            "Owner Override: Incorrect first owner mapping override"
        );

        // Calculate the storage slot for owner mapping: keccak256(abi.encode(MULTICALL3_ADDRESS, 2))
        // where MULTICALL3_ADDRESS is the address of the Multicall3 contract and 2 is the mapping slot in the contract
        bytes32 ownerMappingSlot2 = keccak256(abi.encode(uint256(uint160(expectedOwnerOverride)), uint256(2)));
        assertEq(
            defaultOverride.overrides[3].key,
            ownerMappingSlot2,
            "Owner Override: Must contain second owner mapping override"
        );
        assertEq(
            defaultOverride.overrides[3].value,
            bytes32(uint256(0x1)),
            "Owner Override: Must contain second owner mapping override value"
        );
    }
}

/// The StateOverrideManager contract is an abstract contract so we need to inherit from it
/// to test it.
contract MockStateOverrideManager is StateOverrideManager {
    function wrapperGetStateOverrides(address rootSafe, address[] memory childSafes)
        public
        view
        returns (Simulation.StateOverride[] memory allOverrides_)
    {
        return super.getStateOverrides(rootSafe, childSafes);
    }

    function wrapperAppendUserDefinedOverrides(
        Simulation.StateOverride[] memory defaults,
        Simulation.StateOverride memory userOverride
    ) public pure returns (Simulation.StateOverride[] memory updatedOverrides) {
        return super._appendUserDefinedOverrides(defaults, userOverride);
    }
}
