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
import {Solarray} from "lib/optimism/packages/contracts-bedrock/scripts/libraries/Solarray.sol";

import {MultisigTask, AddressRegistry} from "src/improvements/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {DisputeGameUpgradeTemplate} from "test/tasks/mock/template/DisputeGameUpgradeTemplate.sol";
import {OPCMUpgradeV200} from "src/improvements/template/OPCMUpgradeV200.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MockDisputeGameTask} from "test/tasks/mock/MockDisputeGameTask.sol";
import {DisputeGameUpgradeTemplate} from "test/tasks/mock/template/DisputeGameUpgradeTemplate.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";

/// @notice This test is used to test the nested multisig task.
contract NestedMultisigTaskTest is Test {
    struct TestData {
        address[] allSafes;
        bytes[] allCalldatas;
        IGnosisSafe rootSafe;
        bytes rootSafeCalldata;
        uint256 originalRootSafeNonce;
        address[] childOwnerMultisigs;
    }

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

    string constant TESTING_DIRECTORY = "nested-multisig-task-testing";

    /// @notice ProxyAdminOwner safe for the task below is a nested multisig for Op mainnet L2 chain.
    string constant taskConfigToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
        "templateName = \"DisputeGameUpgradeTemplate\"\n" "\n"
        "implementations = [{gameType = 0, implementation = \"0xf691F8A6d908B58C534B624cF16495b491E633BA\", l2ChainId = 10}]\n";

    /// Addresses used for the above config.toml file.
    address constant ROOT_SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant SECURITY_COUNCIL_CHILD_MULTISIG = 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03;

    function runTask(address childMultisig)
        internal
        returns (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions, address rootSafe)
    {
        multisigTask = new DisputeGameUpgradeTemplate();
        string memory configFilePath =
            MultisigTaskTestHelper.createTempTomlFile(taskConfigToml, TESTING_DIRECTORY, "000");

        (accountAccesses, actions,,, rootSafe) =
            multisigTask.simulate(configFilePath, Solarray.addresses(childMultisig));

        MultisigTaskTestHelper.removeFile(configFilePath);
        addrRegistry = multisigTask.addrRegistry();
        superchainAddrRegistry = SuperchainAddressRegistry(AddressRegistry.unwrap(addrRegistry));
    }

    function testSafeNested() public {
        vm.createSelectFork("mainnet");
        (,, address rootSafe) = runTask(SECURITY_COUNCIL_CHILD_MULTISIG);
        assertEq(multisigTask.isNestedSafe(rootSafe), true, "Expected isNestedSafe to be true");
    }

    function testNestedDataToSignAndHashToApprove() public {
        vm.createSelectFork("mainnet");
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(ROOT_SAFE, SECURITY_COUNCIL_CHILD_MULTISIG);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);

        (, Action[] memory actions, address rootSafe) = runTask(SECURITY_COUNCIL_CHILD_MULTISIG);

        // Step 1: Prepare test data
        TestData memory testData = _prepareTestData(allOriginalNonces, actions, rootSafe);

        // Get the hash of the transaction that the root safe is going to execute which the child multisigs have to approve.
        bytes32 hashToApproveByChildMultisig = testData.rootSafe.getTransactionHash(
            MULTICALL3_ADDRESS,
            0,
            testData.rootSafeCalldata,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            address(0),
            testData.originalRootSafeNonce
        );

        IMulticall3.Call3Value memory call = IMulticall3.Call3Value({
            target: address(testData.rootSafe),
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(testData.rootSafe.approveHash, (hashToApproveByChildMultisig))
        });
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);
        calls[0] = call;
        bytes memory callDataToApprove =
            abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
        bytes memory childSafeCallData = testData.allCalldatas[0];
        assertEq(callDataToApprove, childSafeCallData, "Wrong callDataToApprove");

        for (uint256 i; i < testData.childOwnerMultisigs.length; i++) {
            // Validate the data to sign for the child multisig.
            _validateNestedDataToSign(testData.childOwnerMultisigs[i], callDataToApprove, MULTICALL3_ADDRESS);
        }
    }

    /// @notice Test that the data to sign generated in 'sign' for the child multisigs is correct for MultisigTask.
    function testNestedExecuteWithSignatures() public {
        vm.createSelectFork("mainnet");
        uint256 snapshotId = vm.snapshotState();
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(ROOT_SAFE, SECURITY_COUNCIL_CHILD_MULTISIG);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);

        (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions, address rootSafe) =
            runTask(SECURITY_COUNCIL_CHILD_MULTISIG);

        // Step 1: Prepare test data
        TestData memory testData = _prepareTestData(allOriginalNonces, actions, rootSafe);

        // Step 2: Prepare child multisig signatures
        bytes[] memory childMultisigDatasToSign = _prepareChildMultisigSignatures(testData, actions, MULTICALL3_ADDRESS);

        // Step 3: Setup mock owners and execute approvals
        vm.revertToState(snapshotId);
        MultiSigOwner[] memory newOwners = _setupMockOwners(testData.childOwnerMultisigs);
        for (uint256 i = 0; i < testData.childOwnerMultisigs.length; i++) {
            address[] memory childSafes = Solarray.addresses(testData.childOwnerMultisigs[i]);
            _configureChildMultisig(testData.childOwnerMultisigs[i], newOwners);
            bytes memory packedSignaturesChild =
                _packSignaturesForChildMultisig(testData.childOwnerMultisigs[i], childMultisigDatasToSign[i]);
            // execute the approve hash call with the signatures
            multisigTask = new DisputeGameUpgradeTemplate();
            string memory configFilePath =
                MultisigTaskTestHelper.createTempTomlFile(taskConfigToml, TESTING_DIRECTORY, "001");
            multisigTask.approve(configFilePath, childSafes, packedSignaturesChild);
            MultisigTaskTestHelper.removeFile(configFilePath);
        }

        // Step 4: Execute final task and verify results
        addrRegistry = multisigTask.addrRegistry();
        SuperchainAddressRegistry superchainAddrReg = SuperchainAddressRegistry(AddressRegistry.unwrap(addrRegistry));
        address disputeGameFactory = superchainAddrReg.getAddress("DisputeGameFactoryProxy", 10);
        _executeDisputeGameUpgradeTaskAndVerify(
            testData, accountAccesses, actions, disputeGameFactory, 0xf691F8A6d908B58C534B624cF16495b491E633BA
        );
    }

    function testNestedNestedExecuteWithSignatures() public {
        // TODO: @blmalone implement this test.
    }

    /// @notice Test that the 'data to sign' generated in simulate for the child multisigs
    /// is correct for OPCMTaskBase. This test uses the OPCMUpgradeV200 template as a way to test OPCMTaskBase.
    function testNestedExecuteWithSignaturesOPCM() public {
        address foundationChildMultisig = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B;
        // In block 7972617, an upgrade occurred at: https://sepolia.etherscan.io/tx/0x12b76ef5c31145a3bf6bb71b9c3c7ddd3cd7f182011187353e3ceb1830891fb7
        // Which meant this test failed. We're forking at the block before to continue to test this.
        vm.createSelectFork("sepolia", 7972616);
        uint256 snapshotId = vm.snapshotState();
        multisigTask = new OPCMUpgradeV200();
        string memory opcmTaskConfigFilePath = "test/tasks/example/sep/002-opcm-upgrade-v200/config.toml";

        address[] memory childSafes = Solarray.addresses(foundationChildMultisig);

        (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions,,, address rootSafe) =
            multisigTask.simulate(opcmTaskConfigFilePath, childSafes);

        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(rootSafe, foundationChildMultisig);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);

        TestData memory testData = _prepareTestData(allOriginalNonces, actions, rootSafe);
        address[] memory rootSafeOwners = testData.rootSafe.getOwners();
        bytes[] memory childMultisigDataToSign = _prepareChildMultisigSignatures(testData, actions, MULTICALL3_ADDRESS);
        // Revert to snapshot so that the safe is in the same state as before the task was run
        vm.revertToState(snapshotId);

        MultiSigOwner[] memory newOwners = _createMockOwners();
        for (uint256 i = 0; i < rootSafeOwners.length; i++) {
            address[] memory tmpChildSafes = Solarray.addresses(rootSafeOwners[i]);
            _configureChildMultisig(rootSafeOwners[i], newOwners);
            // sign the approve hash call data to sign with the private keys of the new owners of the child multisig
            bytes memory packedSignaturesChild =
                _packSignaturesForChildMultisig(rootSafeOwners[i], childMultisigDataToSign[i]);

            // execute the approve hash call with the signatures
            multisigTask = new OPCMUpgradeV200();
            multisigTask.approve(opcmTaskConfigFilePath, tmpChildSafes, packedSignaturesChild);
        }

        // Execute the task
        multisigTask = new OPCMUpgradeV200();
        // Snapshot before running the task so we can roll back to this pre-state
        uint256 newSnapshot = vm.snapshotState();

        (accountAccesses, actions,,,) = multisigTask.simulate(opcmTaskConfigFilePath, childSafes);
        bytes32 taskHash = multisigTask.getHash(
            testData.rootSafeCalldata, address(testData.rootSafe), 0, testData.originalRootSafeNonce, testData.allSafes
        );

        vm.revertToState(newSnapshot);
        multisigTask.execute(
            opcmTaskConfigFilePath, prepareSignatures(address(testData.rootSafe), taskHash), childSafes
        );
    }

    function testMockDisputeGameWithCodeExceptionsWorks() public {
        vm.createSelectFork("mainnet");
        string memory configFilePath = "test/tasks/mock/configs/MockDisputeGameUpgradesToEOA.toml";
        multisigTask = new MockDisputeGameTask();

        (,,,, address rootSafe) =
            multisigTask.simulate(configFilePath, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG));
        assertEq(multisigTask.isNestedSafe(rootSafe), true, "Expected isNestedSafe to be true");
    }

    function testSimulateDisputeGameWithoutCodeExceptionsFails() public {
        vm.createSelectFork("mainnet");
        string memory configFilePath = "test/tasks/mock/configs/MockDisputeGameUpgradesToEOA.toml";
        multisigTask = new DisputeGameUpgradeTemplate();

        uint256 start = vm.snapshotState();

        multisigTask.simulate(
            "test/tasks/mock/configs/DisputeGameUpgradeCodeException.toml",
            Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG)
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
        multisigTask.simulate(configFilePath, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG));
    }

    /// @notice Validate the data to sign for the child multisig.
    function _validateNestedDataToSign(
        address _childMultisig,
        bytes memory _callDataToApprove,
        address _multicallAddress
    ) internal view {
        address[] memory tmpAllSafes = MultisigTaskTestHelper.getAllSafes(ROOT_SAFE, _childMultisig);
        uint256[] memory tmpAllOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(tmpAllSafes);
        uint256 childSafeNonce = tmpAllOriginalNonces[0];
        bytes memory dataToSign = GnosisSafeHashes.getEncodedTransactionData(
            _childMultisig, _callDataToApprove, 0, childSafeNonce, _multicallAddress
        );

        bytes memory expectedDataToSign = IGnosisSafe(_childMultisig).encodeTransactionData({
            to: MULTICALL3_ADDRESS,
            value: 0,
            data: _callDataToApprove,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: childSafeNonce
        });
        assertEq(dataToSign, expectedDataToSign, "Wrong data to sign");

        bytes32 nestedHashToApprove = keccak256(dataToSign);
        bytes32 expectedNestedHashToApprove = IGnosisSafe(_childMultisig).getTransactionHash(
            MULTICALL3_ADDRESS,
            0,
            _callDataToApprove,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            address(0),
            childSafeNonce
        );
        assertEq(nestedHashToApprove, expectedNestedHashToApprove, "Wrong nested hash to approve");
    }

    function _prepareTestData(uint256[] memory allOriginalNonces, Action[] memory actions, address rootSafe)
        internal
        view
        returns (TestData memory testData)
    {
        testData.allSafes = MultisigTaskTestHelper.getAllSafes(rootSafe, SECURITY_COUNCIL_CHILD_MULTISIG);
        testData.allCalldatas = multisigTask.transactionDatas(actions, testData.allSafes, allOriginalNonces);
        testData.rootSafe = IGnosisSafe(testData.allSafes[testData.allSafes.length - 1]);
        testData.rootSafeCalldata = testData.allCalldatas[testData.allCalldatas.length - 1];
        testData.originalRootSafeNonce = allOriginalNonces[allOriginalNonces.length - 1];
        testData.childOwnerMultisigs = testData.rootSafe.getOwners();
    }

    function _prepareChildMultisigSignatures(
        TestData memory testData,
        Action[] memory actions,
        address multicallAddress
    ) internal returns (bytes[] memory childMultisigDatasToSign) {
        childMultisigDatasToSign = new bytes[](testData.childOwnerMultisigs.length);
        MultisigTaskTestHelper.decrementNonceAfterSimulation(address(testData.rootSafe));
        // Store the data to sign for each child multisig.
        for (uint256 i = 0; i < testData.childOwnerMultisigs.length; i++) {
            MultisigTaskTestHelper.decrementNonceAfterSimulation(testData.childOwnerMultisigs[i]);
            address[] memory tmpAllSafes =
                MultisigTaskTestHelper.getAllSafes(address(testData.rootSafe), testData.childOwnerMultisigs[i]);
            uint256[] memory tmpAllOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(tmpAllSafes);
            bytes[] memory tmpAllCalldatas = multisigTask.transactionDatas(actions, tmpAllSafes, tmpAllOriginalNonces);
            bytes memory childSafeCalldata = tmpAllCalldatas[0];
            uint256 childSafeNonce = tmpAllOriginalNonces[0];
            childMultisigDatasToSign[i] = GnosisSafeHashes.getEncodedTransactionData(
                testData.childOwnerMultisigs[i], childSafeCalldata, 0, childSafeNonce, multicallAddress
            );
        }
    }

    function _setupMockOwners(address[] memory childOwnerMultisigs)
        internal
        returns (MultiSigOwner[] memory newOwners)
    {
        newOwners = _createMockOwners();
        for (uint256 i = 0; i < childOwnerMultisigs.length; i++) {
            _configureChildMultisig(childOwnerMultisigs[i], newOwners);
        }
    }

    function _createMockOwners() internal returns (MultiSigOwner[] memory newOwners) {
        newOwners = new MultiSigOwner[](9);
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
    }

    /// @notice Configure the child multisig with the new owners.
    function _configureChildMultisig(address childMultisig, MultiSigOwner[] memory newOwners) internal {
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

        // Verify configuration
        address[] memory getNewOwners = IGnosisSafe(childMultisig).getOwners();
        assertEq(getNewOwners.length, 9, "Expected 9 owners");
        for (uint256 j = 0; j < newOwners.length; j++) {
            assertEq(getNewOwners[j], newOwners[j].walletAddress, "Expected owner");
        }

        uint256 threshold = IGnosisSafe(childMultisig).getThreshold();
        assertEq(threshold, 4, "Expected threshold should be updated to mocked value");
    }

    /// @notice Pack the signatures for the child multisig.
    function _packSignaturesForChildMultisig(address childMultisig, bytes memory childMultisigDataToSign)
        internal
        view
        returns (bytes memory packedSignaturesChild_)
    {
        address[] memory getNewOwners = IGnosisSafe(childMultisig).getOwners();
        LibSort.sort(getNewOwners);

        uint256 threshold = 4;
        for (uint256 j = 0; j < threshold; j++) {
            (uint8 v, bytes32 r, bytes32 s) =
                vm.sign(privateKeyForOwner[getNewOwners[j]], keccak256(childMultisigDataToSign));
            packedSignaturesChild_ = bytes.concat(packedSignaturesChild_, abi.encodePacked(r, s, v));
        }
    }

    /// @notice Execute the DisputeGameUpgradeTask and verify the implementation is upgraded correctly.
    function _executeDisputeGameUpgradeTaskAndVerify(
        TestData memory testData,
        VmSafe.AccountAccess[] memory accountAccesses,
        Action[] memory actions,
        address disputeGameFactory,
        address expectedImplementation
    ) internal {
        // execute the task
        multisigTask = new DisputeGameUpgradeTemplate();

        /// snapshot before running the task so we can roll back to this pre-state
        uint256 newSnapshot = vm.snapshotState();

        string memory config = MultisigTaskTestHelper.createTempTomlFile(taskConfigToml, TESTING_DIRECTORY, "002");

        (accountAccesses, actions,,,) =
            multisigTask.simulate(config, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG));

        MultisigTaskTestHelper.removeFile(config);

        // Check that the implementation is upgraded correctly
        assertEq(
            address(IDisputeGameFactory(disputeGameFactory).gameImpls(GameTypes.CANNON)),
            expectedImplementation,
            "implementation not set"
        );

        bytes32 taskHash = multisigTask.getHash(
            testData.rootSafeCalldata, address(testData.rootSafe), 0, testData.originalRootSafeNonce, testData.allSafes
        );

        /// Now run the executeRun flow
        vm.revertToState(newSnapshot);
        string memory taskConfigFilePath =
            MultisigTaskTestHelper.createTempTomlFile(taskConfigToml, TESTING_DIRECTORY, "003");
        multisigTask.execute(
            taskConfigFilePath,
            prepareSignatures(address(testData.rootSafe), taskHash),
            Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG)
        );
        MultisigTaskTestHelper.removeFile(taskConfigFilePath);

        // Check that the implementation is upgraded correctly for a second time
        assertEq(
            address(IDisputeGameFactory(disputeGameFactory).gameImpls(GameTypes.CANNON)),
            expectedImplementation,
            "implementation not set"
        );
    }

    function prepareSignatures(address _safe, bytes32 hash) internal view returns (bytes memory) {
        // prepend the prevalidated signatures to the signatures
        address[] memory approvers = Signatures.getApprovers(_safe, hash);
        return Signatures.genPrevalidatedSignatures(approvers);
    }
}
