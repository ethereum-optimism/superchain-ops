// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MockTarget} from "test/tasks/mock/MockTarget.sol";
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {MockMultisigTask} from "test/tasks/mock/MockMultisigTask.sol";

contract MultisigTaskUnitTest is Test {
    using stdStorage for StdStorage;

    SuperchainAddressRegistry public addrRegistry;
    MultisigTask public task;

    string constant MAINNET_CONFIG = "./test/tasks/mock/configs/OPMainnetGasConfigTemplate.toml";

    /// @notice variables that store the storage offset of different variables in the MultisigTask contract

    /// @notice storage slot for the address registry contract
    bytes32 public constant ADDRESS_REGISTRY_SLOT = bytes32(uint256(35));

    /// @notice storage slot for the parent multisig address
    bytes32 public constant MULTISIG_SLOT = bytes32(uint256(36));

    /// @notice storage slot for the mock target contract
    bytes32 public constant MOCK_TARGET_SLOT = bytes32(uint256(52));

    /// @notice storage slot for the build started flag
    bytes32 public constant BUILD_STARTED_SLOT = bytes32(uint256(49));

    /// @notice storage slot for the target multicall address
    bytes32 public constant TARGET_MULTICALL_SLOT = bytes32(uint256(50));

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

        // Instantiate the SuperchainAddressRegistry contract
        addrRegistry = new SuperchainAddressRegistry(MAINNET_CONFIG);

        // Instantiate the Mock MultisigTask contract
        task = MultisigTask(new MockMultisigTask());
    }

    function testRunFailsNoNetworks() public {
        vm.expectRevert("SuperchainAddressRegistry: no chains found");
        task.simulateRun("./test/tasks/mock/configs/InvalidNetworkConfig.toml");
    }

    function testRunFailsEmptyActions() public {
        MultisigTask.Action[] memory actions = new MultisigTask.Action[](0);
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
        MultisigTask.Action[] memory actions = createActions(address(1), "", 0, Enum.Operation.Call, "");
        vm.expectRevert("Duplicated action found");
        task.validateAction(actions[0].target, actions[0].value, actions[0].arguments, actions);
    }

    function testBuildFailsAddressRegistryNotSet() public {
        vm.expectRevert("Must set address registry for multisig address to be set");
        task.build();
    }

    function testBuildFailsAddressRegistrySetBuildStarted() public {
        // set multisig storage slot in MultisigTask.sol to a non zero address
        // we have to do this because we do not call the run function, which
        // sets the address registry contract variable to a new instance of the
        // address registry object.
        vm.store(
            address(task),
            MULTISIG_SLOT,
            bytes32(uint256(uint160(addrRegistry.getAddress("SystemConfigOwner", getChain("optimism").chainId))))
        );

        // set _buildStarted flag in MultisigTask contract to true, this
        // allows us to hit the revert in the build function of:
        //     "Build already started"
        vm.store(address(task), BUILD_STARTED_SLOT, bytes32(uint256(1)));

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
        vm.store(address(task), MULTISIG_SLOT, bytes32(uint256(uint160(multisig))));

        // set AddressRegistry in MultisigTask contract to a deployed address registry
        // contract so that these calls work
        vm.store(address(task), ADDRESS_REGISTRY_SLOT, bytes32(uint256(uint160(address(addrRegistry)))));

        // set the target multicall address in MultisigTask contract to the
        // multicall address
        vm.store(address(task), TARGET_MULTICALL_SLOT, bytes32(uint256(uint160(MULTICALL3_ADDRESS))));

        MockTarget mock = new MockTarget();
        bytes memory callData = abi.encodeWithSelector(MockTarget.foobar.selector);
        MultisigTask.Action[] memory actions = createActions(address(mock), callData, 0, Enum.Operation.Call, "");
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

    function runTestSimulation(string memory taskConfigFilePath)
        public
        returns (VmSafe.AccountAccess[] memory accountAccesses, MultisigTask.Action[] memory actions)
    {
        (accountAccesses, actions) = task.simulateRun(taskConfigFilePath);

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
        (VmSafe.AccountAccess[] memory accountAccesses, MultisigTask.Action[] memory actions) =
            runTestSimulation(MAINNET_CONFIG);

        vm.expectRevert("MultisigTask: execute failed");
        task.simulate("", actions);

        /// validations should pass after a successful run
        task.validate(accountAccesses, actions);
    }

    function testGetCalldata() public {
        (, MultisigTask.Action[] memory actions) = runTestSimulation(MAINNET_CONFIG);

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

    function createActions(
        address target,
        bytes memory data,
        uint256 value,
        Enum.Operation operation,
        string memory description
    ) internal pure returns (MultisigTask.Action[] memory actions) {
        actions = new MultisigTask.Action[](1);
        actions[0] = MultisigTask.Action({
            target: target,
            value: value,
            arguments: data,
            operation: operation,
            description: description
        });
        return actions;
    }
}
