// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {Vm} from "forge-std/Vm.sol";
import {Solarray} from "lib/optimism/packages/contracts-bedrock/scripts/libraries/Solarray.sol";

import {MultisigTask} from "src/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action, TaskPayload} from "src/libraries/MultisigTypes.sol";
import {MockMultisigTask} from "test/tasks/mock/MockMultisigTask.sol";
import {MockTarget} from "test/tasks/mock/MockTarget.sol";

contract MultisigTaskUnitTest is Test {
    using stdStorage for StdStorage;

    SuperchainAddressRegistry public addrRegistry;
    MultisigTask public task;
    string constant TESTING_DIRECTORY = "multisig-task-testing";

    string constant commonToml =
        "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n" "templateName = \"MockMultisigTask\"\n" "\n";
    address root = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address securityCouncilChildMultisig = 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03;

    /// Test Philosophy:
    /// We want these tests to function as much as possible as unit tests.
    /// In order to achieve this we have to put the contract in states that it
    /// would not normally be in. This is because the MultisigTask contract's
    /// main entrypoint is the run function, which sets the addrRegistry contract
    /// and all other storage variables. We do not call this function in some of
    /// the tests, so we have to set the storage variables manually when we do
    /// not call the run function.

    function setUp() public {
        vm.createSelectFork("mainnet");

        // We want the SuperchainAddressRegistry to be initialized with the OP Mainnet config
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(commonToml, TESTING_DIRECTORY, "000");
        // Instantiate the SuperchainAddressRegistry contract
        addrRegistry = new SuperchainAddressRegistry(fileName);
        MultisigTaskTestHelper.removeFile(fileName);

        // Instantiate the Mock MultisigTask contract
        task = MultisigTask(new MockMultisigTask());
    }

    function testRunFailsEmptyActions() public {
        Action[] memory actions = new Action[](0);
        vm.expectRevert("No actions found");
        task.processTaskActions(actions);
    }

    function testRunFailsInvalidAction() public {
        vm.expectRevert("Invalid target for task");
        task.processTaskActions(createActions(address(0), "", 0, Enum.Operation.Call, ""));

        vm.expectRevert("Invalid arguments for task");
        task.processTaskActions(createActions(address(1), "", 0, Enum.Operation.Call, ""));
    }

    function testRunFailsDuplicateAction() public {
        Action[] memory actions = createActions(address(1), "", 0, Enum.Operation.Call, "");
        vm.expectRevert("Duplicated action found");
        task.validateAction(actions[0].target, actions[0].value, actions[0].arguments, actions);
    }

    function testBuildFailsAddressRegistryNotSet() public {
        vm.expectRevert("Must set address registry for multisig address to be set");
        task.build(address(0));
    }

    function testBuildFailsAddressRegistrySetBuildStarted() public {
        // Set 'buildStarted' flag in MultisigTask contract to true, this allows us to hit the revert.
        bytes32 buildStartedSlot = bytes32(uint256(stdstore.target(address(task)).sig("getBuildStarted()").find()));
        vm.store(address(task), buildStartedSlot, bytes32(uint256(1)));

        task.addrRegistry();

        vm.expectRevert("Build already started");
        task.build(root);
    }

    function testSimulateFailsHashMismatch() public {
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(commonToml, TESTING_DIRECTORY, "001");
        MultisigTask taskHashMismatch = MultisigTask(new MockMultisigTask());

        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        stdstore.target(address(taskHashMismatch)).sig("addrRegistry()").checked_write(address(addrRegistry));
        stdstore.target(address(taskHashMismatch)).sig("superchainAddrRegistry()").checked_write(address(addrRegistry));
        stdstore.target(address(taskHashMismatch)).sig("multicallTarget()").checked_write(MULTICALL3_ADDRESS);

        Action[] memory actions = taskHashMismatch.build(rootSafe);
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(rootSafe, securityCouncilChildMultisig);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);
        bytes[] memory allCalldatas = taskHashMismatch.transactionDatas(actions, allSafes, allOriginalNonces);
        bytes memory rootSafeCalldata = allCalldatas[allCalldatas.length - 1];
        uint256 rootSafeNonce = allOriginalNonces[allOriginalNonces.length - 1];
        {
            vm.mockCall(
                rootSafe,
                abi.encodeWithSelector(
                    IGnosisSafe.getTransactionHash.selector,
                    MULTICALL3_ADDRESS,
                    0,
                    rootSafeCalldata,
                    Enum.Operation.DelegateCall,
                    0,
                    0,
                    0,
                    address(0),
                    payable(address(0)),
                    rootSafeNonce
                ),
                // return a hash that cannot possibly be what is returned by the GnosisSafe
                abi.encode(bytes32(uint256(100)))
            );
        }
        // Unset buildStarted so that simulateAsSigner does not revert.
        stdstore.target(address(taskHashMismatch)).sig("getBuildStarted()").checked_write(uint256(0));

        vm.expectRevert("MultisigTask: hash mismatch");
        taskHashMismatch.simulate(fileName, Solarray.addresses(securityCouncilChildMultisig));
        MultisigTaskTestHelper.removeFile(fileName);
    }

    function testBuildFailsRevertPreviousSnapshotFails() public {
        // Set AddressRegistry in MultisigTask contract to a deployed addrRegistry contract
        // so that these calls work. These two getters are the same value, just different types.
        stdstore.target(address(task)).sig("addrRegistry()").checked_write(address(addrRegistry));
        stdstore.target(address(task)).sig("superchainAddrRegistry()").checked_write(address(addrRegistry));

        MockTarget target = new MockTarget();
        target.setTask(address(task));

        // Set mock target contract in the task contract as there is no setter method,
        // and we need to set the target contract to a deployed contract so that the
        // build function will make this call, which will make the MultisigTask contract
        // try to revert to a previous snapshot that does not exist. It does this by
        // calling vm.store(task, _startSnapshot SLOT, some large number that isn't a valid snapshot id).
        stdstore.target(address(task)).sig("mockTarget()").checked_write(address(target));

        vm.expectRevert("MultisigTask: failed to revert back to snapshot, unsafe state to run task");
        task.build(root);
    }

    function runTestSimulation(string memory taskConfigFilePath, address childMultisig)
        public
        returns (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions)
    {
        (accountAccesses, actions,,,) = task.simulate(taskConfigFilePath, Solarray.addresses(childMultisig));

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = task.processTaskActions(actions);

        // check that the task targets are correct
        assertEq(targets.length, 1, "Wrong targets length");
        assertEq(
            targets[0], addrRegistry.getAddress("ProxyAdmin", getChain("optimism").chainId), "Wrong target at index 0"
        );

        // check that the task values are correct
        assertEq(values.length, 1, "Wrong values length");
        assertEq(values[0], 0, "Wrong value at index 0");

        // check that the task calldatas are correct
        assertEq(calldatas.length, 1, "Wrong calldatas length");
        assertEq(
            calldatas[0],
            abi.encodeWithSignature(
                "upgrade(address,address)",
                addrRegistry.getAddress("L1ERC721BridgeProxy", getChain("optimism").chainId),
                MockMultisigTask(address(task)).newImplementation()
            ),
            "Wrong calldata at index 0"
        );
    }

    function testSimulateFailsTxAlreadyExecuted() public {
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(root, securityCouncilChildMultisig);
        uint256[] memory originalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);

        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(commonToml, TESTING_DIRECTORY, "002");
        (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions) =
            runTestSimulation(fileName, securityCouncilChildMultisig);
        bytes[] memory calldatas = task.transactionDatas(actions, allSafes, originalNonces);

        TaskPayload memory payload =
            TaskPayload({safes: allSafes, calldatas: calldatas, originalNonces: originalNonces});
        uint256 rootSafeIndex = payload.safes.length - 1;
        vm.expectRevert("MultisigTask: execute failed");
        task.executeTaskStep(new bytes(0), payload, rootSafeIndex);

        // Validations should pass after a successful run.
        task.validate(accountAccesses, actions, payload);
        MultisigTaskTestHelper.removeFile(fileName);
    }

    function testRootSafeGetCalldata() public {
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(root, securityCouncilChildMultisig);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(commonToml, TESTING_DIRECTORY, "003");
        (, Action[] memory actions) = runTestSimulation(fileName, securityCouncilChildMultisig);
        MultisigTaskTestHelper.removeFile(fileName);

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = task.processTaskActions(actions);
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](targets.length);
        for (uint256 i; i < calls.length; i++) {
            calls[i] = IMulticall3.Call3Value({
                target: targets[i],
                allowFailure: false,
                value: values[i],
                callData: calldatas[i]
            });
        }

        bytes memory expectedData = abi.encodeCall(IMulticall3.aggregate3Value, calls);
        bytes[] memory expectedCalldatas = task.transactionDatas(actions, allSafes, allOriginalNonces);
        bytes memory rootSafeCalldata = expectedCalldatas[expectedCalldatas.length - 1];
        assertEq(rootSafeCalldata, expectedData, "Wrong aggregate calldata");
    }

    function testFuzz_ValidActionConditions(bool isCall, address randomAccount) public {
        vm.assume(randomAccount != address(addrRegistry));
        vm.assume(randomAccount != VM_ADDRESS);
        uint256 topLevelDepth = 1;

        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        MockMultisigTask harness = new MockMultisigTask();
        // stdstore.target(address(harness)).sig("root()").checked_write(rootSafe);
        stdstore.target(address(harness)).sig("addrRegistry()").checked_write(address(addrRegistry));

        VmSafe.AccountAccessKind kind = isCall ? VmSafe.AccountAccessKind.Call : VmSafe.AccountAccessKind.DelegateCall;

        VmSafe.AccountAccess memory access = createAccess(kind, randomAccount, rootSafe, uint64(topLevelDepth));

        assertTrue(harness.wrapperIsValidAction(access, topLevelDepth, rootSafe));
    }

    function test_validAction_validCall() public {
        MockMultisigTask harness = new MockMultisigTask();
        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            address(0x5678), // Random account
            rootSafe, // Valid accessor
            uint64(topLevelDepth)
        );
        assertTrue(harness.wrapperIsValidAction(access, topLevelDepth, rootSafe));
    }

    function test_validAction_validDelegateCall() public {
        MockMultisigTask harness = new MockMultisigTask();
        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.DelegateCall,
            address(0x5678), // Random account
            rootSafe, // Valid accessor
            uint64(topLevelDepth)
        );
        assertTrue(harness.wrapperIsValidAction(access, topLevelDepth, rootSafe));
    }

    function test_invalidAction_accountIsRegistry() public {
        MockMultisigTask harness = new MockMultisigTask();
        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        address registryAddr = address(0xcafe1234);
        stdstore.target(address(harness)).sig("addrRegistry()").checked_write(address(registryAddr));
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            registryAddr, // Invalid account
            rootSafe,
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth, rootSafe));
    }

    function test_invalidAction_accountIsVm() public {
        MockMultisigTask harness = new MockMultisigTask();
        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            VM_ADDRESS, // Invalid account
            rootSafe,
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth, rootSafe));
    }

    function test_invalidAction_accessorIsRegistry() public {
        MockMultisigTask harness = new MockMultisigTask();
        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        address registryAddr = address(0xcafe1234);
        stdstore.target(address(harness)).sig("addrRegistry()").checked_write(address(registryAddr));
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            address(0x5678),
            registryAddr, // Invalid accessor
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth, rootSafe));
    }

    function test_invalidAction_wrongAccessor() public {
        MockMultisigTask harness = new MockMultisigTask();
        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            address(0x5678),
            address(0x9999), // Wrong accessor
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth, rootSafe));
    }

    function test_invalidAction_wrongDepth() public {
        MockMultisigTask harness = new MockMultisigTask();
        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            address(0x5678),
            rootSafe,
            uint64(topLevelDepth + 1) // Wrong depth
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth, rootSafe));
    }

    function test_invalidAction_wrongKind() public {
        MockMultisigTask harness = new MockMultisigTask();
        address rootSafe = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.StaticCall, // Invalid kind
            address(0x5678),
            rootSafe,
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth, rootSafe));
    }

    // Helper to create AccountAccess struct
    function createAccess(VmSafe.AccountAccessKind kind, address account, address accessor, uint64 depth)
        internal
        pure
        returns (VmSafe.AccountAccess memory)
    {
        return VmSafe.AccountAccess({
            chainInfo: VmSafe.ChainInfo({forkId: 0, chainId: 1}),
            kind: kind,
            account: account,
            accessor: accessor,
            initialized: false,
            oldBalance: 0,
            newBalance: 0,
            deployedCode: "",
            value: 0,
            data: "",
            reverted: false,
            storageAccesses: new VmSafe.StorageAccess[](0),
            depth: depth
        });
    }

    function createActions(
        address target,
        bytes memory data,
        uint256 value,
        Enum.Operation operation,
        string memory description
    ) internal pure returns (Action[] memory actions) {
        actions = new Action[](1);
        actions[0] =
            Action({target: target, value: value, arguments: data, operation: operation, description: description});
        return actions;
    }

    function testCalldatas_singleSafe() public view {
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(root);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);
        Action[] memory actions = createActions(address(0xbeef), hex"dead", 1 ether, Enum.Operation.Call, "Test Action");

        bytes[] memory result = task.transactionDatas(actions, allSafes, allOriginalNonces);
        assertEq(result.length, 1, "Incorrect calldata array length for single safe");
        assertRootCalldata(result[0], actions[0].target, actions[0].value, actions[0].arguments);
    }

    function testCalldatas_nestedSafes() public view {
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(root, securityCouncilChildMultisig);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);
        Action[] memory actions = createActions(address(0xbeef), hex"dead", 1 ether, Enum.Operation.Call, "Test Action");
        bytes[] memory result = task.transactionDatas(actions, allSafes, allOriginalNonces);
        assertEq(result.length, 2, "Incorrect calldata array length for nested safes");
        assertRootCalldata(result[result.length - 1], actions[0].target, actions[0].value, actions[0].arguments);
        // Generate the hash for the root safe that's used in the approveHash call on the nested safe.
        bytes32 hash =
            task.getHash(result[result.length - 1], root, 0, allOriginalNonces[allOriginalNonces.length - 1], allSafes);
        assertNestedCalldata(result[0], root, abi.encodeCall(IGnosisSafe(root).approveHash, (hash)));
    }

    /// @notice Asserts that the root safe calldata is correct.
    function assertRootCalldata(bytes memory data, address target, uint256 value, bytes memory callData)
        internal
        pure
    {
        bytes4 selector = bytes4(data);
        assertEq(selector, IMulticall3.aggregate3Value.selector, "Incorrect calldata for root safe");
        bytes memory params = getParams(data);
        (IMulticall3.Call3Value[] memory calls) = abi.decode(params, (IMulticall3.Call3Value[]));
        assertEq(calls.length, 1, "Incorrect number of calls for root safe");
        assertEq(calls[0].target, target, "Incorrect target for root safe");
        assertEq(calls[0].value, value, "Incorrect value for root safe");
        assertEq(calls[0].callData, callData, "Incorrect call data for root safe");
        assertEq(calls[0].allowFailure, false, "Incorrect allow failure for root safe");
    }

    /// @notice Asserts that the nested safe calldata is correct.
    function assertNestedCalldata(bytes memory data, address target, bytes memory callData) internal pure {
        bytes4 selector = bytes4(data);
        assertEq(selector, IMulticall3.aggregate3Value.selector, "Incorrect calldata for single safe");
        bytes memory params = getParams(data);
        (IMulticall3.Call3Value[] memory calls) = abi.decode(params, (IMulticall3.Call3Value[]));
        assertEq(calls.length, 1, "Incorrect number of calls for nested safes");
        assertEq(calls[0].target, target, "Incorrect target for nested safes");
        assertEq(calls[0].value, 0, "Incorrect value for nested safes");
        assertEq(calls[0].callData, callData, "Incorrect call data for nested safes");
        assertEq(calls[0].allowFailure, false, "Incorrect allow failure for nested safes");
    }

    /// @notice This function is used to get the params from the calldata.
    function getParams(bytes memory data) internal pure returns (bytes memory) {
        uint256 selectorLength = 4;
        bytes memory params = new bytes(data.length - selectorLength);
        for (uint256 j = 0; j < data.length - selectorLength; j++) {
            params[j] = data[j + selectorLength];
        }
        return params;
    }
}

