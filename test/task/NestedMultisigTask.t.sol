// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Test} from "forge-std/Test.sol";

import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {DisputeGameUpgradeTemplate} from "src/fps/example/template/DisputeGameUpgradeTemplate.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

/// @notice This test is used to test the nested multisig task.
contract NestedMultisigTaskTest is Test {
    MultisigTask private multisigTask;
    Addresses private addresses;
    /// ProxyAdminOwner safe for task-01 is a nested multisig for Op mainnet L2 chain.
    string taskConfigFilePath = "src/fps/example/task-01/mainnetConfig.toml";

    function setUp() public {
        vm.createSelectFork("mainnet");
        multisigTask = new DisputeGameUpgradeTemplate();
        multisigTask.run(taskConfigFilePath);
        addresses = multisigTask.addresses();
    }

    function testSafeNested() public view {
        assertEq(multisigTask.isNestedSafe(), true, "Expected isNestedSafe to be false");
    }

    function testNestedDataToSignAndHashToApprove() public view {
        IGnosisSafe parentMultisig = IGnosisSafe(multisigTask.multisig());
        address[] memory childOwnerMultisigs = parentMultisig.getOwners();

        /// child multisigs have to approve the transaction that the parent multisig is going to execute.
        /// hashToApproveByChildMultisig is the hash of the transaction that the parent multisig is going
        /// to execute which the child multisigs have to approve.
        /// nonce is decremented by 1 because when we ran the task, in simulation, execTransaction is called
        /// which increments the nonce by 1 and we want to generate the hash by using the nonce before it was incremented.
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

        IMulticall3.Call3Value memory call = IMulticall3.Call3Value({
            target: address(parentMultisig),
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(parentMultisig.approveHash, (hashToApproveByChildMultisig))
        });

        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);
        calls[0] = call;

        /// callDataToApprove is the data that the child multisig has to execute to
        /// approve the transaction that the parent multisig is going to execute.
        bytes memory callDataToApprove =
            abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
        assertEq(callDataToApprove, multisigTask.generateApproveMulticallData(), "Wrong callDataToApprove");
        for (uint256 i; i < childOwnerMultisigs.length; i++) {
            /// dataToSign is the data that the EOA owners of the child multisig has to sign to help
            /// execute the child multisig approval of hashToApproveByChildMultisig
            bytes memory dataToSign = getNestedDataToSign(childOwnerMultisigs[i]);
            /// nonce is not decremented by 1 because in task simulation approveHash is called by
            /// the child multisig which does not increment the nonce
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

            /// nestedHashToApprove is the hash that the EOA owners of the child multisig has to approve to help
            /// execute the child multisig approval of hashToApproveByChildMultisig
            bytes32 nestedHashToApprove = keccak256(dataToSign);
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

    function getNestedDataToSign(address owner) public view returns (bytes memory) {
        bytes memory callData = multisigTask.generateApproveMulticallData();
        return multisigTask.getDataToSign(owner, callData);
    }
}
