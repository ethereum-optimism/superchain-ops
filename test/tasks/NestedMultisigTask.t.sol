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
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";

import {MultisigTask, AddressRegistry} from "src/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {OPCMUpgradeV200} from "src/template/OPCMUpgradeV200.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MockSetEIP1967ImplTask} from "test/tasks/mock/MockSetEIP1967ImplTask.sol";
import {SetEIP1967Implementation} from "src/template/SetEIP1967Implementation.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";
import {TaskManager} from "src/tasks/TaskManager.sol";

/// @notice This test is used to test the nested multisig task.
contract NestedMultisigTaskTest is Test {
    struct TestData {
        address[] allSafes;
        address[] childSafes;
        bytes[] allCalldatas;
        IGnosisSafe rootSafe;
        bytes rootSafeCalldata;
        uint256 originalRootSafeNonce;
        address[] childDepth1OwnerMultisigs;
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

    /// @notice Mock safe configuration constants
    uint256 public constant MOCK_OWNER_COUNT = 9;
    uint256 public constant MOCK_THRESHOLD = 4;

    string constant TESTING_DIRECTORY = "nested-multisig-task-testing";

    /// @notice Set the implementation of the OptimismPortalProxy to an old implementation.
    string constant taskConfigToml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
        "templateName = \"SetEIP1967Implementation\"\n contractIdentifier = \"OptimismPortalProxy\"\n newImplementation = \"0xB443Da3e07052204A02d630a8933dAc05a0d6fB4\"\n";

    /// Addresses used for the above config.toml file.
    address constant ROOT_SAFE = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address constant SECURITY_COUNCIL_CHILD_MULTISIG = 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03;

    function runTask(address[] memory _childSafes, string memory _taskConfigFilePath, string memory _salt)
        internal
        returns (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions, address rootSafe)
    {
        multisigTask = new SetEIP1967Implementation();
        string memory configFilePath =
            MultisigTaskTestHelper.createTempTomlFile(_taskConfigFilePath, TESTING_DIRECTORY, _salt);

        (accountAccesses, actions,, rootSafe) = multisigTask.simulate(configFilePath, _childSafes);

        MultisigTaskTestHelper.removeFile(configFilePath);
        addrRegistry = multisigTask.addrRegistry();
        superchainAddrRegistry = SuperchainAddressRegistry(AddressRegistry.unwrap(addrRegistry));
    }

    function testSafeNested() public {
        vm.createSelectFork("mainnet");
        (,, address rootSafe) = runTask(Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG), taskConfigToml, "000");
        assertEq(multisigTask.isNestedSafe(rootSafe), true, "Expected isNestedSafe to be true");
    }

    function testNestedDataToSignAndHashToApprove() public {
        vm.createSelectFork("mainnet");
        address[] memory childSafes = Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG);
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(ROOT_SAFE, SECURITY_COUNCIL_CHILD_MULTISIG);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);

        (, Action[] memory actions,) = runTask(childSafes, taskConfigToml, "001");

        // Prepare test data
        TestData memory testData = _prepareTestData(allOriginalNonces, actions, allSafes, childSafes);

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

        for (uint256 i; i < testData.childDepth1OwnerMultisigs.length; i++) {
            // Validate the data to sign for the child multisig.
            _validateNestedDataToSign(testData.childDepth1OwnerMultisigs[i], callDataToApprove, MULTICALL3_ADDRESS);
        }
    }

    /// @notice Test that the data to sign generated in 'sign' for the child multisigs is correct for MultisigTask.
    function testNestedExecuteWithSignatures() public {
        vm.createSelectFork("mainnet");
        uint256 snapshotId = vm.snapshotState();
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(ROOT_SAFE, SECURITY_COUNCIL_CHILD_MULTISIG);
        address[] memory childSafes = Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);

        (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions,) =
            runTask(childSafes, taskConfigToml, "002");

        // Prepare test data
        TestData memory testData = _prepareTestData(allOriginalNonces, actions, allSafes, childSafes);

        // Prepare child multisig signatures
        LeafSafeSigningData[] memory leafSafeSigningData =
            _prepareDataToSignForLeafSafes(testData, actions, MULTICALL3_ADDRESS);

        // Setup mock owners and execute approvals
        vm.revertToState(snapshotId);

        // Extract leaf safe addresses for mock owner setup
        address[] memory leafSafeAddresses = new address[](leafSafeSigningData.length);
        for (uint256 i = 0; i < leafSafeSigningData.length; i++) {
            leafSafeAddresses[i] = leafSafeSigningData[i].leafSafe;
        }
        _setupMockOwners(leafSafeAddresses);
        for (uint256 i = 0; i < leafSafeSigningData.length; i++) {
            address[] memory singleChildSafe = Solarray.addresses(leafSafeSigningData[i].leafSafe);
            bytes memory packedSignaturesChild =
                _packSignaturesForChildMultisig(leafSafeSigningData[i].leafSafe, leafSafeSigningData[i].dataToSign);
            // execute the approve hash call with the signatures
            multisigTask = new SetEIP1967Implementation();
            string memory configFilePath =
                MultisigTaskTestHelper.createTempTomlFile(taskConfigToml, TESTING_DIRECTORY, "001");
            multisigTask.approve(configFilePath, singleChildSafe, packedSignaturesChild);
            MultisigTaskTestHelper.removeFile(configFilePath);
        }

        // Execute final task and verify results
        addrRegistry = multisigTask.addrRegistry();
        SuperchainAddressRegistry superchainAddrReg = SuperchainAddressRegistry(AddressRegistry.unwrap(addrRegistry));
        address optimismPortalProxy = superchainAddrReg.getAddress("OptimismPortalProxy", 10);
        _executeSetEIP1967ImplementationTaskAndVerify(
            testData,
            accountAccesses,
            actions,
            taskConfigToml,
            optimismPortalProxy,
            0xB443Da3e07052204A02d630a8933dAc05a0d6fB4
        );
    }

    /// @notice This test identifies all the leaf safes (a leaf safe is a safe that has no nested safes) from a given root safe.
    /// It then generates the data to sign for each signer of the leaf safes. This is then signed by the owners of the leaf safes.
    /// Using the signatures, the leaf safes are approved along with their parent safes before the task is executed.
    function testNestedNestedExecuteWithSignatures() public {
        vm.createSelectFork("mainnet", 23040371); // Block where Base has a nested-nested safe architecture.
        address baseRootSafe = 0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c;
        address baseNested = 0x9855054731540A48b28990B63DcF4f33d8AE46A1;
        address baseCouncil = 0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd;
        address[] memory childSafes = Solarray.addresses(baseCouncil, baseNested);
        uint256 snapshotId = vm.snapshotState();
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(baseRootSafe, baseNested, baseCouncil);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);

        string memory baseTaskConfigToml = "l2chains = [{name = \"Base\", chainId = 8453}]\n" "\n"
            "templateName = \"SetEIP1967Implementation\"\n contractIdentifier = \"DisputeGameFactoryProxy\"\n newImplementation = \"0xf691F8A6d908B58C534B624cF16495b491E633BA\"\n";

        (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions,) =
            runTask(childSafes, baseTaskConfigToml, "003");

        // Prepare test data
        TestData memory testData = _prepareTestData(allOriginalNonces, actions, allSafes, childSafes);

        // Prepare child multisig signatures
        LeafSafeSigningData[] memory leafSafeSigningData =
            _prepareDataToSignForLeafSafes(testData, actions, MULTICALL3_ADDRESS);

        // Setup mock owners and execute approvals in correct order (depth 2 first, then depth 1)
        vm.revertToState(snapshotId);
        MultiSigOwner[] memory newOwners = _createMockOwners();

        // Configure all leaf safes with mock owners
        for (uint256 i = 0; i < leafSafeSigningData.length; i++) {
            _configureChildMultisig(leafSafeSigningData[i].leafSafe, newOwners);
        }

        // Execute approvals for all leaf safes
        for (uint256 i = 0; i < leafSafeSigningData.length; i++) {
            address[] memory tmpChildSafes = Solarray.addresses(leafSafeSigningData[i].leafSafe);
            if (leafSafeSigningData[i].depth == 2) {
                tmpChildSafes = Solarray.extend(tmpChildSafes, Solarray.addresses(leafSafeSigningData[i].parentSafe));
            }
            bytes memory packedSignaturesChild =
                _packSignaturesForChildMultisig(leafSafeSigningData[i].leafSafe, leafSafeSigningData[i].dataToSign);

            // Execute the approve call for this leaf safe
            multisigTask = new SetEIP1967Implementation();
            string memory configFilePath =
                MultisigTaskTestHelper.createTempTomlFile(baseTaskConfigToml, TESTING_DIRECTORY, "004");
            multisigTask.approve(configFilePath, tmpChildSafes, packedSignaturesChild);

            MultisigTaskTestHelper.removeFile(configFilePath);
        }

        // Approve depth 1 safes (direct children of root). These safes have already been
        // pre-approved by their leaf safe owners in the previous step, so we call approve
        // with empty signatures to mark them as ready for the final root safe execution.
        for (uint256 i = 0; i < testData.childDepth1OwnerMultisigs.length; i++) {
            multisigTask = new SetEIP1967Implementation();
            string memory configFilePath =
                MultisigTaskTestHelper.createTempTomlFile(baseTaskConfigToml, TESTING_DIRECTORY, "004");
            multisigTask.approve(configFilePath, Solarray.addresses(testData.childDepth1OwnerMultisigs[i]), bytes(""));
            MultisigTaskTestHelper.removeFile(configFilePath);
        }

        // Execute final task and verify results
        addrRegistry = multisigTask.addrRegistry();
        SuperchainAddressRegistry superchainAddrReg = SuperchainAddressRegistry(AddressRegistry.unwrap(addrRegistry));
        address optimismPortalProxy = superchainAddrReg.getAddress("OptimismPortalProxy", 8453); // Base chain ID
        _executeSetEIP1967ImplementationTaskAndVerify(
            testData,
            accountAccesses,
            actions,
            baseTaskConfigToml,
            optimismPortalProxy,
            0xB443Da3e07052204A02d630a8933dAc05a0d6fB4
        );
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

        (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions,, address rootSafe) =
            multisigTask.simulate(opcmTaskConfigFilePath, childSafes);

        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(rootSafe, foundationChildMultisig);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);

        TestData memory testData = _prepareTestData(allOriginalNonces, actions, allSafes, childSafes);
        LeafSafeSigningData[] memory leafSafeSigningData =
            _prepareDataToSignForLeafSafes(testData, actions, MULTICALL3_ADDRESS);
        // Revert to snapshot so that the safe is in the same state as before the task was run
        vm.revertToState(snapshotId);

        MultiSigOwner[] memory newOwners = _createMockOwners();
        for (uint256 i = 0; i < leafSafeSigningData.length; i++) {
            address[] memory tmpChildSafes = Solarray.addresses(leafSafeSigningData[i].leafSafe);
            _configureChildMultisig(leafSafeSigningData[i].leafSafe, newOwners);
            // sign the approve hash call data to sign with the private keys of the new owners of the child multisig
            bytes memory packedSignaturesChild =
                _packSignaturesForChildMultisig(leafSafeSigningData[i].leafSafe, leafSafeSigningData[i].dataToSign);

            // execute the approve hash call with the signatures
            multisigTask = new OPCMUpgradeV200();
            multisigTask.approve(opcmTaskConfigFilePath, tmpChildSafes, packedSignaturesChild);
        }

        // Execute the task
        multisigTask = new OPCMUpgradeV200();
        // Snapshot before running the task so we can roll back to this pre-state
        uint256 newSnapshot = vm.snapshotState();

        (accountAccesses, actions,,) = multisigTask.simulate(opcmTaskConfigFilePath, childSafes);
        bytes32 taskHash = multisigTask.getHash(
            testData.rootSafeCalldata, address(testData.rootSafe), 0, testData.originalRootSafeNonce, testData.allSafes
        );

        vm.revertToState(newSnapshot);
        multisigTask.execute(
            opcmTaskConfigFilePath, prepareSignatures(address(testData.rootSafe), taskHash), childSafes
        );
    }

    function testSimulateCodeExceptionsCheckCircumvented() public {
        vm.createSelectFork("mainnet");
        multisigTask = new MockSetEIP1967ImplTask();
        string memory toml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
            "templateName = \"SetEIP1967Implementation\"\n contractIdentifier = \"OptimismPortalProxy\"\n newImplementation = \"0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf\"\n";
        string memory configFilePath = MultisigTaskTestHelper.createTempTomlFile(toml, TESTING_DIRECTORY, "005");
        (,,, address rootSafe) =
            multisigTask.simulate(configFilePath, Solarray.addresses(SECURITY_COUNCIL_CHILD_MULTISIG));
        assertEq(multisigTask.isNestedSafe(rootSafe), true, "Expected isNestedSafe to be true");
        MultisigTaskTestHelper.removeFile(configFilePath);
    }

    function testSimulateCodeExceptionsCheckReverts() public {
        vm.createSelectFork("mainnet", 23149345);
        multisigTask = new SetEIP1967Implementation();
        string memory toml = "l2chains = [{name = \"OP Mainnet\", chainId = 10}]\n" "\n"
            "templateName = \"SetEIP1967Implementation\"\n contractIdentifier = \"OptimismPortalProxy\"\n newImplementation = \"0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf\"\n";
        string memory configFilePath = MultisigTaskTestHelper.createTempTomlFile(toml, TESTING_DIRECTORY, "006");

        string memory err = string.concat(
            "Likely address in storage has no code\n",
            "  account: ",
            vm.toString(address(0xbEb5Fc579115071764c7423A4f12eDde41f106Ed)), // OptimismPortalProxy address at block 23149345
            "\n  slot:    ",
            vm.toString(bytes32(Constants.PROXY_IMPLEMENTATION_ADDRESS)),
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

    function _prepareTestData(
        uint256[] memory _allOriginalNonces,
        Action[] memory _actions,
        address[] memory _allSafes,
        address[] memory _childSafes
    ) internal view returns (TestData memory testData) {
        testData.allSafes = _allSafes;
        testData.childSafes = _childSafes;
        testData.allCalldatas = multisigTask.transactionDatas(_actions, testData.allSafes, _allOriginalNonces);
        testData.rootSafe = IGnosisSafe(testData.allSafes[testData.allSafes.length - 1]);
        testData.rootSafeCalldata = testData.allCalldatas[testData.allCalldatas.length - 1];
        testData.originalRootSafeNonce = _allOriginalNonces[_allOriginalNonces.length - 1];
        testData.childDepth1OwnerMultisigs = testData.rootSafe.getOwners();
    }

    struct LeafSafeSigningData {
        address leafSafe; // The actual safe that needs to sign
        bytes dataToSign; // The data this safe needs to sign
        uint256 depth; // 1 for direct child, 2 for nested child
        address parentSafe; // The parent safe (only relevant for depth 2)
    }

    /// @notice This function finds all leaf safes given a root safe. It returns the data to sign for each leaf safe
    /// along with the path information. Leaf safes are the deepest level safes in the hierarchy.
    function _prepareDataToSignForLeafSafes(
        TestData memory _testData,
        Action[] memory _actions,
        address _multicallAddress
    ) internal returns (LeafSafeSigningData[] memory leafSafeSigningData) {
        address rootSafe = address(_testData.rootSafe);
        address[] memory childDepth1OwnerMultisigs = _testData.childDepth1OwnerMultisigs;

        MultisigTaskTestHelper.decrementNonceAfterSimulation(rootSafe);

        // Count total leaf safes
        TaskManager tm = new TaskManager();
        uint256 totalLeafSafes = 0;
        for (uint256 i = 0; i < childDepth1OwnerMultisigs.length; i++) {
            if (tm.isNestedSafe(childDepth1OwnerMultisigs[i])) {
                totalLeafSafes += IGnosisSafe(childDepth1OwnerMultisigs[i]).getOwners().length;
            } else {
                totalLeafSafes += 1;
            }
        }

        leafSafeSigningData = new LeafSafeSigningData[](totalLeafSafes);
        uint256 currentIndex = 0;

        // Populate signing data directly
        for (uint256 i = 0; i < childDepth1OwnerMultisigs.length; i++) {
            address childMultisig = childDepth1OwnerMultisigs[i];
            MultisigTaskTestHelper.decrementNonceAfterSimulation(childMultisig);

            if (tm.isNestedSafe(childMultisig)) {
                // Handle nested safe (depth 2 owners)
                address[] memory depth2Owners = IGnosisSafe(childMultisig).getOwners();
                for (uint256 j = 0; j < depth2Owners.length; j++) {
                    leafSafeSigningData[currentIndex] =
                        _createDepth2SigningData(rootSafe, childMultisig, depth2Owners[j], _actions, _multicallAddress);
                    currentIndex++;
                }
            } else {
                // Handle leaf safe at depth 1
                leafSafeSigningData[currentIndex] =
                    _createDepth1SigningData(rootSafe, childMultisig, _actions, _multicallAddress);
                currentIndex++;
            }
        }
    }

    /// @notice Create signing data for a depth 1 safe (direct child of root)
    function _createDepth1SigningData(
        address rootSafe,
        address childSafe,
        Action[] memory _actions,
        address _multicallAddress
    ) internal view returns (LeafSafeSigningData memory) {
        address[] memory tmpAllSafes = MultisigTaskTestHelper.getAllSafes(rootSafe, childSafe);
        uint256[] memory tmpAllOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(tmpAllSafes);
        bytes[] memory tmpAllCalldatas = multisigTask.transactionDatas(_actions, tmpAllSafes, tmpAllOriginalNonces);

        return LeafSafeSigningData({
            leafSafe: childSafe,
            dataToSign: GnosisSafeHashes.getEncodedTransactionData(
                childSafe, tmpAllCalldatas[0], 0, tmpAllOriginalNonces[0], _multicallAddress
            ),
            depth: 1,
            parentSafe: rootSafe
        });
    }

    /// @notice Create signing data for a depth 2 safe (nested child)
    function _createDepth2SigningData(
        address rootSafe,
        address childSafe,
        address depth2Safe,
        Action[] memory _actions,
        address _multicallAddress
    ) internal view returns (LeafSafeSigningData memory) {
        address[] memory tmpAllSafes = MultisigTaskTestHelper.getAllSafes(rootSafe, childSafe, depth2Safe);
        uint256[] memory tmpAllOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(tmpAllSafes);
        bytes[] memory tmpAllCalldatas = multisigTask.transactionDatas(_actions, tmpAllSafes, tmpAllOriginalNonces);

        return LeafSafeSigningData({
            leafSafe: depth2Safe,
            dataToSign: GnosisSafeHashes.getEncodedTransactionData(
                depth2Safe, tmpAllCalldatas[0], 0, tmpAllOriginalNonces[0], _multicallAddress
            ),
            depth: 2,
            parentSafe: childSafe
        });
    }

    function _setupMockOwners(address[] memory childOwnerMultisigs) internal {
        MultiSigOwner[] memory newOwners = _createMockOwners();
        for (uint256 i = 0; i < childOwnerMultisigs.length; i++) {
            _configureChildMultisig(childOwnerMultisigs[i], newOwners);
        }
    }

    function _createMockOwners() internal returns (MultiSigOwner[] memory newOwners) {
        newOwners = new MultiSigOwner[](MOCK_OWNER_COUNT);
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

        // set the owners count
        vm.store(childMultisig, bytes32(OWNER_COUNT_STORAGE_OFFSET), bytes32(uint256(MOCK_OWNER_COUNT)));

        // set the threshold
        vm.store(childMultisig, bytes32(THRESHOLD_STORAGE_OFFSET), bytes32(uint256(MOCK_THRESHOLD)));

        // Verify configuration
        address[] memory getNewOwners = IGnosisSafe(childMultisig).getOwners();
        assertEq(getNewOwners.length, MOCK_OWNER_COUNT, "Expected correct number of owners");
        for (uint256 j = 0; j < newOwners.length; j++) {
            assertEq(getNewOwners[j], newOwners[j].walletAddress, "Expected owner");
        }

        uint256 threshold = IGnosisSafe(childMultisig).getThreshold();
        assertEq(threshold, MOCK_THRESHOLD, "Expected threshold should be updated to mocked value");
    }

    /// @notice Pack the signatures for the child multisig.
    function _packSignaturesForChildMultisig(address childMultisig, bytes memory childMultisigDataToSign)
        internal
        view
        returns (bytes memory packedSignaturesChild_)
    {
        address[] memory getNewOwners = IGnosisSafe(childMultisig).getOwners();
        LibSort.sort(getNewOwners);

        uint256 threshold = MOCK_THRESHOLD;
        for (uint256 j = 0; j < threshold; j++) {
            (uint8 v, bytes32 r, bytes32 s) =
                vm.sign(privateKeyForOwner[getNewOwners[j]], keccak256(childMultisigDataToSign));
            packedSignaturesChild_ = bytes.concat(packedSignaturesChild_, abi.encodePacked(r, s, v));
        }
    }

    /// @notice Execute the SetEIP1967ImplementationTask and verify the implementation is upgraded correctly.
    function _executeSetEIP1967ImplementationTaskAndVerify(
        TestData memory _testData,
        VmSafe.AccountAccess[] memory _accountAccesses,
        Action[] memory _actions,
        string memory _taskConfigToml,
        address _proxy,
        address _expectedImplementation
    ) internal {
        // execute the task
        multisigTask = new SetEIP1967Implementation();

        /// snapshot before running the task so we can roll back to this pre-state
        uint256 newSnapshot = vm.snapshotState();

        string memory config = MultisigTaskTestHelper.createTempTomlFile(_taskConfigToml, TESTING_DIRECTORY, "002");

        (_accountAccesses, _actions,,) = multisigTask.simulate(config, _testData.childSafes);

        MultisigTaskTestHelper.removeFile(config);

        // Check that the implementation is upgraded correctly
        vm.prank(address(0));
        assertEq(address(Proxy(payable(_proxy)).implementation()), _expectedImplementation, "implementation not set");

        bytes32 taskHash = multisigTask.getHash(
            _testData.rootSafeCalldata,
            address(_testData.rootSafe),
            0,
            _testData.originalRootSafeNonce,
            _testData.allSafes
        );

        /// Now run the executeRun flow
        vm.revertToState(newSnapshot);
        string memory taskConfigFilePath =
            MultisigTaskTestHelper.createTempTomlFile(_taskConfigToml, TESTING_DIRECTORY, "003");
        multisigTask.execute(
            taskConfigFilePath, prepareSignatures(address(_testData.rootSafe), taskHash), _testData.childSafes
        );
        MultisigTaskTestHelper.removeFile(taskConfigFilePath);

        // Check that the implementation is upgraded correctly for a second time
        vm.prank(address(0));
        assertEq(address(Proxy(payable(_proxy)).implementation()), _expectedImplementation, "implementation not set");
    }

    function prepareSignatures(address _safe, bytes32 hash) internal view returns (bytes memory) {
        // prepend the prevalidated signatures to the signatures
        address[] memory approvers = Signatures.getApprovers(_safe, hash);
        return Signatures.genPrevalidatedSignatures(approvers);
    }
}
