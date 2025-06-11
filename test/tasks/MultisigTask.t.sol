// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {Vm} from "forge-std/Vm.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MockMultisigTask} from "test/tasks/mock/MockMultisigTask.sol";
import {MockTarget} from "test/tasks/mock/MockTarget.sol";

contract MultisigTaskUnitTest is Test {
    using stdStorage for StdStorage;

    SuperchainAddressRegistry public addrRegistry;
    MultisigTask public task;

    string constant commonToml =
        "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n" "templateName = \"MockMultisigTask\"\n" "\n";
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
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(commonToml);
        // Instantiate the SuperchainAddressRegistry contract
        addrRegistry = new SuperchainAddressRegistry(fileName);
        MultisigTaskTestHelper.removeFile(fileName);

        // Instantiate the Mock MultisigTask contract
        task = MultisigTask(new MockMultisigTask());
    }

    function testRunFailsNoNetworks() public {
        vm.expectRevert("SuperchainAddressRegistry: no chains found");
        task.simulateRun("./test/tasks/mock/configs/InvalidNetworkConfig.toml");
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
        task.build();
    }

    function testBuildFailsAddressRegistrySetBuildStarted() public {
        // Set multisig storage slot in MultisigTask.sol to a non zero address
        // we have to do this because we do not call the run function, which
        // sets the address registry contract variable to a new instance of the
        // address registry object.
        stdstore.target(address(task)).sig("parentMultisig()").checked_write(
            addrRegistry.getAddress("SystemConfigOwner", getChain("optimism").chainId)
        );

        // Set 'buildStarted' flag in MultisigTask contract to true, this allows us to hit the revert.
        bytes32 buildStartedSlot = bytes32(uint256(stdstore.target(address(task)).sig("getBuildStarted()").find()));
        vm.store(address(task), buildStartedSlot, bytes32(uint256(1)));

        task.addrRegistry();

        vm.expectRevert("Build already started");
        task.build();
    }

    function testSimulateFailsHashMismatch() public {
        // skip the run function call so we need to write to all storage variables manually
        address multisig = addrRegistry.getAddress("SystemConfigOwner", getChain("optimism").chainId);

        // set multisig variable in MultisigTask to the actual multisig address
        // so that the simulate function does not revert and can run and create
        // calldata by calling the multisig functions
        stdstore.target(address(task)).sig("parentMultisig()").checked_write(multisig);

        // set AddressRegistry in MultisigTask contract to a deployed address registry
        // contract so that these calls work
        stdstore.target(address(task)).sig("addrRegistry()").checked_write(address(addrRegistry));

        // set the target multicall address in MultisigTask contract to the
        // multicall address
        stdstore.target(address(task)).sig("multicallTarget()").checked_write(MULTICALL3_ADDRESS);

        MockTarget mock = new MockTarget();
        bytes memory callData = abi.encodeWithSelector(MockTarget.foobar.selector);
        Action[] memory actions = createActions(address(mock), callData, 0, Enum.Operation.Call, "");
        vm.mockCall(
            multisig,
            abi.encodeWithSelector(
                IGnosisSafe.getTransactionHash.selector,
                MULTICALL3_ADDRESS,
                0,
                task.getMulticall3Calldata(actions),
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                task.nonce()
            ),
            // return a hash that cannot possibly be what is returned by the GnosisSafe
            abi.encode(bytes32(uint256(100)))
        );

        vm.expectRevert("MultisigTask: hash mismatch");
        task.simulate("", actions);
    }

    function testBuildFailsRevertPreviousSnapshotFails() public {
        address multisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        // Set parentMultisig variable in MultisigTask to the actual multisig address
        // so that the simulate function does not revert and can run and create
        // calldata by calling the multisig functions.
        stdstore.target(address(task)).sig("parentMultisig()").checked_write(multisig);

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
        task.build();
    }

    function runTestSimulation(string memory taskConfigFilePath, address childMultisig)
        public
        returns (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions)
    {
        (accountAccesses, actions,,) = task.signFromChildMultisig(taskConfigFilePath, childMultisig);

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
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(commonToml);
        (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions) =
            runTestSimulation(fileName, securityCouncilChildMultisig);
        MultisigTaskTestHelper.removeFile(fileName);

        vm.expectRevert("MultisigTask: execute failed");
        task.simulate("", actions);

        /// validations should pass after a successful run
        task.validate(accountAccesses, actions);
    }

    function testGetCalldata() public {
        string memory fileName = MultisigTaskTestHelper.createTempTomlFile(commonToml);
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

        bytes memory expectedData = abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);

        bytes memory data = task.getMulticall3Calldata(actions);

        assertEq(data, expectedData, "Wrong aggregate calldata");
    }

    function testFuzz_ValidActionConditions(bool isCall, address randomAccount) public {
        vm.assume(randomAccount != address(addrRegistry));
        vm.assume(randomAccount != VM_ADDRESS);
        uint256 topLevelDepth = 1;

        address parentMultisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        MockMultisigTask harness = new MockMultisigTask();
        stdstore.target(address(harness)).sig("parentMultisig()").checked_write(parentMultisig);
        stdstore.target(address(harness)).sig("addrRegistry()").checked_write(address(addrRegistry));

        VmSafe.AccountAccessKind kind = isCall ? VmSafe.AccountAccessKind.Call : VmSafe.AccountAccessKind.DelegateCall;

        VmSafe.AccountAccess memory access = createAccess(kind, randomAccount, parentMultisig, uint64(topLevelDepth));

        assertTrue(harness.wrapperIsValidAction(access, topLevelDepth));
    }

    function test_validAction_validCall() public {
        MockMultisigTask harness = new MockMultisigTask();
        address parentMultisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        stdstore.target(address(harness)).sig("parentMultisig()").checked_write(parentMultisig);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            address(0x5678), // Random account
            parentMultisig, // Valid accessor
            uint64(topLevelDepth)
        );
        assertTrue(harness.wrapperIsValidAction(access, topLevelDepth));
    }

    function test_validAction_validDelegateCall() public {
        MockMultisigTask harness = new MockMultisigTask();
        address parentMultisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        stdstore.target(address(harness)).sig("parentMultisig()").checked_write(parentMultisig);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.DelegateCall,
            address(0x5678), // Random account
            parentMultisig, // Valid accessor
            uint64(topLevelDepth)
        );
        assertTrue(harness.wrapperIsValidAction(access, topLevelDepth));
    }

    function test_invalidAction_accountIsRegistry() public {
        MockMultisigTask harness = new MockMultisigTask();
        address parentMultisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        address registryAddr = address(0xcafe1234);
        stdstore.target(address(harness)).sig("addrRegistry()").checked_write(address(registryAddr));
        stdstore.target(address(harness)).sig("parentMultisig()").checked_write(parentMultisig);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            registryAddr, // Invalid account
            parentMultisig,
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth));
    }

    function test_invalidAction_accountIsVm() public {
        MockMultisigTask harness = new MockMultisigTask();
        address parentMultisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        stdstore.target(address(harness)).sig("parentMultisig()").checked_write(parentMultisig);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            VM_ADDRESS, // Invalid account
            parentMultisig,
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth));
    }

    function test_invalidAction_accessorIsRegistry() public {
        MockMultisigTask harness = new MockMultisigTask();
        address parentMultisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        address registryAddr = address(0xcafe1234);
        stdstore.target(address(harness)).sig("addrRegistry()").checked_write(address(registryAddr));
        stdstore.target(address(harness)).sig("parentMultisig()").checked_write(parentMultisig);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            address(0x5678),
            registryAddr, // Invalid accessor
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth));
    }

    function test_invalidAction_wrongAccessor() public {
        MockMultisigTask harness = new MockMultisigTask();
        address parentMultisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        stdstore.target(address(harness)).sig("parentMultisig()").checked_write(parentMultisig);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            address(0x5678),
            address(0x9999), // Wrong accessor
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth));
    }

    function test_invalidAction_wrongDepth() public {
        MockMultisigTask harness = new MockMultisigTask();
        address parentMultisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        stdstore.target(address(harness)).sig("parentMultisig()").checked_write(parentMultisig);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.Call,
            address(0x5678),
            parentMultisig,
            uint64(topLevelDepth + 1) // Wrong depth
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth));
    }

    function test_invalidAction_wrongKind() public {
        MockMultisigTask harness = new MockMultisigTask();
        address parentMultisig = addrRegistry.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        stdstore.target(address(harness)).sig("parentMultisig()").checked_write(parentMultisig);
        uint256 topLevelDepth = 1;
        VmSafe.AccountAccess memory access = createAccess(
            VmSafe.AccountAccessKind.StaticCall, // Invalid kind
            address(0x5678),
            parentMultisig,
            uint64(topLevelDepth)
        );
        assertFalse(harness.wrapperIsValidAction(access, topLevelDepth));
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
}

library MultisigTaskTestHelper {
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    function createTempTomlFile(string memory tomlContent) internal returns (string memory) {
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
}
