// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IDisputeGameFactory} from "@eth-optimism-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Signatures} from "@base-contracts/script/universal/Signatures.sol";
import {GameTypes} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import {Test} from "forge-std/Test.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";
import {TestOPCMUpgradeVxyz} from "src/improvements/template/TestOPCMUpgradeVxyz.sol";
import {DisputeGameUpgradeTemplate} from "src/improvements/template/DisputeGameUpgradeTemplate.sol";

/// @notice This test is used to test the nested multisig task.
contract NestedMultisigTaskTest is Test {
    struct MultiSigOwner {
        address walletAddress;
        uint256 privateKey;
    }

    MultisigTask private multisigTask;
    AddressRegistry private addrRegistry;
    mapping(address => uint256) private privateKeyForOwner;

    /// @notice constants that describe the owner storage offsets in Gnosis Safe
    uint256 public constant OWNER_MAPPING_STORAGE_OFFSET = 2;
    uint256 public constant OWNER_COUNT_STORAGE_OFFSET = 3;
    uint256 public constant THRESHOLD_STORAGE_OFFSET = 4;

    /// ProxyAdminOwner safe for the task below is a nested multisig for Op mainnet L2 chain.
    string taskConfigFilePath = "test/tasks/mock/configs/NestedMultisigDisputeGameUpgradeTemplate.toml";

    function runTask() internal {
        multisigTask = new DisputeGameUpgradeTemplate();
        multisigTask.simulateRun(taskConfigFilePath);
        addrRegistry = multisigTask.addrRegistry();
    }

    function testSafeNested() public {
        vm.createSelectFork("mainnet");
        runTask();
        assertEq(multisigTask.isNestedSafe(), true, "Expected isNestedSafe to be false");
    }

    function testNestedDataToSignAndHashToApprove() public {
        vm.createSelectFork("mainnet");
        runTask();
        IGnosisSafe parentMultisig = IGnosisSafe(multisigTask.parentMultisig());
        address[] memory childOwnerMultisigs = parentMultisig.getOwners();

        // child multisigs have to approve the transaction that the parent multisig is going to execute.
        // hashToApproveByChildMultisig is the hash of the transaction that the parent multisig is going
        // to execute which the child multisigs have to approve.
        // nonce is decremented by 1 because when we ran the task, in simulation, execTransaction is called
        // which increments the nonce by 1 and we want to generate the hash by using the nonce before it was incremented.
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

        // callDataToApprove is the data that the child multisig has to execute to
        // approve the transaction that the parent multisig is going to execute.
        bytes memory callDataToApprove =
            abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
        assertEq(callDataToApprove, multisigTask.generateApproveMulticallData(), "Wrong callDataToApprove");
        for (uint256 i; i < childOwnerMultisigs.length; i++) {
            // dataToSign is the data that the EOA owners of the child multisig has to sign to help
            // execute the child multisig approval of hashToApproveByChildMultisig
            bytes memory dataToSign = getNestedDataToSign(childOwnerMultisigs[i]);
            // nonce is not decremented by 1 because in task simulation approveHash is called by
            // the child multisig which does not increment the nonce
            uint256 nonce = IGnosisSafe(childOwnerMultisigs[i]).nonce();
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
                _nonce: nonce
            });
            assertEq(dataToSign, expectedDataToSign, "Wrong data to sign");

            // nestedHashToApprove is the hash that the EOA owners of the child multisig has to approve to help
            // execute the child multisig approval of hashToApproveByChildMultisig
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
                nonce
            );
            assertEq(nestedHashToApprove, expectedNestedHashToApprove, "Wrong nested hash to approve");
        }
    }

    /// @notice test that the data to sign generated in simulateRun for the child multisigs
    /// is correct for MultisigTask
    function testNestedExecuteWithSignatures() public {
        vm.createSelectFork("mainnet");
        uint256 snapshotId = vm.snapshot();
        runTask();
        address multisig = multisigTask.parentMultisig();
        address[] memory parentMultisigOwners = IGnosisSafe(multisig).getOwners();
        bytes[] memory childMultisigDatasToSign = new bytes[](parentMultisigOwners.length);
        // store the data to sign for each child multisig
        for (uint256 i = 0; i < parentMultisigOwners.length; i++) {
            childMultisigDatasToSign[i] = getNestedDataToSign(parentMultisigOwners[i]);
        }
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(addrRegistry.getAddress("DisputeGameFactoryProxy", 10));
        // revert to snapshot so that the safe is in the same state as before the task was run
        vm.revertTo(snapshotId);

        MultiSigOwner[] memory newOwners = new MultiSigOwner[](9);
        (newOwners[0].walletAddress, newOwners[0].privateKey) = makeAddrAndKey("Owner0");
        (newOwners[1].walletAddress, newOwners[1].privateKey) = makeAddrAndKey("Owner1");
        (newOwners[2].walletAddress, newOwners[2].privateKey) = makeAddrAndKey("Owner2");
        (newOwners[3].walletAddress, newOwners[3].privateKey) = makeAddrAndKey("Owner3");
        (newOwners[4].walletAddress, newOwners[4].privateKey) = makeAddrAndKey("Owner4");
        (newOwners[5].walletAddress, newOwners[5].privateKey) = makeAddrAndKey("Owner5");
        (newOwners[6].walletAddress, newOwners[6].privateKey) = makeAddrAndKey("Owner6");
        (newOwners[7].walletAddress, newOwners[7].privateKey) = makeAddrAndKey("Owner7");
        (newOwners[8].walletAddress, newOwners[8].privateKey) = makeAddrAndKey("Owner8");

        for (uint256 i = 0; i < newOwners.length; i++) {
            privateKeyForOwner[newOwners[i].walletAddress] = newOwners[i].privateKey;
        }

        for (uint256 i = 0; i < parentMultisigOwners.length; i++) {
            address childMultisig = parentMultisigOwners[i];

            {
                // set the new owners for the child multisig
                address currentOwner = address(0x1);
                bytes32 slot;
                for (uint256 j = 0; j < newOwners.length; j++) {
                    slot = keccak256(abi.encode(currentOwner, OWNER_MAPPING_STORAGE_OFFSET));
                    vm.store(childMultisig, slot, bytes32(uint256(uint160(newOwners[j].walletAddress))));
                    currentOwner = newOwners[j].walletAddress;
                }

                // point the final owner back to the sentinel
                slot = keccak256(abi.encode(currentOwner, OWNER_MAPPING_STORAGE_OFFSET));
                vm.store(childMultisig, slot, bytes32(uint256(uint160(0x1))));
            }

            // set the owners count to 9
            vm.store(childMultisig, bytes32(OWNER_COUNT_STORAGE_OFFSET), bytes32(uint256(9)));

            // set the threshold to 4
            vm.store(childMultisig, bytes32(THRESHOLD_STORAGE_OFFSET), bytes32(uint256(4)));

            address[] memory getNewOwners = IGnosisSafe(childMultisig).getOwners();
            assertEq(getNewOwners.length, 9, "Expected 9 owners");
            for (uint256 j = 0; j < newOwners.length; j++) {
                // check that the new owners are set correctly
                assertEq(getNewOwners[j], newOwners[j].walletAddress, "Expected owner");
            }

            uint256 threshold = IGnosisSafe(childMultisig).getThreshold();
            assertEq(threshold, 4, "Expected threshold should be updated to mocked value");
            LibSort.sort(getNewOwners);

            // sign the approve hash call data to sign with the private keys of the new owners of the child multisig
            bytes memory packedSignaturesChild;
            for (uint256 j = 0; j < threshold; j++) {
                (uint8 v, bytes32 r, bytes32 s) =
                    vm.sign(privateKeyForOwner[getNewOwners[j]], keccak256(childMultisigDatasToSign[i]));
                packedSignaturesChild = bytes.concat(packedSignaturesChild, abi.encodePacked(r, s, v));
            }

            // execute the approve hash call with the signatures
            multisigTask = new DisputeGameUpgradeTemplate();
            multisigTask.approveFromChildMultisig(taskConfigFilePath, childMultisig, packedSignaturesChild);
        }

        /// execute the task
        multisigTask = new DisputeGameUpgradeTemplate();

        /// snapshot before running the task so we can roll back to this pre-state
        uint256 newSnapshot = vm.snapshot();

        multisigTask.simulateRun(taskConfigFilePath);

        // check that the implementation is upgraded correctly
        assertEq(
            address(disputeGameFactory.gameImpls(GameTypes.CANNON)),
            0xf691F8A6d908B58C534B624cF16495b491E633BA,
            "implementation not set"
        );

        bytes32 taskHash = multisigTask.getHash();

        /// now run the executeRun flow
        vm.revertTo(newSnapshot);
        multisigTask.executeRun(taskConfigFilePath, prepareSignatures(multisig, taskHash));
        addrRegistry = multisigTask.addrRegistry();

        // check that the implementation is upgraded correctly for a second time
        assertEq(
            address(disputeGameFactory.gameImpls(GameTypes.CANNON)),
            0xf691F8A6d908B58C534B624cF16495b491E633BA,
            "implementation not set"
        );
    }

    /// @notice test that the data to sign generated in simulateRun for the child multisigs
    /// is correct for OPCMBaseTask
    function testNestedExecuteWithSignaturesOPCM() public {
        vm.createSelectFork("sepolia");
        uint256 snapshotId = vm.snapshot();
        multisigTask = new TestOPCMUpgradeVxyz();
        string memory opcmTaskConfigFilePath = "test/tasks/mock/configs/TestOPCMUpgradeVxyz.toml";
        multisigTask.simulateRun(opcmTaskConfigFilePath);
        addrRegistry = multisigTask.addrRegistry();
        address multisig = multisigTask.parentMultisig();
        address[] memory parentMultisigOwners = IGnosisSafe(multisig).getOwners();
        bytes[] memory childMultisigDatasToSign = new bytes[](parentMultisigOwners.length);
        // store the data to sign for each child multisig
        for (uint256 i = 0; i < parentMultisigOwners.length; i++) {
            childMultisigDatasToSign[i] = getNestedDataToSign(parentMultisigOwners[i]);
        }
        // revert to snapshot so that the safe is in the same state as before the task was run
        vm.revertTo(snapshotId);

        MultiSigOwner[] memory newOwners = new MultiSigOwner[](9);
        (newOwners[0].walletAddress, newOwners[0].privateKey) = makeAddrAndKey("Owner0");
        (newOwners[1].walletAddress, newOwners[1].privateKey) = makeAddrAndKey("Owner1");
        (newOwners[2].walletAddress, newOwners[2].privateKey) = makeAddrAndKey("Owner2");
        (newOwners[3].walletAddress, newOwners[3].privateKey) = makeAddrAndKey("Owner3");
        (newOwners[4].walletAddress, newOwners[4].privateKey) = makeAddrAndKey("Owner4");
        (newOwners[5].walletAddress, newOwners[5].privateKey) = makeAddrAndKey("Owner5");
        (newOwners[6].walletAddress, newOwners[6].privateKey) = makeAddrAndKey("Owner6");
        (newOwners[7].walletAddress, newOwners[7].privateKey) = makeAddrAndKey("Owner7");
        (newOwners[8].walletAddress, newOwners[8].privateKey) = makeAddrAndKey("Owner8");

        for (uint256 i = 0; i < newOwners.length; i++) {
            privateKeyForOwner[newOwners[i].walletAddress] = newOwners[i].privateKey;
        }

        for (uint256 i = 0; i < parentMultisigOwners.length; i++) {
            address childMultisig = parentMultisigOwners[i];

            {
                // set the new owners for the child multisig
                address currentOwner = address(0x1);
                bytes32 slot;
                for (uint256 j = 0; j < newOwners.length; j++) {
                    slot = keccak256(abi.encode(currentOwner, OWNER_MAPPING_STORAGE_OFFSET));
                    vm.store(childMultisig, slot, bytes32(uint256(uint160(newOwners[j].walletAddress))));
                    currentOwner = newOwners[j].walletAddress;
                }

                // point the final owner back to the sentinel
                slot = keccak256(abi.encode(currentOwner, OWNER_MAPPING_STORAGE_OFFSET));
                vm.store(childMultisig, slot, bytes32(uint256(uint160(0x1))));
            }

            // set the owners count to 9
            vm.store(childMultisig, bytes32(OWNER_COUNT_STORAGE_OFFSET), bytes32(uint256(9)));

            // set the threshold to 4
            vm.store(childMultisig, bytes32(THRESHOLD_STORAGE_OFFSET), bytes32(uint256(4)));

            address[] memory getNewOwners = IGnosisSafe(childMultisig).getOwners();
            assertEq(getNewOwners.length, 9, "Expected 9 owners");
            for (uint256 j = 0; j < newOwners.length; j++) {
                // check that the new owners are set correctly
                assertEq(getNewOwners[j], newOwners[j].walletAddress, "Expected owner");
            }

            uint256 threshold = IGnosisSafe(childMultisig).getThreshold();
            assertEq(threshold, 4, "Expected threshold should be updated to mocked value");
            LibSort.sort(getNewOwners);

            // sign the approve hash call data to sign with the private keys of the new owners of the child multisig
            bytes memory packedSignaturesChild;
            for (uint256 j = 0; j < threshold; j++) {
                (uint8 v, bytes32 r, bytes32 s) =
                    vm.sign(privateKeyForOwner[getNewOwners[j]], keccak256(childMultisigDatasToSign[i]));
                packedSignaturesChild = bytes.concat(packedSignaturesChild, abi.encodePacked(r, s, v));
            }

            // execute the approve hash call with the signatures
            multisigTask = new TestOPCMUpgradeVxyz();
            multisigTask.approveFromChildMultisig(opcmTaskConfigFilePath, childMultisig, packedSignaturesChild);
        }

        // execute the task
        multisigTask = new TestOPCMUpgradeVxyz();

        /// snapshot before running the task so we can roll back to this pre-state
        uint256 newSnapshot = vm.snapshot();

        multisigTask.simulateRun(opcmTaskConfigFilePath);
        bytes32 taskHash = multisigTask.getHash();

        /// now run the executeRun flow
        vm.revertTo(newSnapshot);

        multisigTask.executeRun(opcmTaskConfigFilePath, prepareSignatures(multisig, taskHash));
    }

    function getNestedDataToSign(address owner) internal view returns (bytes memory) {
        bytes memory callData = multisigTask.generateApproveMulticallData();
        return multisigTask.getDataToSign(owner, callData);
    }

    function prepareSignatures(address _safe, bytes32 hash) internal view returns (bytes memory) {
        // prepend the prevalidated signatures to the signatures
        address[] memory approvers = Signatures.getApprovers(_safe, hash);
        return Signatures.genPrevalidatedSignatures(approvers);
    }
}
