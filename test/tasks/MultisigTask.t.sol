// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Test} from "forge-std/Test.sol";

import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MockTarget} from "test/tasks/mock/MockTarget.sol";
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";
import {MockMultisigTask} from "test/tasks/mock/MockMultisigTask.sol";

contract MultisigTaskUnitTest is Test {
    AddressRegistry public addresses;
    MultisigTask public task;

    string constant MAINNET_CONFIG = "./test/tasks/mock/example/eth/task-03/config.toml";

    /// @notice variables that store the storage offset of different variables in the MultisigTask contract

    /// @notice storage slot for the addresses contract
    bytes32 public constant ADDRESSES_SLOT = bytes32(uint256(35));

    /// @notice storage slot for the multisig address
    bytes32 public constant MULTISIG_SLOT = bytes32(uint256(36));

    /// @notice storage slot for the addresses contract
    bytes32 public constant MOCK_TARGET_SLOT = bytes32(uint256(51));

    /// @notice storage slot for the build started flag
    bytes32 public constant BUILD_STARTED_SLOT = bytes32(uint256(50));

    /// Test Philosophy:
    /// We want these tests to function as much as possible as unit tests.
    /// In order to achieve this we have to put the contract in states that it
    /// would not normally be in. This is because the MultisigTask contract's
    /// main entrypoint is the run function, which sets the addresses contract
    /// and all other storage variables. We do not call this function in some of
    /// the tests, so we have to set the storage variables manually when we do
    /// not call the run function.

    function setUp() public {
        vm.createSelectFork("mainnet");

        // Instantiate the Addresses contract
        addresses = new AddressRegistry(MAINNET_CONFIG);

        // Instantiate the Mock MultisigTask contract
        task = MultisigTask(new MockMultisigTask());
    }

    function testRunFailsNoNetworks() public {
        vm.expectRevert("MultisigTask: no chains found");
        task.simulateRun("./test/tasks/mock/invalidNetworkConfig.toml");
    }

    function testRunFailsEmptyActions() public {
        /// add empty action that will cause a revert
        _addAction(address(0), "", 0, "");
        vm.expectRevert("Invalid target for task");
        task.simulateRun(MAINNET_CONFIG);
    }

    function testRunFailsInvalidAction() public {
        /// add invalid args for action that will cause a revert
        _addAction(address(1), "", 0, "");
        vm.expectRevert("Invalid arguments for task");
        task.simulateRun(MAINNET_CONFIG);
    }

    function testBuildFailsAddressesNotSet() public {
        vm.expectRevert("Must set addresses object for multisig address to be set");
        task.build();
    }

    function testBuildFailsAddressesSetBuildStarted() public {
        /// set multisig storage slot in MultisigTask.sol to a non zero address
        /// we have to do this because we do not call the run function, which
        /// sets the addresses contract variable to a new instance of the
        /// addresses object.
        vm.store(
            address(task),
            MULTISIG_SLOT,
            bytes32(uint256(uint160(addresses.getAddress("SystemConfigOwner", getChain("optimism").chainId))))
        );

        /// set _buildStarted flag in MultisigTask contract to true, this
        /// allows us to hit the revert in the build function of:
        ///     "Build already started"
        vm.store(address(task), BUILD_STARTED_SLOT, bytes32(uint256(1)));

        task.addresses();

        vm.expectRevert("Build already started");
        task.build();
    }

    function testSimulateFailsHashMismatch() public {
        /// skip the run function call so we need to write to all storage variables manually
        address multisig = addresses.getAddress("SystemConfigOwner", getChain("optimism").chainId);

        /// set multisig variable in MultisigTask to the actual multisig address
        /// so that the simulate function does not revert and can run and create
        /// calldata by calling the multisig functions
        vm.store(address(task), MULTISIG_SLOT, bytes32(uint256(uint160(multisig))));

        /// set addresses in MultisigTask contract to a deployed addresses
        /// contract so that these calls work
        vm.store(address(task), ADDRESSES_SLOT, bytes32(uint256(uint160(address(addresses)))));

        _addUpgradeAction();

        vm.mockCall(
            multisig,
            abi.encodeWithSelector(
                IGnosisSafe.getTransactionHash.selector,
                MULTICALL3_ADDRESS,
                0,
                task.getCalldata(),
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                task.nonce()
            ),
            /// return a hash that cannot possibly be what is returned by the GnosisSafe
            abi.encode(bytes32(uint256(100)))
        );

        vm.expectRevert("MultisigTask: hash mismatch");
        task.simulate();
    }

    function testBuildFailsRevertPreviousSnapshotFails() public {
        address multisig = addresses.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        /// set multisig variable in MultisigTask to the actual multisig address
        /// so that the simulate function does not revert and can run and create
        /// calldata by calling the multisig functions
        vm.store(address(task), MULTISIG_SLOT, bytes32(uint256(uint160(multisig))));

        /// set addresses in MultisigTask contract to a deployed addresses
        /// contract so that these calls work
        vm.store(address(task), ADDRESSES_SLOT, bytes32(uint256(uint160(address(addresses)))));

        MockTarget target = new MockTarget();
        target.setTask(address(task));

        /// set mock target contract in the task contract as there is no setter method,
        /// and we need to set the target contract to a deployed contract so that the
        /// build function will make this call, which will make the MultisigTask contract
        /// try to revert to a previous snapshot that does not exist. It does this by
        /// calling vm.store(task, _startSnapshot SLOT, some large number that isn't a valid snapshot id)
        vm.store(address(task), MOCK_TARGET_SLOT, bytes32(uint256(uint160(address(target)))));

        vm.expectRevert("failed to revert back to snapshot, unsafe state to run task");
        task.build();
    }

    function testRunFailsDuplicateAction() public {
        /// add duplicate action that will cause a revert
        _addUpgradeAction();
        vm.expectRevert("Duplicated action found");
        task.simulateRun(MAINNET_CONFIG);
    }

    function testRun() public {
        vm.expectRevert("No actions found");
        task.getTaskActions();

        task.simulateRun(MAINNET_CONFIG);

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = task.getTaskActions();

        // check that the task targets are correct
        assertEq(targets.length, 1, "Wrong targets length");
        assertEq(
            targets[0], addresses.getAddress("ProxyAdmin", getChain("optimism").chainId), "Wrong target at index 0"
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
                addresses.getAddress("L1ERC721BridgeProxy", getChain("optimism").chainId),
                MockMultisigTask(address(task)).newImplementation()
            ),
            "Wrong calldata at index 0"
        );
    }

    function testSimulateFailsTxAlreadyExecuted() public {
        testRun();

        vm.expectRevert("GS025");
        task.simulate();

        /// validations should pass after a successful run
        task.validate();
    }

    function testGetCalldata() public {
        testRun();

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = task.getTaskActions();

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

        bytes memory data = task.getCalldata();

        assertEq(data, expectedData, "Wrong aggregate calldata");
    }

    function _addAction(address target, bytes memory data, uint256 value, string memory description) internal {
        MockMultisigTask(address(task)).addAction(target, data, value, description);
    }

    function _addUpgradeAction() internal {
        _addAction(
            addresses.getAddress("ProxyAdmin", getChain("optimism").chainId),
            abi.encodeWithSignature(
                "upgrade(address,address)",
                addresses.getAddress("L1ERC721BridgeProxy", getChain("optimism").chainId),
                MockMultisigTask(address(task)).newImplementation()
            ),
            0,
            ""
        );
    }
}
