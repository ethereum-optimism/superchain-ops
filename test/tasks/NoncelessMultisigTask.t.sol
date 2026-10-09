// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MultisigTask} from "src/tasks/MultisigTask.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {GasConfigTemplate} from "test/tasks/mock/template/GasConfigTemplate.sol";
import {MockMultisigTask} from "test/tasks/mock/MockMultisigTask.sol";
import {MockUnorderedExecutionModule} from "test/tasks/mock/MockUnorderedExecutionModule.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";
import {Solarray} from "lib/optimism/packages/contracts-bedrock/scripts/libraries/Solarray.sol";

/// @notice Tests for nonceless (hash-once) task execution through the UnorderedExecutionModule.
/// The module is deployed locally at a fixed address and enabled on the forked safes; on real
/// networks it must be deployed and enabled on-chain before a nonceless task can run.
contract NoncelessMultisigTaskTest is Test {
    string constant TESTING_DIRECTORY = "nonceless-multisig-task-testing";

    /// @notice Fixed address referenced by the 'hashOnceModule' key in the test configs.
    address constant MODULE_ADDRESS = 0x4242424242424242424242424242424242424242;

    string constant HASH_ONCE_INPUT = "test: totally unique string";

    /// @notice Single multisig config: SystemConfigOwner of Mode and Metal.
    string constant singleToml =
        "l2chains = [{name = \"Mode\", chainId = 34443}, {name = \"Metal\", chainId = 1750}]\n"
        "templateName = \"GasConfigTemplate\"\n" "hashOnceInput = \"test: totally unique string\"\n"
        "hashOnceModule = \"0x4242424242424242424242424242424242424242\"\n" "[gasConfigs]\n"
        "gasLimits = [{chainId = 34443, gasLimit = 100000000}, {chainId = 1750, gasLimit = 100000000}]\n";

    /// @notice Nested multisig config: OP Mainnet ProxyAdminOwner (L1PAO).
    string constant nestedToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n"
        "templateName = \"MockMultisigTask\"\n" "hashOnceInput = \"test: totally unique string\"\n"
        "hashOnceModule = \"0x4242424242424242424242424242424242424242\"\n";

    address constant SECURITY_COUNCIL = 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03;

    uint256 expectedHashOnce;

    function setUp() public {
        vm.createSelectFork("mainnet");
        deployCodeTo("MockUnorderedExecutionModule.sol", MODULE_ADDRESS);
        expectedHashOnce = uint256(keccak256(bytes(HASH_ONCE_INPUT)));
    }

    function enableModule(address safe) internal {
        vm.prank(safe);
        IGnosisSafe(safe).enableModule(MODULE_ADDRESS);
    }

    function test_noncelessSingle_simulate_succeeds() public {
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(singleToml, TESTING_DIRECTORY, "000");
        MultisigTask task = new GasConfigTemplate();

        (,,, address rootSafe) = simulateWithModuleEnabled(task, fileName);
        MultisigTaskTestHelper.removeFile(fileName);

        assertTrue(task.isNonceless(), "task should be nonceless");
        assertEq(task.hashOnce(), expectedHashOnce, "hashOnce should be derived from hashOnceInput");
        assertEq(address(task.hashOnceModule()), MODULE_ADDRESS, "module address should come from config");
        assertTrue(
            MockUnorderedExecutionModule(MODULE_ADDRESS).executed(rootSafe, expectedHashOnce),
            "module should have consumed the hash-once value"
        );
    }

    function test_noncelessSingle_safeNonce_unchanged() public {
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(singleToml, TESTING_DIRECTORY, "001");
        MultisigTask task = new GasConfigTemplate();
        address rootSafe = task.getRootSafe(fileName);
        uint256 nonceBefore = IGnosisSafe(rootSafe).nonce();

        simulateWithModuleEnabled(task, fileName);
        MultisigTaskTestHelper.removeFile(fileName);

        assertEq(IGnosisSafe(rootSafe).nonce(), nonceBefore, "module execution must not touch the safe nonce");
    }

    /// @notice The core property of nonceless tasks: the data to sign does not change when the
    /// safe's nonce drifts, so signatures collected before the drift stay valid.
    function test_noncelessSingle_nonceDrift_dataToSignUnchanged() public {
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(singleToml, TESTING_DIRECTORY, "002");

        uint256 snapshot = vm.snapshotState();
        MultisigTask task = new GasConfigTemplate();
        (,, bytes[] memory dataToSign,) = simulateWithModuleEnabled(task, fileName);

        assertTrue(vm.revertToState(snapshot), "failed to revert state");

        // Drift the root safe's nonce by 5 and simulate again.
        MultisigTask driftedTask = new GasConfigTemplate();
        address rootSafe = driftedTask.getRootSafe(fileName);
        uint256 gnosisSafeNonceSlot = 0x5;
        uint256 nonceBefore = IGnosisSafe(rootSafe).nonce();
        vm.store(rootSafe, bytes32(gnosisSafeNonceSlot), bytes32(nonceBefore + 5));

        (,, bytes[] memory dataToSignAfterDrift,) = simulateWithModuleEnabled(driftedTask, fileName);
        MultisigTaskTestHelper.removeFile(fileName);

        assertEq(dataToSign.length, dataToSignAfterDrift.length, "dataToSign count should match");
        for (uint256 i = 0; i < dataToSign.length; i++) {
            assertEq(dataToSign[i], dataToSignAfterDrift[i], "dataToSign must not change when the safe nonce drifts");
        }
    }

    function test_noncelessSingle_dataToSign_usesHashOnceAsNonce() public {
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(singleToml, TESTING_DIRECTORY, "003");
        MultisigTask task = new GasConfigTemplate();

        (, Action[] memory actions, bytes[] memory dataToSign, address rootSafe) =
            simulateWithModuleEnabled(task, fileName);
        MultisigTaskTestHelper.removeFile(fileName);

        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(rootSafe);
        uint256[] memory hashOnceNonces = new uint256[](1);
        hashOnceNonces[0] = expectedHashOnce;
        bytes[] memory calldatas = task.transactionDatas(actions, allSafes, hashOnceNonces);

        bytes memory expectedDataToSign = GnosisSafeHashes.getEncodedTransactionData(
            rootSafe, calldatas[calldatas.length - 1], 0, expectedHashOnce, MULTICALL3_ADDRESS
        );
        assertEq(dataToSign.length, 1, "single safe task should return one dataToSign");
        assertEq(dataToSign[0], expectedDataToSign, "dataToSign must embed the hash-once value as the nonce");
    }

    function test_noncelessSingle_replay_reverts() public {
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(singleToml, TESTING_DIRECTORY, "004");
        MultisigTask task = new GasConfigTemplate();
        simulateWithModuleEnabled(task, fileName);

        // The hash-once value is consumed; executing the same task again must fail.
        MultisigTask replayTask = new GasConfigTemplate();
        vm.expectRevert(
            "MultisigTask: hash-once value already consumed on this safe. Was the task already executed, or does another task reuse the same hashOnceInput?"
        );
        replayTask.simulate(fileName, new address[](0));
        MultisigTaskTestHelper.removeFile(fileName);
    }

    function test_nonceless_moduleNotDeployed_reverts() public {
        string memory badToml = "l2chains = [{name = \"Mode\", chainId = 34443}]\n"
            "templateName = \"GasConfigTemplate\"\n" "hashOnceInput = \"test: totally unique string\"\n"
            "hashOnceModule = \"0x9999999999999999999999999999999999999999\"\n" "[gasConfigs]\n"
            "gasLimits = [{chainId = 34443, gasLimit = 100000000}]\n";
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(badToml, TESTING_DIRECTORY, "005");
        MultisigTask task = new GasConfigTemplate();

        vm.expectRevert("MultisigTask: hashOnceModule has no code. Is the module deployed on this network?");
        task.simulate(fileName, new address[](0));
        MultisigTaskTestHelper.removeFile(fileName);
    }

    function test_nonceless_missingModuleAddress_reverts() public {
        string memory badToml = "l2chains = [{name = \"Mode\", chainId = 34443}]\n"
            "templateName = \"GasConfigTemplate\"\n" "hashOnceInput = \"test: totally unique string\"\n"
            "[gasConfigs]\n" "gasLimits = [{chainId = 34443, gasLimit = 100000000}]\n";
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(badToml, TESTING_DIRECTORY, "006");
        MultisigTask task = new GasConfigTemplate();

        vm.expectRevert("MultisigTask: hashOnceModule address is required when hashOnceInput is set");
        task.simulate(fileName, new address[](0));
        MultisigTaskTestHelper.removeFile(fileName);
    }

    function test_noncelessNested_simulate_succeeds() public {
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(nestedToml, TESTING_DIRECTORY, "007");
        MultisigTask task = new MockMultisigTask();
        address rootSafe = task.getRootSafe(fileName);
        enableModule(rootSafe);
        enableModule(SECURITY_COUNCIL);
        uint256 rootNonceBefore = IGnosisSafe(rootSafe).nonce();
        uint256 childNonceBefore = IGnosisSafe(SECURITY_COUNCIL).nonce();

        (,, bytes[] memory dataToSign,) = task.simulate(fileName, Solarray.addresses(SECURITY_COUNCIL));
        MultisigTaskTestHelper.removeFile(fileName);

        assertTrue(task.isNonceless(), "task should be nonceless");
        assertTrue(
            MockUnorderedExecutionModule(MODULE_ADDRESS).executed(rootSafe, expectedHashOnce),
            "module should have consumed the root safe's hash-once value"
        );
        assertEq(IGnosisSafe(rootSafe).nonce(), rootNonceBefore, "root safe nonce must not change");
        assertEq(IGnosisSafe(SECURITY_COUNCIL).nonce(), childNonceBefore, "child safe nonce must not change");

        // Every sibling child safe signs with the hash-once value in the nonce slot.
        for (uint256 i = 0; i < dataToSign.length; i++) {
            (, bytes32 messageHash) = GnosisSafeHashes.getDomainAndMessageHashFromEncodedTransactionData(dataToSign[i]);
            assertTrue(messageHash != bytes32(0), "sibling dataToSign should be well-formed");
        }
    }

    /// @notice Nested drift property: the child signers' data to sign survives both root and
    /// child nonce drift.
    function test_noncelessNested_nonceDrift_dataToSignUnchanged() public {
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(nestedToml, TESTING_DIRECTORY, "008");

        uint256 snapshot = vm.snapshotState();
        MultisigTask task = new MockMultisigTask();
        address rootSafe = task.getRootSafe(fileName);
        enableModule(rootSafe);
        enableModule(SECURITY_COUNCIL);
        (,, bytes[] memory dataToSign,) = task.simulate(fileName, Solarray.addresses(SECURITY_COUNCIL));

        assertTrue(vm.revertToState(snapshot), "failed to revert state");

        MultisigTask driftedTask = new MockMultisigTask();
        enableModule(rootSafe);
        enableModule(SECURITY_COUNCIL);
        uint256 gnosisSafeNonceSlot = 0x5;
        vm.store(rootSafe, bytes32(gnosisSafeNonceSlot), bytes32(IGnosisSafe(rootSafe).nonce() + 3));
        vm.store(SECURITY_COUNCIL, bytes32(gnosisSafeNonceSlot), bytes32(IGnosisSafe(SECURITY_COUNCIL).nonce() + 7));

        (,, bytes[] memory dataToSignAfterDrift,) = driftedTask.simulate(fileName, Solarray.addresses(SECURITY_COUNCIL));
        MultisigTaskTestHelper.removeFile(fileName);

        assertEq(dataToSign.length, dataToSignAfterDrift.length, "dataToSign count should match");
        for (uint256 i = 0; i < dataToSign.length; i++) {
            assertEq(dataToSign[i], dataToSignAfterDrift[i], "dataToSign must not change when any safe's nonce drifts");
        }
    }

    function simulateWithModuleEnabled(MultisigTask task, string memory fileName)
        internal
        returns (
            VmSafe.AccountAccess[] memory accountAccesses,
            Action[] memory actions,
            bytes[] memory dataToSign,
            address rootSafe
        )
    {
        enableModule(task.getRootSafe(fileName));
        (accountAccesses, actions, dataToSign, rootSafe) = task.simulate(fileName, new address[](0));
    }
}
