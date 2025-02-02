// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";
import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {GasConfigTemplate} from "src/fps/example/template/GasConfigTemplate.sol";
import {IncorrectGasConfigTemplate1} from "test/task/mock/IncorrectGasConfigTemplate1.sol";
import {IncorrectGasConfigTemplate2} from "test/task/mock/IncorrectGasConfigTemplate2.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

contract SingleMultisigTaskTest is Test {
    MultisigTask private multisigTask;
    Addresses private addresses;

    /// @notice ProxyAdminOwner safe for task-00 is a single multisig.
    string taskConfigFilePath = "src/fps/example/task-00/mainnetConfig.toml";

    function setUp() public {
        vm.createSelectFork("mainnet");
    }

    function runTask() public {
        multisigTask = new GasConfigTemplate();
        multisigTask.run(taskConfigFilePath);
    }

    function testTemplateSetup() public {
        runTask();
        assertEq(GasConfigTemplate(address(multisigTask)).gasLimits(291), 100000000, "Expected gas limit for 291");
        assertEq(GasConfigTemplate(address(multisigTask)).gasLimits(1750), 100000000, "Expected gas limit for 1750");
    }

    function testSafeSetup() public {
        runTask();
        addresses = multisigTask.addresses();
        assertEq(multisigTask.multisig(), addresses.getAddress("SystemConfigOwner", 291), "Wrong safe address string");
        assertEq(multisigTask.multisig(), addresses.getAddress("SystemConfigOwner", 1750), "Wrong safe address string");
        assertEq(multisigTask.isNestedSafe(), false, "Expected isNestedSafe to be false");
    }

    function testAllowedStorageWrites() public {
        runTask();
        addresses = multisigTask.addresses();
        address[] memory allowedStorageAccesses = multisigTask.getAllowedStorageAccess();
        assertEq(
            allowedStorageAccesses[0],
            addresses.getAddress("SystemConfigProxy", 291),
            "Wrong storage write access address"
        );
        assertEq(
            allowedStorageAccesses[1],
            addresses.getAddress("SystemConfigProxy", 1750),
            "Wrong storage write access address"
        );
    }

    function testBuild() public {
        MultisigTask localMultisigTask = new GasConfigTemplate();

        vm.expectRevert("No actions found");
        localMultisigTask.getTaskActions();

        localMultisigTask.run(taskConfigFilePath);

        addresses = localMultisigTask.addresses();

        (address[] memory targets, uint256[] memory values, bytes[] memory arguments) =
            localMultisigTask.getTaskActions();

        assertEq(targets.length, 2, "Expected 2 targets");
        assertEq(targets[0], addresses.getAddress("SystemConfigProxy", 291), "Expected SystemConfigProxy target");
        assertEq(targets[1], addresses.getAddress("SystemConfigProxy", 1750), "Expected SystemConfigProxy target");
        assertEq(values.length, 2, "Expected 2 values");
        assertEq(values[0], 0, "Expected 0 value");
        assertEq(values[1], 0, "Expected 0 value");
        assertEq(arguments.length, 2, "Expected 2 arguments");
        assertEq(arguments[0], abi.encodeWithSignature("setGasLimit(uint64)", uint64(100000000)), "Wrong calldata");
        assertEq(arguments[1], abi.encodeWithSignature("setGasLimit(uint64)", uint64(100000000)), "Wrong calldata");
    }

    function testGetCallData() public {
        runTask();

        (address[] memory targets, uint256[] memory values, bytes[] memory arguments) = multisigTask.getTaskActions();

        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](targets.length);

        for (uint256 i = 0; i < targets.length; i++) {
            calls[i] = IMulticall3.Call3Value({
                target: targets[i],
                allowFailure: false,
                value: values[i],
                callData: arguments[i]
            });
        }

        bytes memory expectedCallData =
            abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);

        bytes memory callData = multisigTask.getCalldata();
        assertEq(callData, expectedCallData, "Wrong calldata");
    }

    function testGetDataToSign() public {
        runTask();
        addresses = multisigTask.addresses();
        bytes memory callData = multisigTask.getCalldata();
        bytes memory dataToSign = multisigTask.getDataToSign(multisigTask.multisig(), callData);

        /// The nonce is decremented by 1 because we want to recreate the data to sign with the same nonce
        /// that was used in the simulation. The nonce was incremented as part of running the simulation.
        bytes memory expectedDataToSign = IGnosisSafe(multisigTask.multisig()).encodeTransactionData({
            to: MULTICALL3_ADDRESS,
            value: 0,
            data: callData,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: IGnosisSafe(multisigTask.multisig()).nonce() - 1
        });
        assertEq(dataToSign, expectedDataToSign, "Wrong data to sign");
    }

    function testHashToApprove() public {
        runTask();
        bytes memory callData = multisigTask.getCalldata();
        bytes32 hash = multisigTask.getHash();
        bytes32 expectedHash = IGnosisSafe(multisigTask.multisig()).getTransactionHash(
            MULTICALL3_ADDRESS,
            0,
            callData,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            address(0),
            IGnosisSafe(multisigTask.multisig()).nonce() - 1
        );
        assertEq(hash, expectedHash, "Wrong hash to approve");
    }

    function testRevertIfReInitialised() public {
        runTask();
        vm.expectRevert("MultisigTask: already initialized");
        multisigTask.run(taskConfigFilePath);
    }

    function testRevertIfUnsupportedChain() public {
        vm.chainId(10);
        MultisigTask localMultisigTask = new GasConfigTemplate();
        vm.expectRevert("Unsupported network");
        localMultisigTask.run(taskConfigFilePath);
    }

    function testRevertIfDifferentL2SafeAddresses() public {
        string memory incorrectTaskConfigFilePath = "test/task/mock/IncorrectMainnetConfig.toml";
        MultisigTask localMultisigTask = new GasConfigTemplate();
        Addresses addressRegistry = new Addresses(incorrectTaskConfigFilePath);
        bytes memory expectedRevertMessage = bytes(
            string.concat(
                "MultisigTask: safe address mismatch. Caller: ",
                localMultisigTask.getAddressLabel(addressRegistry.getAddress("SystemConfigOwner", 291)),
                ". Actual address: ",
                localMultisigTask.getAddressLabel(addressRegistry.getAddress("SystemConfigOwner", 10))
            )
        );
        vm.expectRevert(expectedRevertMessage);
        localMultisigTask.run(incorrectTaskConfigFilePath);
    }

    function testRevertIfIncorrectAllowedStorageWrite() public {
        MultisigTask localMultisigTask = new IncorrectGasConfigTemplate1();
        Addresses addressRegistry = new Addresses(taskConfigFilePath);
        bytes memory expectedRevertMessage = bytes(
            string.concat(
                "MultisigTask: address ",
                localMultisigTask.getAddressLabel(addressRegistry.getAddress("SystemConfigProxy", 291)),
                " not in allowed storage accesses"
            )
        );
        vm.expectRevert(expectedRevertMessage);
        localMultisigTask.run(taskConfigFilePath);
    }

    function testRevertIfAllowedStorageNotWritten() public {
        MultisigTask localMultisigTask = new IncorrectGasConfigTemplate2();
        Addresses addressRegistry = new Addresses(taskConfigFilePath);
        bytes memory expectedRevertMessage = bytes(
            string.concat(
                "MultisigTask: address ",
                localMultisigTask.getAddressLabel(addressRegistry.getAddress("SystemConfigOwner", 291)),
                " not in task state change addresses"
            )
        );
        vm.expectRevert(expectedRevertMessage);
        localMultisigTask.run(taskConfigFilePath);
    }
}
