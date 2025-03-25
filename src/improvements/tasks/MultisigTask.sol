// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {Signatures} from "@base-contracts/script/universal/Signatures.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {SimpleAddressRegistry} from "src/improvements/SimpleAddressRegistry.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";
import {StateOverrideManager} from "src/improvements/tasks/StateOverrideManager.sol";
import {Base64} from "solady/utils/Base64.sol";

type AddressRegistry is address;

abstract contract MultisigTask is Test, Script, StateOverrideManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using AccountAccessParser for VmSafe.AccountAccess[];

    /// @notice nonce used for generating the safe transaction
    /// will be set to the value specified in the config file
    uint256 public nonce;

    /// @notice owners the safe started with
    address[] public startingOwners;

    /// @notice AddressesRegistry contract
    AddressRegistry public addrRegistry;

    /// @notice The address of the multisig for this task
    /// This state variable is always set in the `_taskSetup` function
    address public parentMultisig;

    /// @notice struct to store allowed storage accesses read in from config file
    EnumerableSet.AddressSet internal _allowedStorageAccesses;

    /// @notice Struct to store information about an action
    /// @param target The address of the target contract
    /// @param value The amount of ETH to send with the action
    /// @param arguments The calldata to send with the action
    /// @param callType The type of call to be made (e.g. "call", "delegatecall", "staticcall")
    /// @param description A description of the action
    struct Action {
        address target;
        uint256 value;
        bytes arguments;
        Enum.Operation operation;
        string description;
    }

    /// @notice Struct to store information about a token/Eth transfer
    /// @param to The address of the recipient
    /// @param value The amount of tokens/Eth to transfer
    /// @param tokenAddress The address of the token contract
    struct TransferInfo {
        address to;
        uint256 value;
        address tokenAddress;
    }

    /// @notice Struct to store information about a state change
    /// @param slot The storage slot that is being updated
    /// @param oldValue The old value of the storage slot
    /// @param newValue The new value of the storage slot
    struct StateInfo {
        bytes32 slot;
        bytes32 oldValue;
        bytes32 newValue;
    }

    /// @notice Enum to determine the type of task
    enum TaskType {
        L2TaskBase,
        SimpleBase
    }

    /// @notice transfers during task execution
    mapping(address => TransferInfo[]) private _taskTransfers;

    /// @notice state changes during task execution
    mapping(address => StateInfo[]) internal _stateInfos;

    /// @notice addresses involved in state changes or token transfers
    EnumerableSet.AddressSet private _taskTransferFromAddresses;

    /// @notice addresses whose state is updated in task execution
    EnumerableSet.AddressSet internal _taskStateChangeAddresses;

    /// @notice stores the gnosis safe accesses for the task
    VmSafe.StorageAccess[] internal _accountAccesses;

    /// @notice starting snapshot of the contract state before the calls are made
    uint256 internal _startSnapshot;

    /// @notice cached calldata of the parent multisig
    bytes parentCalldata;

    /// @notice Multicall3 call data struct
    /// @param target The address of the target contract
    /// @param allowFailure Flag to determine if the call should be allowed to fail
    /// @param value The amount of ETH to send with the call
    /// @param callData The calldata to send with the call
    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    /// @notice Task TOML config file values
    struct TaskConfig {
        string[] allowedStorageKeys;
        string safeAddressString;
    }

    /// @notice configuration set at initialization
    TaskConfig public config;

    /// @notice flag to determine if the task is being simulated
    uint256 private _buildStarted;

    /// @notice The address of the multicall target for this task
    address public multicallTarget;

    // ==================================================
    // ======== Virtual, Unimplemented Functions ========
    // ==================================================
    // These are functions have no default implementation and MUST be implemented by the inheriting contract.

    /// @notice Returns the type of task. L2TaskBase or SimpleBase.
    function taskType() public pure virtual returns (TaskType);

    /// @notice Specifies the safe address string to run the template from. This string refers
    /// to a named contract, where the name is read from an address registry contract.
    function safeAddressString() public pure virtual returns (string memory);

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their storage written to during the task.
    function _taskStorageWrites() internal view virtual returns (string[] memory);

    /// @notice By default, any value written to storage that looks like an address is expected to
    /// have code. Sometimes, accounts without code are expected, and this function allows you to
    /// specify a list of those addresses.
    function getCodeExceptions() internal view virtual returns (address[] memory);

    /// @notice Different tasks have different inputs. A task template will create the appropriate
    /// storage structures for storing and accessing these inputs. In this method, you read in the
    /// task config file, parse the inputs from the TOML as needed, and save them off.
    function _templateSetup(string memory taskConfigFilePath) internal virtual;

    /// @notice This method is responsible for deploying the required address registry, defining
    /// the parent multisig address, and setting the multicall target address.
    /// This method may also set any allowed and expected storage accesses that are expected in all
    /// use cases of the template.
    function _configureTask(string memory configPath)
        internal
        virtual
        returns (AddressRegistry, IGnosisSafe, address);

    /// @notice This is essentially a solidity script of the calls you want to make, and its
    /// contents are extracted into calldata for the task.
    function _build() internal virtual;

    /// @notice Called after the build function has been run, to execute assertions on the calls and
    /// state diffs. This function is how you obtain confidence the transaction does what it's supposed to do.
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions) internal view virtual;

    // =================================
    // ======== Other functions ========
    // =================================
    // TODO This section is not yet organized, this will happen in a future PR.

    /// @notice Runs the task with the given configuration file path.
    /// Sets the address registry, initializes and simulates the single multisig
    /// as well as the nested multisig. For single multisig,
    /// prints the data to sign and the hash to approve which is used to sign with the eip712sign binary.
    /// For nested multisig, prints the data to sign and the hash to approve for each of the child multisigs.
    /// @param taskConfigFilePath The path to the task configuration file.
    function simulateRun(string memory taskConfigFilePath, bytes memory signatures, address optionalChildMultisig)
        internal
        returns (VmSafe.AccountAccess[] memory, Action[] memory)
    {
        // sets safe to the safe specified by the current template from addresses.json
        _taskSetup(taskConfigFilePath);

        // Overrides only get applied when simulating
        _overrideState(taskConfigFilePath);

        // now execute task actions
        Action[] memory actions = build();
        VmSafe.AccountAccess[] memory accountAccesses = simulate(signatures, actions);
        validate(accountAccesses, actions);
        print(actions, accountAccesses, optionalChildMultisig, true);

        if (optionalChildMultisig != address(0)) {
            require(isNestedSafe(parentMultisig), "MultisigTask: multisig must be nested");
        }

        return (accountAccesses, actions);
    }

    /// @notice Runs the task with the given configuration file path.
    function simulateRun(string memory taskConfigFilePath, bytes memory signatures) public {
        simulateRun(taskConfigFilePath, signatures, address(0));
    }

    /// @notice Runs the task with the given configuration file path.
    /// Sets the address registry, initializes and simulates the single multisig
    /// as well as the nested multisig. For single multisig,
    /// prints the data to sign and the hash to approve which is used to sign with the eip712sign binary.
    /// For nested multisig, prints the data to sign and the hash to approve for each of the child multisigs.
    /// @param taskConfigFilePath The path to the task configuration file.
    function simulateRun(string memory taskConfigFilePath)
        public
        returns (VmSafe.AccountAccess[] memory, Action[] memory)
    {
        return simulateRun(taskConfigFilePath, "", address(0));
    }

    /// @notice Executes the task with the given configuration file path and signatures.
    /// Sets the address registry, initializes and executes the task the single multisig
    /// as well as the nested multisig.
    /// @param taskConfigFilePath The path to the task configuration file.
    /// @param signatures The signatures to execute the task.
    function executeRun(string memory taskConfigFilePath, bytes memory signatures)
        public
        returns (VmSafe.AccountAccess[] memory)
    {
        // sets safe to the safe specified by the current template from addresses.json
        _taskSetup(taskConfigFilePath);

        // gather mutative calls
        Action[] memory actions = build();

        // now execute task actions
        VmSafe.AccountAccess[] memory accountAccesses = execute(signatures, actions);

        // validate all state transitions
        validate(accountAccesses, actions);

        // print out results of execution
        print(actions, accountAccesses, address(0), false);

        return accountAccesses;
    }

    /// @notice Child multisig of a nested multisig approves the task to be executed with the given
    /// configuration file path and signatures.
    /// @param taskConfigFilePath The path to the task configuration file.
    /// @param _childMultisig The address of the child multisig that is approving the task.
    /// @param signatures The signatures to approve the task transaction hash.
    function approveFromChildMultisig(string memory taskConfigFilePath, address _childMultisig, bytes memory signatures)
        public
    {
        _taskSetup(taskConfigFilePath);
        Action[] memory actions = build();
        approve(_childMultisig, signatures, actions);
        console.log(
            "--------- Successfully %s Child Multisig %s Approval ---------",
            isBroadcastContext() ? "Broadcasted" : "Simulated",
            _childMultisig
        );
    }

    /// @notice Simulates a nested multisig task with the given configuration file path for a
    /// given child multisig. Prints the data to sign and the hash to approve corresponding to
    /// the _childMultisig, printed data to sign is used to sign with the eip712sign binary.
    function signFromChildMultisig(string memory taskConfigFilePath, address _childMultisig)
        public
        returns (VmSafe.AccountAccess[] memory, Action[] memory)
    {
        return simulateRun(taskConfigFilePath, "", _childMultisig);
    }

    /// @notice Sets the address registry, initializes the task.
    /// @param taskConfigFilePath The path to the task configuration file.
    function _taskSetup(string memory taskConfigFilePath) internal {
        require(bytes(config.safeAddressString).length == 0, "MultisigTask: already initialized");
        config.safeAddressString = safeAddressString();
        IGnosisSafe _parentMultisig; // TODO parentMultisig should be of type IGnosisSafe
        (addrRegistry, _parentMultisig, multicallTarget) = _configureTask(taskConfigFilePath);

        parentMultisig = address(_parentMultisig);

        config.allowedStorageKeys = _taskStorageWrites();
        config.allowedStorageKeys.push(safeAddressString());

        _templateSetup(taskConfigFilePath);
        nonce = IGnosisSafe(parentMultisig).nonce(); // Maybe be overridden later by state overrides

        startingOwners = IGnosisSafe(parentMultisig).getOwners();

        vm.label(AddressRegistry.unwrap(addrRegistry), "AddrRegistry");
        vm.label(address(this), "MultisigTask");
    }

    /// @notice Get the calldata to be executed by safe.
    /// Callable only after the build function has been run and the
    /// calldata has been loaded up to storage.
    function getMulticall3Calldata(Action[] memory actions) public view virtual returns (bytes memory data) {
        (address[] memory targets, uint256[] memory values, bytes[] memory arguments) = processTaskActions(actions);

        // Create calls array with targets and arguments.
        Call3Value[] memory calls = new Call3Value[](targets.length);

        for (uint256 i; i < calls.length; i++) {
            require(targets[i] != address(0), "Invalid target for multisig");
            calls[i] = Call3Value({target: targets[i], allowFailure: false, value: values[i], callData: arguments[i]});
        }

        // Generate calldata
        data = abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
    }

    /// @notice Print the data to sign.
    function printEncodedTransactionData(bytes memory dataToSign) public pure {
        // logs required for using eip712sign binary to sign the data to sign with Ledger
        console.log("\nData to sign:");
        console.log("vvvvvvvv");
        console.logBytes(dataToSign);
        console.log("^^^^^^^^\n");

        console.log("########## IMPORTANT ##########");
        console.log("Please make sure that the 'Data to sign' displayed above matches:");
        console.log("1. What you see in the Tenderly simulation.");
        console.log("2. What you see in your hardware wallet.");
        console.log("This is a critical step that must not be skipped.");
        console.log("###############################");
    }

    /// @notice print the hash to approve by EOA for parent/root multisig
    function printParentHash(bytes memory callData) public view {
        console.logBytes32(getHash(callData, parentMultisig));

        bytes memory encodedTxData = getEncodedTransactionData(parentMultisig, callData);
        bytes32 safeTxHash;
        assembly {
            // 66 bytes = (bytes1(0x19), bytes1(0x01), bytes32(domainSeparator()), bytes32(safeTxHash))
            // Retrieve the last 32 bytes of encodedTxData (safeTxHash).
            // Memory layout of encodedTxData:
            // - The first 32 bytes store the length (66 bytes in this case).
            // - The actual data starts at encodedTxData + 32.
            // - The last 32 bytes of the data (safeTxHash) start at:
            //   encodedTxData + 32 + (66 - 32) = encodedTxData + 66.
            safeTxHash := mload(add(encodedTxData, mload(encodedTxData)))
        }

        bytes32 domainSeparator = GnosisSafeHashes.calculateDomainSeparator(block.chainid, parentMultisig);
        console.log("Domain Hash:    ", vm.toString(domainSeparator));
        console.log("Message Hash:   ", vm.toString(safeTxHash));

        printOPTxVerifyLink(parentMultisig, callData);
    }

    /// @notice This function prints a op-txverify link which can be used for verifying the authenticity of the domain and message hashes
    function printOPTxVerifyLink(address safe, bytes memory callData) private view {
        uint256 childNonce = _getNonce(safe);
        uint256 parentNonce = _getNonce(parentMultisig);
        bool isNested = isNestedSafe(parentMultisig);

        string memory json = string.concat(
            '{\n   "safe": "',
            vm.toString(parentMultisig),
            '",\n   "chain": ',
            vm.toString(block.chainid),
            ',\n   "to": "',
            vm.toString(_getMulticallAddress(parentMultisig)),
            '",\n   "value": ',
            vm.toString(uint256(0)),
            ',\n   "data": "',
            vm.toString(parentCalldata)
        );

        json = string.concat(
            json,
            '",\n   "operation": ',
            vm.toString(uint8(Enum.Operation.DelegateCall)),
            ',\n   "safe_tx_gas": ',
            vm.toString(uint256(0)),
            ',\n   "base_gas": ',
            vm.toString(uint256(0)),
            ',\n   "gas_price": ',
            vm.toString(uint256(0)),
            ',\n   "gas_token": "',
            vm.toString(address(0)),
            '",\n   "refund_receiver": "',
            vm.toString(address(0))
        );

        json = string.concat(
            json,
            '",\n   "nonce": ',
            vm.toString(parentNonce),
            isNested
                ? string.concat(
                    ',\n   "nested": ',
                    '{\n    "safe": "',
                    vm.toString(safe),
                    '",\n    "nonce": ',
                    vm.toString(childNonce),
                    ',\n    "operation": ',
                    vm.toString(uint8(Enum.Operation.DelegateCall)),
                    ',\n    "data": "',
                    vm.toString(callData),
                    '",\n    "to": "',
                    vm.toString(_getMulticallAddress(safe)),
                    '"\n   }'
                )
                : "",
            "\n}"
        );

        string memory base64Json = Base64.encode(bytes(json));
        console.log(
            "\nTo verify this transaction, run `op-verify qr` on your machine, then open the following link on your mobile device: https://op-verify.optimism.io/?tx=%s",
            base64Json
        );
    }

    function _getNonce(address safe) internal view returns (uint256) {
        return (safe == parentMultisig) ? nonce : IGnosisSafe(safe).nonce();
    }

    /// @notice get the data to sign by EOA
    /// @param safe The address of the safe
    /// @param data The calldata to be executed
    function getEncodedTransactionData(address safe, bytes memory data)
        public
        view
        returns (bytes memory encodedTxData)
    {
        encodedTxData = IGnosisSafe(safe).encodeTransactionData({
            to: _getMulticallAddress(safe),
            value: 0,
            data: data,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: _getNonce(safe)
        });
        require(encodedTxData.length == 66, "MultisigTask: encodedTxData length is not 66 bytes.");
    }

    /// @notice simulate the task by approving from owners and then executing
    function simulate(bytes memory _signatures, Action[] memory actions)
        public
        returns (VmSafe.AccountAccess[] memory)
    {
        bytes memory callData = getMulticall3Calldata(actions);
        bytes32 hash = getHash(callData, parentMultisig);
        bytes memory signatures;

        // Approve the hash from each owner
        address[] memory owners = IGnosisSafe(parentMultisig).getOwners();
        if (_signatures.length == 0) {
            for (uint256 i = 0; i < owners.length; i++) {
                vm.prank(owners[i]);
                IGnosisSafe(parentMultisig).approveHash(hash);
            }
            // gather signatures after approval hashes have been made
            signatures = prepareSignatures(parentMultisig, hash);
        } else {
            signatures = Signatures.prepareSignatures(parentMultisig, hash, _signatures);
        }

        bytes32 txHash = IGnosisSafe(parentMultisig).getTransactionHash(
            multicallTarget, 0, callData, Enum.Operation.DelegateCall, 0, 0, 0, address(0), payable(address(0)), nonce
        );

        require(hash == txHash, "MultisigTask: hash mismatch");

        vm.startStateDiffRecording();

        // Execute the transaction
        parentCalldata = callData;
        execTransaction(parentMultisig, multicallTarget, 0, callData, Enum.Operation.DelegateCall, signatures);
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();
        return accountAccesses;
    }

    /// @notice child multisig approves the task to be executed.
    /// @param _childMultisig The address of the child multisig that is approving the task.
    /// @param signatures The signatures to approve the task transaction hash.
    function approve(address _childMultisig, bytes memory signatures, Action[] memory actions) public {
        bytes memory approveCalldata = generateApproveMulticallData(actions);
        bytes32 hash = keccak256(getEncodedTransactionData(_childMultisig, approveCalldata));
        signatures = Signatures.prepareSignatures(_childMultisig, hash, signatures);

        execTransaction(_childMultisig, MULTICALL3_ADDRESS, 0, approveCalldata, Enum.Operation.DelegateCall, signatures);
    }

    /// @notice Executes the task with the given signatures.
    /// @param signatures The signatures to execute the task.
    function execute(bytes memory signatures, Action[] memory actions) public returns (VmSafe.AccountAccess[] memory) {
        bytes memory callData = getMulticall3Calldata(actions);
        bytes32 hash = getHash(callData, parentMultisig);

        if (signatures.length == 0) {
            // if no signatures are attached, this means we are dealing with a
            // nested safe that should already have all of its approve hashes in
            // child multisigs signed already.
            signatures = prepareSignatures(parentMultisig, hash);
        } else {
            // otherwise, if signatures are attached, this means EOA's have
            // signed, so we order the signatures based on how Gnosis Safe
            // expects signatures to be ordered by address cast to a number
            signatures = Signatures.sortUniqueSignatures(
                parentMultisig, signatures, hash, IGnosisSafe(parentMultisig).getThreshold(), signatures.length
            );
        }

        vm.startStateDiffRecording();

        execTransaction(parentMultisig, multicallTarget, 0, callData, Enum.Operation.DelegateCall, signatures);

        return vm.stopAndReturnStateDiff();
    }

    /// @notice helper function that returns whether or not the current context
    /// is a broadcast context
    function isBroadcastContext() internal view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptBroadcast) || vm.isContext(VmSafe.ForgeContext.ScriptResume);
    }

    /// @notice Executes a transaction to the target multisig.
    function execTransaction(
        address multisig,
        address target,
        uint256 value,
        bytes memory data,
        Enum.Operation operationType,
        bytes memory signatures
    ) internal {
        if (isBroadcastContext()) {
            vm.broadcast();
        }

        bytes memory callData = abi.encodeWithSelector(
            IGnosisSafe.execTransaction.selector,
            target,
            value,
            data,
            operationType,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            signatures
        );

        // Use the TENDERLY_GAS environment variable to set a specific gas limit, if provided.
        // Otherwise, default to the remaining gas. This helps surface out-of-gas errors earlier,
        // before they would show up in Tenderly's simulation results.
        uint256 gas = vm.envOr("TENDERLY_GAS", gasleft());
        console.log("Passing %s gas to execTransaction (from env or gasleft)", gas);
        (bool success, bytes memory returnData) = multisig.call{gas: gas}(callData);

        if (!success) {
            console.log("Error executing multisig transaction");
            console.logBytes(returnData);
        }

        require(success, "MultisigTask: execute failed");
    }

    /// @notice returns the allowed storage accesses
    /// @return _allowedStorageAccesses The allowed storage accesses
    function getAllowedStorageAccess() public view returns (address[] memory) {
        return _allowedStorageAccesses.values();
    }

    /// @notice execute post-task checks.
    ///          e.g. read state variables of the deployed contracts to make
    ///          sure they are deployed and initialized correctly, or read
    ///          states that are expected to have changed during the simulate step.
    function validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions) public virtual {
        // write all state changes to storage
        _processStateDiffChanges(accountAccesses);

        address[] memory accountsWithWrites = accountAccesses.getUniqueWrites(false);
        // By default, we allow storage accesses to newly created contracts.
        address[] memory newContracts = accountAccesses.getNewContracts();

        for (uint256 i; i < accountsWithWrites.length; i++) {
            address addr = accountsWithWrites[i];
            require(
                _allowedStorageAccesses.contains(addr) || _isNewContract(addr, newContracts),
                string(
                    abi.encodePacked(
                        "MultisigTask: address ", getAddressLabel(addr), " not in allowed storage accesses"
                    )
                )
            );
        }

        require(IGnosisSafe(parentMultisig).nonce() == nonce + 1, "MultisigTask: nonce not incremented");

        _validate(accountAccesses, actions);

        // check that state diff is as expected
        checkStateDiff(accountAccesses);
    }

    /// @notice get task actions
    /// @return targets The targets of the actions
    /// @return values The values of the actions
    /// @return arguments The arguments of the actions
    function processTaskActions(Action[] memory actions)
        public
        pure
        returns (address[] memory targets, uint256[] memory values, bytes[] memory arguments)
    {
        uint256 actionsLength = actions.length;
        require(actionsLength > 0, "No actions found");

        targets = new address[](actionsLength);
        values = new uint256[](actionsLength);
        arguments = new bytes[](actionsLength);

        for (uint256 i; i < actionsLength; i++) {
            require(actions[i].target != address(0), "Invalid target for task");
            // if there are no args and no eth, the action is not valid
            require(
                (actions[i].arguments.length == 0 && actions[i].value > 0) || actions[i].arguments.length > 0,
                "Invalid arguments for task"
            );
            targets[i] = actions[i].target;
            arguments[i] = actions[i].arguments;
            values[i] = actions[i].value;
        }
    }

    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------
    /// --------------------------- Public functions -----------------------
    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------

    /// @notice build the task actions for all l2chains in the task
    /// @dev contract calls must be perfomed in plain solidity.
    ///      overriden requires using buildModifier modifier to leverage
    ///      foundry snapshot and state diff recording to populate the actions array.
    function build() public returns (Action[] memory actions) {
        require(parentMultisig != address(0), "Must set address registry for multisig address to be set");

        require(_buildStarted == uint256(0), "Build already started");
        _buildStarted = 1;

        _startBuild();
        _build();
        actions = _endBuild();

        _buildStarted = 0;

        return actions;
    }

    /// @notice print task description, actions, transfers, state changes and EOAs datas to sign
    function print(
        Action[] memory actions,
        VmSafe.AccountAccess[] memory accountAccesses,
        address optionalChildMultisig,
        bool isSimulate
    ) public view {
        console.log("\n------------------ Task Actions ------------------");
        for (uint256 i; i < actions.length; i++) {
            console.log("%d). %s", i + 1, actions[i].description);
            console.log("target: %s\npayload", getAddressLabel(actions[i].target));
            console.logBytes(actions[i].arguments);
            console.log("\n");
        }

        accountAccesses.decodeAndPrint();

        printSafe(actions, optionalChildMultisig, isSimulate);
    }

    /// @notice Prints all relevant hashes to sign as well as the tenderly simulation link.
    function printSafe(Action[] memory actions, address optionalChildMultisig, bool isSimulate) private view {
        // Print calldata to be executed within the Safe.
        console.log("\n\n------------------ Task Calldata ------------------");
        console.logBytes(getMulticall3Calldata(actions));

        // Only print data if the task is being simulated.
        if (isSimulate) {
            if (isNestedSafe(parentMultisig)) {
                printNestedData(actions, optionalChildMultisig);
            } else {
                printSingleData(actions);
            }

            console.log("\n\n------------------ Tenderly Simulation Data ------------------");
            printTenderlySimulationData(actions, optionalChildMultisig);
        }
    }

    /// @notice Helper function to print nested calldata.
    function printNestedData(Action[] memory actions, address childMultisig) private view {
        require(
            childMultisig != address(0),
            "MultisigTask: Child multisig cannot be zero address when printing nested data to sign."
        );
        (, bytes memory dataToSign, bytes32 domainSeparator, bytes32 messageHash) =
            getApproveTransactionInfo(actions, childMultisig);

        console.log("\n\n------------------ Nested Multisig Child's Hash to Approve ------------------");
        console.log("Parent multisig: %s", getAddressLabel(parentMultisig));
        console.log("Parent hashToApprove: %s", vm.toString(getHash(parentCalldata, parentMultisig)));
        console.log("\n\n------------------ Nested Multisig EOAs Data to Sign ------------------");
        printEncodedTransactionData(dataToSign);
        console.log("\n\n------------------ Nested Multisig EOAs Hash to Approve ------------------");
        printChildHash(childMultisig, domainSeparator, messageHash);
        printOPTxVerifyLink(childMultisig, generateApproveMulticallData(actions));
    }

    /// @notice Helper function to print non-nested safe calldata.
    function printSingleData(Action[] memory actions) private view {
        console.log("\n\n------------------ Single Multisig EOA Data to Sign ------------------");
        bytes memory dataToSign = getEncodedTransactionData(parentMultisig, getMulticall3Calldata(actions));
        printEncodedTransactionData(dataToSign);
        console.log("\n\n------------------ Single Multisig EOA Hash to Approve ------------------");
        printParentHash(getMulticall3Calldata(actions));
    }

    /// @notice Print the hash to approve by EOA for nested multisig.
    function printChildHash(address childMultisig, bytes32 domainSeparator, bytes32 messageHash) public view {
        require(
            childMultisig != address(0), "MultisigTask: Child multisig cannot be zero address when printing child hash."
        );
        console.log("Child multisig: %s", getAddressLabel(childMultisig));
        console.log("Domain Hash:    ", vm.toString(domainSeparator));
        console.log("Message Hash:   ", vm.toString(messageHash));
    }

    /// @notice print the tenderly simulation payload with the state overrides
    function printTenderlySimulationData(Action[] memory actions, address optionalChildMultisig) internal view {
        // TODO: Support child nonce as a state override. Right now we always get the latest nonce.
        // Use the max uint256 to indicate that the child multisig nonce is not provided (zero is a valid nonce).
        uint256 childMultisigNonce =
            optionalChildMultisig != address(0) ? _getNonce(optionalChildMultisig) : type(uint256).max;
        Simulation.StateOverride[] memory allStateOverrides =
            getStateOverrides(parentMultisig, _getNonce(parentMultisig), optionalChildMultisig, childMultisigNonce);

        if (optionalChildMultisig != address(0)) {
            bytes memory finalExec = getNestedSimulationMulticall3Calldata(actions, optionalChildMultisig);

            console.log("\nSimulation link:");
            Simulation.logSimulationLink({
                _to: MULTICALL3_ADDRESS,
                _data: finalExec,
                _from: msg.sender,
                _overrides: allStateOverrides
            });
        } else {
            bytes memory finalExec = _execTransactionCalldata(
                parentMultisig,
                getMulticall3Calldata(actions),
                Signatures.genPrevalidatedSignature(msg.sender),
                _getMulticallAddress(parentMultisig)
            );

            // Log the simulation link
            console.log("\nSimulation link:");
            Simulation.logSimulationLink({
                _to: parentMultisig,
                _data: finalExec,
                _from: msg.sender,
                _overrides: allStateOverrides
            });
        }
    }

    /// @notice Log a JSON payload to create a Tenderly simulation.
    /// Logging this data to the terminal is important for a separate process that performs Tenderly verifications.
    function logTenderlySimulationPayload(
        bytes memory txData,
        Simulation.StateOverride[] memory stateOverrides,
        address to
    ) internal view {
        require(stateOverrides.length > 0, "MultisigTask: stateOverrides length must be greater than 0");

        console.log("\nSimulation payload:");
        // forgefmt: disable-start
        string memory payload = string.concat(
            '{\"network_id\":\"', vm.toString(block.chainid),'\",',
            '\"from\":\"', vm.toString(msg.sender),'\",',
            '\"to\":\"', vm.toString(to), '\",',
            '\"save\":true,',
            '\"input\":\"', vm.toString(txData),'\",',
            '\"value\":\"0x0\",',
            '\"state_objects\":{'
        );
        // forgefmt: disable-end

        for (uint256 i = 0; i < stateOverrides.length && i < 2; i++) {
            if (i > 0) payload = string.concat(payload, ",");
            payload = string.concat(payload, tenderlyPayloadStateOverride(stateOverrides[i]));
        }

        payload = string.concat(payload, "}}");
        console.log(payload);
    }

    /// @notice Helper function to format the state overrides for Tenderly.
    function tenderlyPayloadStateOverride(Simulation.StateOverride memory stateOverride)
        internal
        pure
        returns (string memory)
    {
        // forgefmt: disable-start
        string memory result = string.concat(
            '\"', vm.toString(stateOverride.contractAddress), '\":{\"storage\":{'
        );

        for (uint256 j = 0; j < stateOverride.overrides.length; j++) {
            if (j > 0) result = string.concat(result, ',');
            result = string.concat(
                result,
                '\"', vm.toString(bytes32(stateOverride.overrides[j].key)), '\":\"',
                vm.toString(stateOverride.overrides[j].value), '\"'
            );
        }
        // forgefmt: disable-end

        return string.concat(result, "}}");
    }

    /// @notice get the hash for this safe transaction
    function getHash(bytes memory callData, address safe) public view returns (bytes32) {
        return keccak256(getEncodedTransactionData(safe, callData));
    }

    /// @notice Helper function to generate the approveHash calldata to be executed by child multisig owner on parent multisig.
    function generateApproveMulticallData(Action[] memory actions) public view returns (bytes memory) {
        bytes memory callData = getMulticall3Calldata(actions);
        bytes32 hash = getHash(callData, parentMultisig);
        Call3Value memory call = Call3Value({
            target: parentMultisig,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe(parentMultisig).approveHash, (hash))
        });

        Call3Value[] memory calls = new Call3Value[](1);
        calls[0] = call;
        return abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
    }

    /// @notice helper method to get labels for addresses
    function getAddressLabel(address contractAddress) public view returns (string memory) {
        string memory label = vm.getLabel(contractAddress);

        bytes memory prefix = bytes("unlabeled:");
        bytes memory strBytes = bytes(label);

        if (strBytes.length >= prefix.length) {
            // check if address is unlabeled
            for (uint256 i = 0; i < prefix.length; i++) {
                if (strBytes[i] != prefix[i]) {
                    // return "{LABEL} @{ADDRESS}" if address is labeled
                    return string(abi.encodePacked(label, " @", vm.toString(contractAddress)));
                }
            }
        } else {
            // return "{LABEL} @{ADDRESS}" if address is labeled
            return string(abi.encodePacked(label, " @", vm.toString(contractAddress)));
        }

        // return "UNLABELED @{ADDRESS}" if address is unlabeled
        return string(abi.encodePacked("UNLABELED @", vm.toString(contractAddress)));
    }

    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------
    /// ------------------------- Internal functions -----------------------
    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------

    /// @notice validate actions inclusion
    /// default implementation check for duplicate actions
    function validateAction(address target, uint256 value, bytes memory data, Action[] memory actions) public pure {
        uint256 actionsLength = actions.length;
        for (uint256 i = 0; i < actionsLength; i++) {
            // Check if the target, arguments and value matches with other existing actions.
            bool isDuplicateTarget = actions[i].target == target;
            bool isDuplicateArguments = keccak256(actions[i].arguments) == keccak256(data);
            bool isDuplicateValue = actions[i].value == value;

            require(!(isDuplicateTarget && isDuplicateArguments && isDuplicateValue), "Duplicated action found");
        }
    }

    function isNestedSafe(address safe) public view returns (bool) {
        // assume safe is nested unless there is an EOA owner
        bool nested = true;

        address[] memory owners = IGnosisSafe(safe).getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i].code.length == 0) {
                nested = false;
            }
        }
        return nested;
    }

    /// @notice helper function to prepare the signatures to be executed
    /// @param _safe The address of the parent multisig
    /// @param hash The hash to be approved
    /// @return The signatures to be executed
    function prepareSignatures(address _safe, bytes32 hash) internal view returns (bytes memory) {
        // prepend the prevalidated signatures to the signatures
        address[] memory approvers = Signatures.getApprovers(_safe, hash);
        return Signatures.genPrevalidatedSignatures(approvers);
    }

    function _execTransactionCalldata(
        address _safe,
        bytes memory _data,
        bytes memory _signatures,
        address _multicallTarget
    ) internal pure returns (bytes memory) {
        return abi.encodeCall(
            IGnosisSafe(_safe).execTransaction,
            (
                _multicallTarget,
                0,
                _data,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                _signatures
            )
        );
    }

    /// @notice Get the multicall address for the given safe.
    /// Override to return required multicall address.
    function _getMulticallAddress(address safe) internal view virtual returns (address) {
        // Some child contracts may override this function and return a different multicall address
        // based on the safe address (e.g. whether it's the parent or child multisig).
        require(safe != address(0), "Safe address cannot be zero address");
        return multicallTarget;
    }

    /// @notice To show the full transaction trace in Tenderly, we build custom calldata
    /// that shows both the child multisig approving the hash, as well as the parent multisig
    /// executing the task. This is only used when simulating a nested multisig.
    function getNestedSimulationMulticall3Calldata(Action[] memory actions, address childMultisig)
        internal
        view
        virtual
        returns (bytes memory data)
    {
        Call3Value[] memory calls = new Call3Value[](2);

        (bytes memory approveHashCallData,,,) = getApproveTransactionInfo(actions, childMultisig);
        bytes memory approveHashExec = _execTransactionCalldata(
            childMultisig,
            approveHashCallData,
            Signatures.genPrevalidatedSignature(MULTICALL3_ADDRESS),
            MULTICALL3_ADDRESS
        );
        calls[0] = Call3Value({target: childMultisig, allowFailure: false, value: 0, callData: approveHashExec});

        bytes memory customExec = _execTransactionCalldata(
            parentMultisig,
            getMulticall3Calldata(actions),
            Signatures.genPrevalidatedSignature(childMultisig),
            _getMulticallAddress(parentMultisig)
        );
        calls[1] = Call3Value({target: parentMultisig, allowFailure: false, value: 0, callData: customExec});

        return abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
    }

    /// @notice Helper function to get the approve transaction info.
    function getApproveTransactionInfo(Action[] memory actions, address childMultisig)
        internal
        view
        returns (bytes memory callData, bytes memory encodedTxData, bytes32 domainSeparator, bytes32 messageHash)
    {
        callData = generateApproveMulticallData(actions);
        encodedTxData = getEncodedTransactionData(childMultisig, callData);
        messageHash = GnosisSafeHashes.getMessageHashFromEncodedTransactionData(encodedTxData);
        domainSeparator = GnosisSafeHashes.calculateDomainSeparator(block.chainid, childMultisig);
        return (callData, encodedTxData, domainSeparator, messageHash);
    }

    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------
    /// ------------------------- Private functions ------------------------
    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------

    /// @notice to be used by the build function to capture the state changes applied by a given task.
    /// These state changes will inform whether or not the task will be executed onchain.
    /// steps:
    ///  1). take a snapshot of the current state of the contract
    ///  2). start prank as the multisig
    ///  3). start a recording of all calls created during the task
    function _startBuild() private {
        vm.startPrank(parentMultisig);

        _startSnapshot = vm.snapshotState();

        vm.startStateDiffRecording();
    }

    /// @notice to be used at the end of the build function to snapshot
    /// the actions performed by the task and revert these changes
    /// then, stop the prank and record the state diffs and actions that
    /// were taken by the task.
    function _endBuild() private returns (Action[] memory) {
        VmSafe.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        vm.stopPrank();

        // Roll back state changes.
        require(
            vm.revertToState(_startSnapshot),
            "MultisigTask: failed to revert back to snapshot, unsafe state to run task"
        );
        require(accesses.length > 0, "MultisigTask: no account accesses found");

        // get the minimum depth of the calls, we only care about the top level calls
        // this is to avoid counting subcalls as actions.
        // the account accesses are in order of the calls, so the first one is always the top level call
        uint256 topLevelDepth = accesses[0].depth;

        // First pass: count valid actions.
        uint256 validCount = 0;
        for (uint256 i = 0; i < accesses.length; i++) {
            // Record storage accesses if applicable.
            for (uint256 j = 0; j < accesses[i].storageAccesses.length; j++) {
                if (accesses[i].account == parentMultisig && accesses[i].storageAccesses[j].isWrite) {
                    _accountAccesses.push(accesses[i].storageAccesses[j]);
                }
            }
            if (_isValidAction(accesses[i], topLevelDepth)) {
                validCount++;
            }
        }

        // Allocate a memory array with exactly enough room.
        Action[] memory validActions = new Action[](validCount);
        uint256 index = 0;
        for (uint256 i = 0; i < accesses.length; i++) {
            if (_isValidAction(accesses[i], topLevelDepth)) {
                // Ensure action uniqueness.
                validateAction(accesses[i].account, accesses[i].value, accesses[i].data, validActions);

                (string memory opStr, Enum.Operation op) = _getOperationDetails(accesses[i].kind);
                string memory desc = _composeDescription(accesses[i], opStr);

                validActions[index] = Action({
                    value: accesses[i].value,
                    target: accesses[i].account,
                    arguments: accesses[i].data,
                    operation: op,
                    description: desc
                });
                index++;
            }
        }

        return validActions;
    }

    /// @notice Override the state of the task. Function is called only when simulating.
    function _overrideState(string memory taskConfigFilePath) private {
        _applyStateOverrides(taskConfigFilePath);
        nonce = _getNonceOrOverride(address(parentMultisig));
    }

    function _isNewContract(address addr, address[] memory newContracts) private pure returns (bool isNewContract_) {
        isNewContract_ = false;
        for (uint256 j; j < newContracts.length; j++) {
            if (newContracts[j] == addr) {
                isNewContract_ = true;
                break;
            }
        }
    }

    /// @dev Returns true if the given account access should be recorded as an action.
    function _isValidAction(VmSafe.AccountAccess memory access, uint256 topLevelDepth) internal view returns (bool) {
        bool accountNotRegistryOrVm =
            (access.account != AddressRegistry.unwrap(addrRegistry) && access.account != address(vm));
        bool accessorNotRegistry = access.accessor != AddressRegistry.unwrap(addrRegistry);
        bool isCall = access.kind == VmSafe.AccountAccessKind.Call;
        bool isTopLevelDelegateCall =
            (access.kind == VmSafe.AccountAccessKind.DelegateCall && access.depth == topLevelDepth);
        bool accessorIsParent = (access.accessor == parentMultisig);
        return accountNotRegistryOrVm && accessorNotRegistry && (isCall || isTopLevelDelegateCall) && accessorIsParent;
    }

    /// @dev Composes a description string for the given access using the provided operation string.
    function _composeDescription(VmSafe.AccountAccess memory access, string memory opStr)
        internal
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                opStr,
                " ",
                getAddressLabel(access.account),
                " with ",
                vm.toString(access.value),
                " eth and ",
                vm.toString(access.data),
                " data."
            )
        );
    }

    function _getOperationDetails(VmSafe.AccountAccessKind kind)
        private
        pure
        returns (string memory opStr, Enum.Operation op)
    {
        if (kind == VmSafe.AccountAccessKind.Call) {
            opStr = "Call";
            op = Enum.Operation.Call;
        } else if (kind == VmSafe.AccountAccessKind.DelegateCall) {
            opStr = "DelegateCall";
            op = Enum.Operation.DelegateCall;
        } else {
            revert("Unknown account access kind");
        }
    }

    /// @notice helper function that can be overridden by template contracts to
    /// check the state changes applied by the task. This function can check
    /// that only the nonce changed in the parent multisig when executing a task
    /// by checking the slot and address where the slot changed.
    function checkStateDiff(VmSafe.AccountAccess[] memory accountAccesses) internal view {
        console.log("Running assertions on the state diff");
        require(accountAccesses.length > 0, "No account accesses");
        address[] memory allowedAccesses = getAllowedStorageAccess();
        address[] memory newContracts = accountAccesses.getNewContracts();
        for (uint256 i; i < accountAccesses.length; i++) {
            VmSafe.AccountAccess memory accountAccess = accountAccesses[i];
            // All touched accounts should have code, with the exception of precompiles.
            bool isPrecompile = accountAccess.account >= address(0x1) && accountAccess.account <= address(0xa);
            if (!isPrecompile) {
                require(
                    accountAccess.account.code.length != 0,
                    string.concat("Account has no code: ", vm.toString(accountAccess.account))
                );
            }
            require(
                accountAccess.oldBalance == accountAccess.newBalance,
                string.concat("Unexpected balance change: ", vm.toString(accountAccess.account))
            );
            require(
                accountAccess.kind != VmSafe.AccountAccessKind.SelfDestruct,
                string.concat("Self-destructed account: ", vm.toString(accountAccess.account))
            );
            for (uint256 j; j < accountAccess.storageAccesses.length; j++) {
                VmSafe.StorageAccess memory storageAccess = accountAccess.storageAccesses[j];
                if (!storageAccess.isWrite) continue; // Skip SLOADs.
                uint256 value = uint256(storageAccess.newValue);
                address account = storageAccess.account;
                if (isLikelyAddressThatShouldHaveCode(value)) {
                    // Log account, slot, and value if there is no code.
                    string memory err = string.concat(
                        "Likely address in storage has no code\n",
                        "  account: ",
                        vm.toString(account),
                        "\n  slot:    ",
                        vm.toString(storageAccess.slot),
                        "\n  value:   ",
                        vm.toString(bytes32(value))
                    );
                    require(address(uint160(value)).code.length != 0, err);
                } else {
                    // Log account, slot, and value if there is code.
                    string memory err = string.concat(
                        "Likely address in storage has unexpected code\n",
                        "  account: ",
                        vm.toString(account),
                        "\n  slot:    ",
                        vm.toString(storageAccess.slot),
                        "\n  value:   ",
                        vm.toString(bytes32(value))
                    );
                    require(address(uint160(value)).code.length == 0, err);
                }
                require(account.code.length != 0, string.concat("Storage account has no code: ", vm.toString(account)));
                require(!storageAccess.reverted, string.concat("Storage access reverted: ", vm.toString(account)));
                bool allowed;
                for (uint256 k; k < allowedAccesses.length; k++) {
                    allowed = allowed || (account == allowedAccesses[k]) || _isNewContract(account, newContracts);
                }
                require(allowed, string.concat("Unallowed Storage access: ", vm.toString(account)));
            }
        }
    }

    /// @notice helper method to get transfers and state changes of task affected addresses
    function _processStateDiffChanges(VmSafe.AccountAccess[] memory accountAccesses) private {
        for (uint256 i = 0; i < accountAccesses.length; i++) {
            // TODO Once `validate` is updated to use `accountAccesses` instead of
            // `_taskStateChangeAddresses`, we can delete the  `_processStateDiffChanges`
            // and `_processStateChanges` methods.
            _processStateChanges(accountAccesses[i].storageAccesses);
        }
    }

    /// @notice helper method to get state changes of task affected addresses
    function _processStateChanges(VmSafe.StorageAccess[] memory storageAccess) private {
        for (uint256 i; i < storageAccess.length; i++) {
            address account = storageAccess[i].account;

            // get only state changes for write storage access
            if (storageAccess[i].isWrite) {
                _stateInfos[account].push(
                    StateInfo({
                        slot: storageAccess[i].slot,
                        oldValue: storageAccess[i].previousValue,
                        newValue: storageAccess[i].newValue
                    })
                );
            }

            // add address to task state change addresses array only if not already added
            if (!_taskStateChangeAddresses.contains(account) && _stateInfos[account].length != 0) {
                _taskStateChangeAddresses.add(account);
            }
        }
    }

    /// @notice Checks that values have code on this chain.
    ///         This method is not storage-layout-aware and therefore is not perfect. It may return erroneous
    ///         results for cases like packed slots, and silently show that things are okay when they are not.
    function isLikelyAddressThatShouldHaveCode(uint256 value) internal view virtual returns (bool) {
        // If out of range (fairly arbitrary lower bound), return false.
        if (value > type(uint160).max) return false;
        if (value < uint256(uint160(0x00000000fFFFffffffFfFfFFffFfFffFFFfFffff))) return false;
        // If the value is a L2 predeploy address it won't have code on this chain, so return false.
        if (
            value >= uint256(uint160(0x4200000000000000000000000000000000000000))
                && value <= uint256(uint160(0x420000000000000000000000000000000000FffF))
        ) return false;
        // Allow known EOAs.
        address[] memory exceptions = getCodeExceptions();
        for (uint256 i; i < exceptions.length; i++) {
            require(
                exceptions[i] != address(0),
                "getCodeExceptions includes the zero address, please make sure all entries are populated."
            );
            if (address(uint160(value)) == exceptions[i]) return false;
        }
        // Otherwise, this value looks like an address that we'd expect to have code.
        return true;
    }
}