library MultisigTaskTestHelper {
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    /// @notice This function is used to create a temporary toml file for a test. The 'salt' parameter is used to ensure
    /// that the file name is unique for each test.
    function createTempTomlFile(string memory tomlContent, string memory directory, string memory salt)
        internal
        returns (string memory)
    {
        string memory randomFileName = vm.toString(keccak256(abi.encodePacked(vm.randomBytes(32), salt)));
        string memory testConfigFilesDirectory = "test-config-files"; // This directory is in the .gitignore file.
        string memory fullDirectory = string.concat(testConfigFilesDirectory, "/", directory);
        vm.createDir(fullDirectory, true);
        string memory fileName = string.concat(fullDirectory, "/", randomFileName, ".toml");
        vm.writeFile(fileName, tomlContent);
        return fileName;
    }

    /// @notice This function is used to remove a file. The reason we use a try catch
    /// is because sometimes the file may not exist and this leads to flaky tests.
    function removeFile(string memory fileName) internal {
        try vm.removeFile(fileName) {} catch {}
    }

    /// @notice This function is used to decrement the nonce of an EOA or contract.
    /// It's specifically useful for decrementing the nonce of a child multisig after the simulation
    /// of a nested multisig task.
    function decrementNonceAfterSimulation(address owner) public {
        // Decrement the nonces by 1 because in task simulation child multisig nonces are incremented.
        if (address(owner).code.length > 0) {
            uint256 currentOwnerNonce = IGnosisSafe(owner).nonce();
            vm.store(owner, bytes32(uint256(0x5)), bytes32(uint256(--currentOwnerNonce)));
        } else {
            uint256 currentOwnerNonce = vm.getNonce(owner);
            vm.setNonce(owner, uint64(--currentOwnerNonce));
        }
    }

    /// @notice This function is used to get all the safes in the task for a single multisig task.
    function getAllSafes(address rootSafe) internal pure returns (address[] memory allSafes) {
        return Solarray.addresses(rootSafe);
    }

    /// @notice This function is used to get all the safes in the task for a nested multisig task.
    function getAllSafes(address rootSafe, address childSafeDepth1) internal pure returns (address[] memory allSafes) {
        return Solarray.addresses(childSafeDepth1, rootSafe);
    }

    /// @notice This function is used to get all the safes in the task for a nested-nested multisig task.
    function getAllSafes(address rootSafe, address childSafeDepth1, address childSafeDepth2)
        internal
        pure
        returns (address[] memory allSafes)
    {
        return Solarray.addresses(childSafeDepth2, childSafeDepth1, rootSafe);
    }

    /// @notice This function is used to get all the original nonces in the task.
    function getAllOriginalNonces(address[] memory safes) internal view returns (uint256[] memory allOriginalNonces) {
        allOriginalNonces = new uint256[](safes.length);
        for (uint256 i = 0; i < safes.length; i++) {
            allOriginalNonces[i] = IGnosisSafe(safes[i]).nonce();
        }
        return allOriginalNonces;
    }
}
