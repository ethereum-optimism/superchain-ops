// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Test} from "forge-std/Test.sol";

import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MockTarget} from "test/mock/MockTarget.sol";
import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {AddressRegistry} from "src/fps/AddressRegistry.sol";
import {MockMultisigTask} from "test/mock/MockMultisigTask.sol";

contract MultisigTaskUnitTest is Test {
    AddressRegistry public addresses;
    MultisigTask public task;

    string constant MAINNET_CONFIG = "./src/fps/example/task-03/mainnetConfig.toml";

    function setUp() public {
        vm.createSelectFork("mainnet");

        // Instantiate the Addresses contract
        addresses = new AddressRegistry(MAINNET_CONFIG);

        // Instantiate the Mock MultisigTask contract
        task = MultisigTask(new MockMultisigTask());
    }

    function testRunFailsNoNetworks() public {
        vm.expectRevert("MultisigTask: no chains found");
        task.run("./test/mock/invalidNetworkConfig.toml");
    }

    function testRunFailsEmptyActions() public {
        /// add empty action that will cause a revert
        MockMultisigTask(address(task)).addAction(address(0), "", 0, "");
        vm.expectRevert("Invalid target for task");
        task.run(MAINNET_CONFIG);
    }

    function testRunFailsInvalidAction() public {
        /// add invalid args for action that will cause a revert
        MockMultisigTask(address(task)).addAction(address(1), "", 0, "");
        vm.expectRevert("Invalid arguments for task");
        task.run(MAINNET_CONFIG);
    }

    function testBuildFailsAddressesNotSet() public {
        vm.expectRevert("Must set addresses object for multisig address to be set");
        task.build();
    }

    function testBuildFailsAddressesSetBuildStarted() public {
        /// set multisig to a non zero address
        vm.store(
            address(task),
            bytes32(uint256(38)),
            bytes32(uint256(uint160(addresses.getAddress("SystemConfigOwner", getChain("optimism").chainId))))
        );
        /// set _buildStarted to true
        vm.store(address(task), bytes32(uint256(52)), bytes32(uint256(1)));

        task.addresses();

        vm.expectRevert("Build already started");
        task.build();
    }

    function testSimulateFailsHashMismatch() public {
        /// skip the run function call so we need to write to all storage variables manually

        address multisig = addresses.getAddress("SystemConfigOwner", getChain("optimism").chainId);
        /// set multisig to a non zero address
        vm.store(address(task), bytes32(uint256(38)), bytes32(uint256(uint160(multisig))));
        /// set addresses contract
        vm.store(address(task), bytes32(uint256(37)), bytes32(uint256(uint160(address(addresses)))));
        MockMultisigTask(address(task)).addAction(
            addresses.getAddress("ProxyAdmin", getChain("optimism").chainId),
            abi.encodeWithSignature(
                "upgrade(address,address)",
                addresses.getAddress("L1ERC721BridgeProxy", getChain("optimism").chainId),
                MockMultisigTask(address(task)).newImplementation()
            ),
            0,
            ""
        );

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
            /// return a hash that cannot possible be what is returned by the GnosisSafe
            abi.encode(bytes32(uint256(100)))
        );

        vm.expectRevert("MultisigTask: hash mismatch");
        task.simulate();
    }

    function testBuildFailsRevertPreviousSnapshotFails() public {
        address multisig = addresses.getAddress("ProxyAdminOwner", getChain("optimism").chainId);
        /// set multisig to a non zero address
        vm.store(address(task), bytes32(uint256(38)), bytes32(uint256(uint160(multisig))));
        /// set addresses contract
        vm.store(address(task), bytes32(uint256(37)), bytes32(uint256(uint160(address(addresses)))));

        MockTarget target = new MockTarget();
        target.setTask(address(task));

        /// set mock target contract in the task contract
        vm.store(address(task), bytes32(uint256(53)), bytes32(uint256(uint160(address(target)))));

        vm.expectRevert("failed to revert back to snapshot, unsafe state to run task");
        task.build();
    }

    function testRunFailsDuplicateAction() public {
        /// add duplicate action that will cause a revert
        MockMultisigTask(address(task)).addAction(
            addresses.getAddress("ProxyAdmin", getChain("optimism").chainId),
            abi.encodeWithSignature(
                "upgrade(address,address)",
                addresses.getAddress("L1ERC721BridgeProxy", getChain("optimism").chainId),
                MockMultisigTask(address(task)).newImplementation()
            ),
            0,
            ""
        );
        vm.expectRevert("Duplicated action found");
        task.run(MAINNET_CONFIG);
    }

    function testRun() public {
        vm.expectRevert("No actions found");
        task.getTaskActions();

        task.run(MAINNET_CONFIG);

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
}