abstract contract L2TaskBase is MultisigTask {
    using EnumerableSet for EnumerableSet.AddressSet;

    SuperchainAddressRegistry public superchainAddrRegistry;

    /// @notice Returns the type of task. L2TaskBase.
    /// Overrides the taskType function in the MultisigTask contract.
    function taskType() public pure override returns (TaskType) {
        return TaskType.L2TaskBase;
    }

    /// @notice Configures the task for L2TaskBase type tasks.
    /// Overrides the configureTask function in the MultisigTask contract.
    /// For L2TaskBase, we need to configure the superchain address registry.
    function _configureTask(string memory taskConfigFilePath)
        internal
        virtual
        override
        returns (AddressRegistry addrRegistry_, IGnosisSafe parentMultisig_, address multicallTarget_)
    {
        multicallTarget_ = MULTICALL3_ADDRESS;

        superchainAddrRegistry = new SuperchainAddressRegistry(taskConfigFilePath);
        addrRegistry_ = AddressRegistry.wrap(address(superchainAddrRegistry));

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        parentMultisig_ = IGnosisSafe(superchainAddrRegistry.getAddress(config.safeAddressString, chains[0].chainId));
        // Ensure that all chains have the same parentMultisig.
        for (uint256 i = 1; i < chains.length; i++) {
            require(
                address(parentMultisig_)
                    == superchainAddrRegistry.getAddress(config.safeAddressString, chains[i].chainId),
                string.concat(
                    "MultisigTask: safe address mismatch. Caller: ",
                    getAddressLabel(address(parentMultisig_)),
                    ". Actual address: ",
                    getAddressLabel(superchainAddrRegistry.getAddress(config.safeAddressString, chains[i].chainId))
                )
            );
        }
    }

    /// @notice We use this function to add allowed storage accesses.
    function _templateSetup(string memory) internal virtual override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < config.allowedStorageKeys.length; i++) {
            for (uint256 j = 0; j < chains.length; j++) {
                require(gasleft() > 500_000, "MultisigTask: Insufficient gas for initial getAddress() call"); // Ensure try/catch is EIP-150 safe.
                try superchainAddrRegistry.getAddress(config.allowedStorageKeys[i], chains[j].chainId) returns (
                    address addr
                ) {
                    _allowedStorageAccesses.add(addr);
                } catch {
                    require(gasleft() > 500_000, "MultisigTask: Insufficient gas for fallback get() call"); // Ensure try/catch is EIP-150 safe.
                    try superchainAddrRegistry.get(config.allowedStorageKeys[i]) returns (address addr) {
                        _allowedStorageAccesses.add(addr);
                    } catch {
                        console.log(
                            "\x1B[33m[WARN]\x1B[0m Contract: %s not found for chain: '%s'",
                            config.allowedStorageKeys[i],
                            chains[j].name
                        );
                        console.log(
                            "\x1B[33m[WARN]\x1B[0m Contract will not be added to allowed storage accesses: '%s' for chain: '%s'",
                            config.allowedStorageKeys[i],
                            chains[j].name
                        );
                    }
                }
            }
        }
    }
}

