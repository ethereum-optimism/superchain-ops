// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";
import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {DisputeGameUpgradeTemplate} from "src/fps/example/template/DisputeGameUpgradeTemplate.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {MULTICALL3_ADDRESS} from "src/fps/utils/Constants.sol";

contract NestedMultisigTaskTest is Test {
    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    MultisigTask private multisigTask;
    Addresses private addresses;
    string taskConfigFilePath = "src/fps/example/task-01/mainnetConfig.toml";

    function setUp() public {
        vm.createSelectFork("mainnet");
    }

    function runTask() public {
        multisigTask = new DisputeGameUpgradeTemplate();
        multisigTask.run(taskConfigFilePath);
    }

    function testSafeNested() public {
        runTask();
        assertEq(multisigTask.isNestedSafe(), true, "Expected isNestedSafe to be false");
    }

    function testNestedDataToSignAndHashToApprove() public {
        runTask();
        addresses = multisigTask.addresses();
        IGnosisSafe parentMultisig = IGnosisSafe(multisigTask.multisig());
        address[] memory childOwnerMultisigs = parentMultisig.getOwners();

        bytes32 hashToApproveByChildMultisig = parentMultisig.getTransactionHash(
            MULTICALL3_ADDRESS,
            0,
            multisigTask.getCalldata(),
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            address(0),
            parentMultisig.nonce() - 1
        );

        Call3Value memory call = Call3Value({
            target: address(parentMultisig),
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(parentMultisig.approveHash, (hashToApproveByChildMultisig))
        });

        Call3Value[] memory calls = new Call3Value[](1);
        calls[0] = call;

        bytes memory callDataToApprove =
            abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
        assertEq(callDataToApprove, multisigTask.generateApproveMulticallData(), "Wrong callDataToApprove");

        for (uint256 i; i < childOwnerMultisigs.length; i++) {
            bytes memory dataToSign = multisigTask.getNestedDataToSign(childOwnerMultisigs[i]);
            bytes memory expectedDataToSign = IGnosisSafe(childOwnerMultisigs[i]).encodeTransactionData({
                to: MULTICALL3_ADDRESS,
                value: 0,
                data: callDataToApprove,
                operation: Enum.Operation.DelegateCall,
                safeTxGas: 0,
                baseGas: 0,
                gasPrice: 0,
                gasToken: address(0),
                refundReceiver: address(0),
                _nonce: IGnosisSafe(childOwnerMultisigs[i]).nonce()
            });
            assertEq(dataToSign, expectedDataToSign, "Wrong data to sign");

            bytes32 nestedHashToApprove = multisigTask.getNestedHashToApprove(childOwnerMultisigs[i]);
            bytes32 expectedNestedHashToApprove = IGnosisSafe(childOwnerMultisigs[i]).getTransactionHash(
                MULTICALL3_ADDRESS,
                0,
                callDataToApprove,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                address(0),
                IGnosisSafe(childOwnerMultisigs[i]).nonce()
            );
            assertEq(nestedHashToApprove, expectedNestedHashToApprove, "Wrong nested hash to approve");
        }
    }
}
