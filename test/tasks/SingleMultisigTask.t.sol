// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Signatures} from "@base-contracts/script/universal/Signatures.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MultisigTask, AddressRegistry} from "src/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {GasConfigTemplate} from "test/tasks/mock/template/GasConfigTemplate.sol";
import {IncorrectGasConfigTemplate1} from "test/tasks/mock/template/IncorrectGasConfigTemplate1.sol";
import {IncorrectGasConfigTemplate2} from "test/tasks/mock/template/IncorrectGasConfigTemplate2.sol";
import {MultisigTaskTestHelper} from "test/tasks/MultisigTask.t.sol";
import {Utils} from "src/libraries/Utils.sol";
import {TaskPayload, SafeData} from "src/libraries/MultisigTypes.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";

contract SingleMultisigTaskTest is Test {
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

    /// @notice ProxyAdminOwner safe for task-00 is a single multisig.
    string taskConfigFilePath = "test/tasks/mock/configs/SingleMultisigGasConfigTemplate.toml";

    function setUp() public {
        vm.createSelectFork("mainnet");
    }

    function runTask()
        public
        returns (VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions, address rootSafe)
    {
        multisigTask = new GasConfigTemplate();
        (accountAccesses, actions,, rootSafe) = multisigTask.simulate(taskConfigFilePath, new address[](0));
    }

    function toSuperchainAddrRegistry(AddressRegistry _addrRegistry)
        internal
        pure
        returns (SuperchainAddressRegistry)
    {
        return SuperchainAddressRegistry(AddressRegistry.unwrap(_addrRegistry));
    }

    function testTemplateSetup() public {
        (,, address rootSafe) = runTask();
        assertEq(multisigTask.isNestedSafe(rootSafe), false, "Expected isNestedSafe to be false");
        assertEq(GasConfigTemplate(address(multisigTask)).gasLimits(34443), 100000000, "Expected gas limit for 34443");
        assertEq(GasConfigTemplate(address(multisigTask)).gasLimits(1750), 100000000, "Expected gas limit for 1750");
    }

    function testSafeSetup() public {
        (,, address rootSafe) = runTask();
        addrRegistry = multisigTask.addrRegistry();
        assertEq(
            rootSafe,
            toSuperchainAddrRegistry(addrRegistry).getAddress("SystemConfigOwner", 34443),
            "Wrong safe address string"
        );
        assertEq(
            rootSafe,
            toSuperchainAddrRegistry(addrRegistry).getAddress("SystemConfigOwner", 1750),
            "Wrong safe address string"
        );
        assertEq(multisigTask.isNestedSafe(rootSafe), false, "Expected isNestedSafe to be false");
    }

    function testAllowedStorageWrites() public {
        runTask();
        addrRegistry = multisigTask.addrRegistry();
        address[] memory allowedStorageAccesses = multisigTask.getAllowedStorageAccess();
        assertEq(
            allowedStorageAccesses[0],
            toSuperchainAddrRegistry(addrRegistry).getAddress("SystemConfigProxy", 34443),
            "Wrong storage write access address"
        );
        assertEq(
            allowedStorageAccesses[1],
            toSuperchainAddrRegistry(addrRegistry).getAddress("SystemConfigProxy", 1750),
            "Wrong storage write access address"
        );
    }

    function testBuild() public {
        MultisigTask localMultisigTask = new GasConfigTemplate();
        Action[] memory actions;
        VmSafe.AccountAccess[] memory accountAccesses;

        vm.expectRevert("No actions found");
        localMultisigTask.processTaskActions(actions);

        (accountAccesses, actions,,) = localMultisigTask.simulate(taskConfigFilePath, new address[](0));

        addrRegistry = localMultisigTask.addrRegistry();

        (address[] memory targets, uint256[] memory values, bytes[] memory arguments) =
            localMultisigTask.processTaskActions(actions);

        assertEq(targets.length, 2, "Expected 2 targets");
        assertEq(
            targets[0],
            toSuperchainAddrRegistry(addrRegistry).getAddress("SystemConfigProxy", 34443),
            "Expected SystemConfigProxy target"
        );
        assertEq(
            targets[1],
            toSuperchainAddrRegistry(addrRegistry).getAddress("SystemConfigProxy", 1750),
            "Expected SystemConfigProxy target"
        );
        assertEq(values.length, 2, "Expected 2 values");
        assertEq(values[0], 0, "Expected 0 value");
        assertEq(values[1], 0, "Expected 0 value");
        assertEq(arguments.length, 2, "Expected 2 arguments");
        assertEq(arguments[0], abi.encodeWithSignature("setGasLimit(uint64)", uint64(100000000)), "Wrong calldata");
        assertEq(arguments[1], abi.encodeWithSignature("setGasLimit(uint64)", uint64(100000000)), "Wrong calldata");
    }

    function testGetRootSafeCallData() public {
        (, Action[] memory actions, address rootSafe) = runTask();
        (address[] memory targets, uint256[] memory values, bytes[] memory arguments) =
            multisigTask.processTaskActions(actions);
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

        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(rootSafe);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);
        bytes[] memory allCalldatas = multisigTask.transactionDatas(actions, allSafes, allOriginalNonces);
        bytes memory rootSafeCallData = allCalldatas[allCalldatas.length - 1];
        assertEq(rootSafeCallData, expectedCallData, "Wrong calldata");
    }

    function testGetDataToSign() public {
        (, Action[] memory actions, address rootSafe) = runTask();
        addrRegistry = multisigTask.addrRegistry();
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(rootSafe);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);
        bytes[] memory allCalldatas = multisigTask.transactionDatas(actions, allSafes, allOriginalNonces);
        TaskPayload memory payload =
            TaskPayload({safes: allSafes, calldatas: allCalldatas, originalNonces: allOriginalNonces});

        SafeData memory rootSafeData = Utils.getSafeData(payload, payload.safes.length - 1);

        bytes memory dataToSign = GnosisSafeHashes.getEncodedTransactionData(
            rootSafe, rootSafeData.callData, 0, rootSafeData.nonce, MULTICALL3_ADDRESS
        );

        bytes memory expectedDataToSign = IGnosisSafe(rootSafe).encodeTransactionData({
            to: MULTICALL3_ADDRESS,
            value: 0,
            data: rootSafeData.callData,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: rootSafeData.nonce
        });
        assertEq(dataToSign, expectedDataToSign, "Wrong data to sign");
    }

    function testHashToApprove() public {
        (, Action[] memory actions, address rootSafe) = runTask();
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(rootSafe);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);
        bytes[] memory allCalldatas = multisigTask.transactionDatas(actions, allSafes, allOriginalNonces);
        TaskPayload memory payload =
            TaskPayload({safes: allSafes, calldatas: allCalldatas, originalNonces: allOriginalNonces});

        SafeData memory rootSafeData = Utils.getSafeData(payload, payload.safes.length - 1);

        bytes32 hash = multisigTask.getHash(rootSafeData.callData, rootSafeData.safe, 0, rootSafeData.nonce, allSafes);
        bytes32 expectedHash = IGnosisSafe(rootSafe).getTransactionHash(
            MULTICALL3_ADDRESS,
            0,
            rootSafeData.callData,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            address(0),
            rootSafeData.nonce
        );
        assertEq(hash, expectedHash, "Wrong hash to approve");
    }

    function testRevertIfReInitialised() public {
        runTask();
        vm.expectRevert("MultisigTask: already initialized");
        multisigTask.simulate(taskConfigFilePath, new address[](0));
    }

    function testRevertIfUnsupportedChain() public {
        vm.chainId(20101010); // non-existent chain ID
        MultisigTask localMultisigTask = new GasConfigTemplate();
        vm.expectRevert("SuperchainAddressRegistry: Unsupported task chain ID 20101010");
        localMultisigTask.simulate(taskConfigFilePath, new address[](0));
    }

    function testRevertIfDifferentL2SafeAddresses() public {
        string memory incorrectTaskConfigFilePath = "test/tasks/mock/configs/MultisigSafeAddressMismatch.toml";
        MultisigTask localMultisigTask = new GasConfigTemplate();
        SuperchainAddressRegistry addressRegistry = new SuperchainAddressRegistry(incorrectTaskConfigFilePath);
        bytes memory expectedRevertMessage = bytes(
            string.concat(
                "MultisigTask: safe address mismatch. Caller: ",
                MultisigTaskPrinter.getAddressLabel(addressRegistry.getAddress("SystemConfigOwner", 8453)),
                ". Actual address: ",
                MultisigTaskPrinter.getAddressLabel(addressRegistry.getAddress("SystemConfigOwner", 1750))
            )
        );
        vm.expectRevert(expectedRevertMessage);
        localMultisigTask.simulate(incorrectTaskConfigFilePath, new address[](0));
    }

    function testRevertIfIncorrectAllowedStorageWrite() public {
        MultisigTask localMultisigTask = new IncorrectGasConfigTemplate1();
        SuperchainAddressRegistry addressRegistry = new SuperchainAddressRegistry(taskConfigFilePath);
        bytes memory expectedRevertMessage = bytes(
            string.concat(
                "MultisigTask: address ",
                MultisigTaskPrinter.getAddressLabel(addressRegistry.getAddress("SystemConfigProxy", 34443)),
                " not in allowed storage accesses"
            )
        );
        vm.expectRevert(expectedRevertMessage);
        localMultisigTask.simulate(taskConfigFilePath, new address[](0));
    }

    function testRevertIfAllowedStorageNotWritten() public {
        MultisigTask localMultisigTask = new IncorrectGasConfigTemplate2();
        SuperchainAddressRegistry addressRegistry = new SuperchainAddressRegistry(taskConfigFilePath);
        bytes memory expectedRevertMessage = bytes(
            string.concat(
                "MultisigTask: address ",
                MultisigTaskPrinter.getAddressLabel(addressRegistry.getAddress("SystemConfigProxy", 34443)),
                " not in allowed storage accesses"
            )
        );
        vm.expectRevert(expectedRevertMessage);
        localMultisigTask.simulate(taskConfigFilePath, new address[](0));
    }

    function testExecuteWithSignatures() public {
        uint256 snapshotId = vm.snapshotState();
        (, Action[] memory actions, address rootSafe) = runTask();
        addrRegistry = multisigTask.addrRegistry();
        multisigTask.processTaskActions(actions);

        // Get transaction data
        bytes memory dataToSign = _getTransactionDataToSign(actions, rootSafe);

        // Store system config addresses for later verification
        address systemConfigMode = toSuperchainAddrRegistry(addrRegistry).getAddress("SystemConfigProxy", 34443);
        address systemConfigMetal = toSuperchainAddrRegistry(addrRegistry).getAddress("SystemConfigProxy", 1750);

        // Revert to snapshot so that the safe is in the same state as before the task was run
        vm.revertToState(snapshotId);

        // Setup mock owners and signatures
        MultiSigOwner[] memory newOwners = _setupMockOwners();
        address safeAddress = _setGnosisSafeOwners(rootSafe, newOwners);
        bytes memory packedSignatures = _generateSignatures(safeAddress, dataToSign, newOwners);

        // Execute and verify
        _executeAndVerify(packedSignatures, systemConfigMode, systemConfigMetal, rootSafe);
    }

    function _getTransactionDataToSign(Action[] memory _actions, address _rootSafe)
        private
        view
        returns (bytes memory)
    {
        address[] memory allSafes = MultisigTaskTestHelper.getAllSafes(_rootSafe);
        uint256[] memory allOriginalNonces = MultisigTaskTestHelper.getAllOriginalNonces(allSafes);
        bytes[] memory allCalldatas = multisigTask.transactionDatas(_actions, allSafes, allOriginalNonces);
        TaskPayload memory payload =
            TaskPayload({safes: allSafes, calldatas: allCalldatas, originalNonces: allOriginalNonces});

        SafeData memory rootSafeData = Utils.getSafeData(payload, payload.safes.length - 1);
        rootSafeData.nonce = rootSafeData.nonce - 1; // The task has already run so we decrement the nonce by 1.

        return GnosisSafeHashes.getEncodedTransactionData(
            _rootSafe, rootSafeData.callData, 0, rootSafeData.nonce, MULTICALL3_ADDRESS
        );
    }

    function _setupMockOwners() private returns (MultiSigOwner[] memory newOwners) {
        uint256 ownersCount = 9;
        newOwners = new MultiSigOwner[](ownersCount);

        for (uint256 i = 0; i < ownersCount; i++) {
            // Dynamically create a label, e.g.: "Owner0", "Owner1", ...
            string memory label = string(abi.encodePacked("Owner", vm.toString(i)));
            (newOwners[i].walletAddress, newOwners[i].privateKey) = makeAddrAndKey(label);
            privateKeyForOwner[newOwners[i].walletAddress] = newOwners[i].privateKey;
        }
    }

    function _setGnosisSafeOwners(address _rootSafe, MultiSigOwner[] memory _newOwners) private returns (address) {
        // Gnosis safe SENTINEL_OWNER
        address currentOwner = address(0x1);

        // Set the new owners of the safe
        // Owners are stored in the form of a circular linked list using owners mapping in gnosis safe
        // Starting from sentinel owner and cycling back to it
        for (uint256 i = 0; i < _newOwners.length; i++) {
            bytes32 tmpSlot = keccak256(abi.encode(currentOwner, OWNER_MAPPING_STORAGE_OFFSET));
            vm.store(_rootSafe, tmpSlot, bytes32(uint256(uint160(_newOwners[i].walletAddress))));
            currentOwner = _newOwners[i].walletAddress;
        }

        // Link the last owner to the sentinel owner
        bytes32 slot = keccak256(abi.encode(currentOwner, OWNER_MAPPING_STORAGE_OFFSET));
        vm.store(_rootSafe, slot, bytes32(uint256(uint160(0x1))));

        // Set the owners count to 9
        vm.store(_rootSafe, bytes32(OWNER_COUNT_STORAGE_OFFSET), bytes32(uint256(9)));
        // Set the threshold to 4
        vm.store(_rootSafe, bytes32(THRESHOLD_STORAGE_OFFSET), bytes32(uint256(4)));

        return _rootSafe;
    }

    function _generateSignatures(address _safeAddress, bytes memory _dataToSign, MultiSigOwner[] memory _newOwners)
        private
        view
        returns (bytes memory)
    {
        address[] memory getNewOwners = IGnosisSafe(_safeAddress).getOwners();
        assertEq(getNewOwners.length, 9, "Expected 9 owners");

        for (uint256 i = 0; i < _newOwners.length; i++) {
            // Check that the new owners are set correctly
            assertEq(getNewOwners[i], _newOwners[i].walletAddress, "Expected owner");
        }

        uint256 threshold = IGnosisSafe(_safeAddress).getThreshold();
        assertEq(threshold, 4, "Expected threshold should be updated to mocked value");

        LibSort.sort(getNewOwners);

        // Sign the data to sign with the private keys of the new owners
        bytes memory packedSignatures;
        for (uint256 i = 0; i < threshold; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKeyForOwner[getNewOwners[i]], keccak256(_dataToSign));
            packedSignatures = bytes.concat(packedSignatures, abi.encodePacked(r, s, v));
        }

        return packedSignatures;
    }

    function _executeAndVerify(
        bytes memory _packedSignatures,
        address _systemConfigMode,
        address _systemConfigMetal,
        address _rootSafe
    ) private {
        // execute the task with the signatures
        multisigTask = new GasConfigTemplate();
        multisigTask.execute(taskConfigFilePath, _packedSignatures, new address[](0));

        // Check that the gas limits are set correctly after the task is executed
        SystemConfig systemConfig = SystemConfig(_systemConfigMode);
        assertEq(systemConfig.gasLimit(), 100000000, "l2 gas limit not set for Mode");
        systemConfig = SystemConfig(_systemConfigMetal);
        assertEq(systemConfig.gasLimit(), 100000000, "l2 gas limit not set for Metal");
        assertEq(multisigTask.isNestedSafe(_rootSafe), false, "Expected isNestedSafe to be false");
    }
}
