// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IDisputeGameFactory} from "@eth-optimism-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Signatures} from "@base-contracts/script/universal/Signatures.sol";
import {GameTypes} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {MultisigTask, AddressRegistry} from "src/improvements/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {DisputeGameUpgradeTemplate} from "test/tasks/mock/template/DisputeGameUpgradeTemplate.sol";
import {OPCMUpgradeV200} from "src/improvements/template/OPCMUpgradeV200.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MockDisputeGameTask} from "test/tasks/mock/MockDisputeGameTask.sol";
import {DisputeGameUpgradeTemplate} from "test/tasks/mock/template/DisputeGameUpgradeTemplate.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";

/// @notice This test is used to test the nested multisig task.
contract NestedMultisigTaskTest is Test {
    struct MultiSigOwner {
        address walletAddress;
        uint256 privateKey;
    }

    MultisigTask private multisigTask;
    AddressRegistry private addrRegistry;
    SuperchainAddressRegistry private superchainAddrRegistry;
    mapping(address => uint256) private privateKeyForOwner;

    /// @notice constants that describe the owner storage offsets in Gnosis Safe
    uint256 public constant OWNER_MAPPING_STORAGE_OFFSET = 2;
    uint256 public constant OWNER_COUNT_STORAGE_OFFSET = 3;
    uint256 public constant THRESHOLD_STORAGE_OFFSET = 4;

    /// @notice ProxyAdminOwner safe for the task below is a nested multisig for Op mainnet L2 chain.
    string constant taskConfigToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
        "templateName = \"DisputeGameUpgradeTemplate\"\n" "\n"
        "implementations = [{gameType = 0, implementation = \"0xf691F8A6d908B58C534B624cF16495b491E633BA\", l2ChainId = 10}]\n";
    address constant SECURITY_COUNCIL_CHILD_MULTISIG = 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03;

    function runTask(address childMultisig)
        internal
        returns (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions)
    {
        multisigTask = new DisputeGameUpgradeTemplate();
        string memory configFilePath = MultisigTaskTestHelper.createTempTomlFile(taskConfigToml);
        (accountAccesses, actions,,) = multisigTask.signFromChildMultisig(configFilePath, childMultisig);
        MultisigTaskTestHelper.removeFile(configFilePath);
        addrRegistry = multisigTask.addrRegistry();
        superchainAddrRegistry = SuperchainAddressRegistry(AddressRegistry.unwrap(addrRegistry));
    }

    function testSafeNested() public {
        vm.createSelectFork("mainnet");
        runTask(SECURITY_COUNCIL_CHILD_MULTISIG);
        assertEq(multisigTask.isNestedSafe(multisigTask.parentMultisig()), true, "Expected isNestedSafe to be true");
    }

    function testNestedDataToSignAndHashToApprove() public {
        vm.createSelectFork("mainnet");
        (, Action[] memory actions) = runTask(SECURITY_COUNCIL_CHILD_MULTISIG);
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
            multisigTask.getMulticall3Calldata(actions),
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
        assertEq(callDataToApprove, multisigTask.generateApproveMulticallData(actions), "Wrong callDataToApprove");
        for (uint256 i; i < childOwnerMultisigs.length; i++) {
            // dataToSign is the data that the EOA owners of the child multisig has to sign to help
            // execute the child multisig approval of hashToApproveByChildMultisig
            bytes memory dataToSign = getNestedDataToSign(childOwnerMultisigs[i], actions);
            // Nonce is not decremented by 1 because decrementNonceHelper is called in getNestedDataToSign.
            uint256 nonce = (IGnosisSafe(childOwnerMultisigs[i]).nonce());

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

    /// @notice Test that the data to sign generated in signFromChildMultisig for the child multisigs
    /// is correct for MultisigTask
    function testNestedExecuteWithSignatures() public {
        vm.createSelectFork("mainnet");
        uint256 snapshotId = vm.snapshotState();
        (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions) =
            runTask(SECURITY_COUNCIL_CHILD_MULTISIG);
        address parentMultisig = multisigTask.parentMultisig();
        address[] memory parentMultisigOwners = IGnosisSafe(parentMultisig).getOwners();
        bytes[] memory childMultisigDatasToSign = new bytes[](parentMultisigOwners.length);

        // store the data to sign for each child multisig
        for (uint256 i = 0; i < parentMultisigOwners.length; i++) {
            childMultisigDatasToSign[i] = getNestedDataToSign(parentMultisigOwners[i], actions);
        }
        IDisputeGameFactory disputeGameFactory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", 10));

        // revert to snapshot so that the safe is in the same state as before the task was run
        vm.revertToState(snapshotId);

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
            string memory configFilePath = MultisigTaskTestHelper.createTempTomlFile(taskConfigToml);
            multisigTask.approveFromChildMultisig(configFilePath, childMultisig, packedSignaturesChild);
            MultisigTaskTestHelper.removeFile(configFilePath);
        }

        // execute the task
        multisigTask = new DisputeGameUpgradeTemplate();

        /// snapshot before running the task so we can roll back to this pre-state
        uint256 newSnapshot = vm.snapshotState();

        string memory config = MultisigTaskTestHelper.createTempTomlFile(taskConfigToml);
        (accountAccesses, actions,,) = multisigTask.signFromChildMultisig(config, SECURITY_COUNCIL_CHILD_MULTISIG);
        MultisigTaskTestHelper.removeFile(config);

        // Check that the implementation is upgraded correctly
        assertEq(
            address(disputeGameFactory.gameImpls(GameTypes.CANNON)),
            0xf691F8A6d908B58C534B624cF16495b491E633BA,
            "implementation not set"
        );

        bytes memory callData = multisigTask.getMulticall3Calldata(actions);
        bytes32 taskHash = multisigTask.getHash(callData, parentMultisig);

        /// Now run the executeRun flow
        vm.revertToState(newSnapshot);
        string memory taskConfigFilePath = MultisigTaskTestHelper.createTempTomlFile(taskConfigToml);
        multisigTask.executeRun(taskConfigFilePath, prepareSignatures(parentMultisig, taskHash));
        MultisigTaskTestHelper.removeFile(taskConfigFilePath);
        addrRegistry = multisigTask.addrRegistry();

        // Check that the implementation is upgraded correctly for a second time
        assertEq(
            address(disputeGameFactory.gameImpls(GameTypes.CANNON)),
            0xf691F8A6d908B58C534B624cF16495b491E633BA,
            "implementation not set"
        );
    }

    /// @notice Test that the 'data to sign' generated in simulateRun for the child multisigs
    /// is correct for OPCMTaskBase. This test uses the OPCMUpgradeV200 template as a way to test OPCMTaskBase.
    function testNestedExecuteWithSignaturesOPCM() public {
        address foundationChildMultisig = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B;
        // In block 7972617, an upgrade occurred at: https://sepolia.etherscan.io/tx/0x12b76ef5c31145a3bf6bb71b9c3c7ddd3cd7f182011187353e3ceb1830891fb7
        // Which meant this test failed. We're forking at the block before to continue to test this.
        vm.createSelectFork("sepolia", 7972616);
        uint256 snapshotId = vm.snapshotState();
        multisigTask = new OPCMUpgradeV200();
        string memory opcmTaskConfigFilePath = "test/tasks/example/sep/002-opcm-upgrade-v200/config.toml";
        (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions,,) =
            multisigTask.signFromChildMultisig(opcmTaskConfigFilePath, foundationChildMultisig);

        addrRegistry = multisigTask.addrRegistry();
        address parentMultisig = multisigTask.parentMultisig();
        address[] memory parentMultisigOwners = IGnosisSafe(parentMultisig).getOwners();
        bytes[] memory childMultisigDatasToSign = new bytes[](parentMultisigOwners.length);
        // Store the data to sign for each child multisig
        for (uint256 i = 0; i < parentMultisigOwners.length; i++) {
            childMultisigDatasToSign[i] = getNestedDataToSign(parentMultisigOwners[i], actions);
        }
        // Revert to snapshot so that the safe is in the same state as before the task was run
        vm.revertToState(snapshotId);

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
                // Set the new owners for the child multisig
                address currentOwner = address(0x1);
                bytes32 slot;
                for (uint256 j = 0; j < newOwners.length; j++) {
                    slot = keccak256(abi.encode(currentOwner, OWNER_MAPPING_STORAGE_OFFSET));
                    vm.store(childMultisig, slot, bytes32(uint256(uint160(newOwners[j].walletAddress))));
                    currentOwner = newOwners[j].walletAddress;
                }

                // Point the final owner back to the sentinel
                slot = keccak256(abi.encode(currentOwner, OWNER_MAPPING_STORAGE_OFFSET));
                vm.store(childMultisig, slot, bytes32(uint256(uint160(0x1))));
            }

            // Set the owners count to 9
            vm.store(childMultisig, bytes32(OWNER_COUNT_STORAGE_OFFSET), bytes32(uint256(9)));

            // Set the threshold to 4
            vm.store(childMultisig, bytes32(THRESHOLD_STORAGE_OFFSET), bytes32(uint256(4)));

            address[] memory getNewOwners = IGnosisSafe(childMultisig).getOwners();
            assertEq(getNewOwners.length, 9, "Expected 9 owners");
            for (uint256 j = 0; j < newOwners.length; j++) {
                assertEq(getNewOwners[j], newOwners[j].walletAddress, "Expected owner");
            }

            uint256 threshold = IGnosisSafe(childMultisig).getThreshold();
            assertEq(threshold, 4, "Expected threshold should be updated to mocked value");
            LibSort.sort(getNewOwners);

            // Sign the approve hash call data to sign with the private keys of the new owners of the child multisig
            bytes memory packedSignaturesChild;
            for (uint256 j = 0; j < threshold; j++) {
                (uint8 v, bytes32 r, bytes32 s) =
                    vm.sign(privateKeyForOwner[getNewOwners[j]], keccak256(childMultisigDatasToSign[i]));
                packedSignaturesChild = bytes.concat(packedSignaturesChild, abi.encodePacked(r, s, v));
            }

            // Execute the approve hash call with the signatures
            multisigTask = new OPCMUpgradeV200();
            multisigTask.approveFromChildMultisig(opcmTaskConfigFilePath, childMultisig, packedSignaturesChild);
        }

        // Execute the task
        multisigTask = new OPCMUpgradeV200();

        // Snapshot before running the task so we can roll back to this pre-state
        uint256 newSnapshot = vm.snapshotState();

        (accountAccesses, actions,,) =
            multisigTask.signFromChildMultisig(opcmTaskConfigFilePath, foundationChildMultisig);
        bytes32 taskHash =
            multisigTask.getHash(multisigTask.getMulticall3Calldata(actions), multisigTask.parentMultisig());

        vm.revertToState(newSnapshot);
        multisigTask.executeRun(opcmTaskConfigFilePath, prepareSignatures(parentMultisig, taskHash));
    }

    function testMockDisputeGameWithCodeExceptionsWorks() public {
        vm.createSelectFork("mainnet");
        string memory configFilePath = "test/tasks/mock/configs/MockDisputeGameUpgradesToEOA.toml";
        multisigTask = new MockDisputeGameTask();
        multisigTask.signFromChildMultisig(configFilePath, SECURITY_COUNCIL_CHILD_MULTISIG);
        assertEq(multisigTask.isNestedSafe(multisigTask.parentMultisig()), true, "Expected isNestedSafe to be true");
    }

    function testSimulateRunDisputeGameWithoutCodeExceptionsFails() public {
        vm.createSelectFork("mainnet");
        string memory configFilePath = "test/tasks/mock/configs/MockDisputeGameUpgradesToEOA.toml";
        multisigTask = new DisputeGameUpgradeTemplate();

        uint256 start = vm.snapshotState();

        multisigTask.signFromChildMultisig(
            "test/tasks/mock/configs/DisputeGameUpgradeCodeException.toml", SECURITY_COUNCIL_CHILD_MULTISIG
        );
        addrRegistry = multisigTask.addrRegistry();
        SuperchainAddressRegistry superchainAddrReg = SuperchainAddressRegistry(AddressRegistry.unwrap(addrRegistry));
        address account = superchainAddrReg.getAddress("DisputeGameFactoryProxy", getChain("optimism").chainId);

        vm.revertToState(start);

        string memory err = string.concat(
            "Likely address in storage has no code\n",
            "  account: ",
            vm.toString(account),
            "\n  slot:    ",
            vm.toString(bytes32(0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b)),
            "\n  value:   ",
            vm.toString(bytes32(0x0000000000000000000000000000000fffffffffffffffffffffffffffffffff))
        );
        vm.expectRevert(bytes(err));
        multisigTask.signFromChildMultisig(configFilePath, SECURITY_COUNCIL_CHILD_MULTISIG);
    }

    function getNestedDataToSign(address owner, Action[] memory actions) internal returns (bytes memory) {
        // Decrement the nonces by 1 because in task simulation child multisig nonces are incremented.
        MultisigTaskTestHelper.decrementNonceAfterSimulation(owner);
        bytes memory callData = multisigTask.generateApproveMulticallData(actions);
        return multisigTask.getEncodedTransactionData(owner, callData);
    }

    function prepareSignatures(address _safe, bytes32 hash) internal view returns (bytes memory) {
        // prepend the prevalidated signatures to the signatures
        address[] memory approvers = Signatures.getApprovers(_safe, hash);
        return Signatures.genPrevalidatedSignatures(approvers);
    }
}