abstract contract SimpleBase is MultisigTask {
    using EnumerableSet for EnumerableSet.AddressSet;

    SimpleAddressRegistry public simpleAddrRegistry;

    /// @notice Returns the type of task. SimpleBase.
    /// Overrides the taskType function in the MultisigTask contract.
    function taskType() public pure override returns (TaskType) {
        return TaskType.SimpleBase;
    }

    /// @notice Configures the task for SimpleBase type tasks.
    /// Overrides the configureTask function in the MultisigTask contract.
    /// For SimpleBase, we need to configure the simple address registry.
    function _configureTask(string memory taskConfigFilePath)
        internal
        virtual
        override
        returns (AddressRegistry addrRegistry_, IGnosisSafe parentMultisig_, address multicallTarget_)
    {
        multicallTarget_ = MULTICALL3_ADDRESS;

        simpleAddrRegistry = new SimpleAddressRegistry(taskConfigFilePath);
        addrRegistry_ = AddressRegistry.wrap(address(simpleAddrRegistry));

        parentMultisig_ = IGnosisSafe(simpleAddrRegistry.get(config.safeAddressString));
    }

    /// @notice We use this function to add allowed storage accesses.
    function _templateSetup(string memory) internal virtual override {
        for (uint256 i = 0; i < config.allowedStorageKeys.length; i++) {
            _allowedStorageAccesses.add(simpleAddrRegistry.get(config.allowedStorageKeys[i]));
        }
    }
}
