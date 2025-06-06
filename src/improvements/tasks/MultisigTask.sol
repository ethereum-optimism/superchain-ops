// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {StdStyle} from "forge-std/StdStyle.sol";

import {Signatures} from "@base-contracts/script/universal/Signatures.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";
import {Action, Call3Value} from "src/libraries/MultisigTypes.sol";
import {StateOverrideManager} from "src/improvements/tasks/StateOverrideManager.sol";
import {Utils} from "src/libraries/Utils.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";

type AddressRegistry is address;

abstract contract MultisigTask is Test, Script, StateOverrideManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using AccountAccessParser for VmSafe.AccountAccess[];
    using AccountAccessParser for VmSafe.AccountAccess;
    using StdStyle for string;

    /// @notice Parent nonce used for generating the safe transaction.
    uint256 public nonce;

    /// @notice AddressesRegistry contract
    AddressRegistry public addrRegistry;

    /// @notice The address of the multisig for this task
    /// This state variable is always set in the `_taskSetup` function
    address public parentMultisig;

    /// @notice struct to store the addresses that are expected to have storage accesses
    EnumerableSet.AddressSet internal _allowedStorageAccesses;

    /// @notice struct to store the addresses that are expected to have balance changes
    EnumerableSet.AddressSet internal _allowedBalanceChanges;

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
        SimpleTaskBase,
        OPCMTaskBase
    }

    /// @notice state changes during task execution
    mapping(address => StateInfo[]) internal _stateInfos;

    /// @notice addresses whose state is updated in task execution
    EnumerableSet.AddressSet internal _taskStateChangeAddresses;

    /// @notice stores the gnosis safe accesses for the task
    VmSafe.StorageAccess[] internal _accountAccesses;

    /// @notice starting snapshot of the contract state before the calls are made
    uint256 internal _startSnapshot;

    /// @notice Task TOML config file values
    struct TaskConfig {
        string[] allowedStorageKeys;
        string[] allowedBalanceChanges;
        string safeAddressString;
    }

    /// @notice configuration set at initialization
    TaskConfig public config;

    /// @notice flag to determine if the task is being simulated
    uint256 private _buildStarted;

    /// @notice The address of the multicall target for this task
    address public multicallTarget;

    /// @notice Address of the child multisig. Required for nested multisig tasks; optional otherwise.
    address private childMultisig;

    /// @notice Nonce of the child multisig. Required for nested multisig tasks; optional otherwise.
    uint256 private childNonce;

    // ==================================================
    // ======== Virtual, Unimplemented Functions ========
    // ==================================================
    // These are functions have no default implementation and MUST be implemented by the inheriting contract.

    /// @notice Returns the type of task. L2TaskBase, SimpleTaskBase or OPCMTaskBase.
    function taskType() public pure virtual returns (TaskType);

    /// @notice Specifies the safe address string to run the template from. This string refers
    /// to a named contract, where the name is read from an address registry contract.
    function safeAddressString() public view virtual returns (string memory);

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their storage written to during the task.
    function _taskStorageWrites() internal view virtual returns (string[] memory);

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual returns (string[] memory) {
        return new string[](0);
    }

    /// @notice By default, any value written to storage that looks like an address is expected to
    /// have code. Sometimes, accounts without code are expected, and this function allows you to
    /// specify a list of those addresses.
    function getCodeExceptions() internal view virtual returns (address[] memory);

    /// @notice Different tasks have different inputs. A task template will create the appropriate
    /// storage structures for storing and accessing these inputs. In this method, you read in the
    /// task config file, parse the inputs from the TOML as needed, and save them off.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory taskConfigFilePath) internal virtual;

    /// @notice This method is responsible for deploying the required address registry, defining
    /// the parent multisig address, and setting the multicall target address.
    /// This method may also set any allowed and expected storage accesses that are expected in all
    /// use cases of the template.
    function _configureTask(string memory configPath)
        internal
        virtual
        returns (AddressRegistry, IGnosisSafe, address);

    /// @notice This is a solidity script of the calls you want to make, and its
    /// contents are extracted into calldata for the task. WARNING: Any state written to in this function will be reverted
    /// after the build function has been run.
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
        // Sets safe to the safe specified by the current template from addresses.json
        _taskSetup(taskConfigFilePath, optionalChildMultisig);

        // Overrides only get applied when simulating
        _overrideState(taskConfigFilePath);

        // now execute task actions
        Action[] memory actions = build();
        (VmSafe.AccountAccess[] memory accountAccesses, bytes32 txHash) = simulate(signatures, actions);
        validate(accountAccesses, actions);
        print(actions, accountAccesses, true, txHash);

        // Revert with meaningful error message if the user is trying to simulate with the wrong command.
        if (optionalChildMultisig != address(0)) {
            require(isNestedSafe(parentMultisig), "MultisigTask: multisig must be a nested safe.");
        } else {
            require(!isNestedSafe(parentMultisig), "MultisigTask: multisig must be a single safe.");
        }

        return (accountAccesses, actions);
    }

    /// @notice Runs the task with the given configuration file path.
    function simulateRun(string memory taskConfigFilePath, bytes memory signatures)
        public
        returns (VmSafe.AccountAccess[] memory, Action[] memory)
    {
        return simulateRun(taskConfigFilePath, signatures, address(0));
    }

    /// @notice Runs the task with the given configuration file path.
    function simulateRun(string memory taskConfigFilePath)
        public
        returns (VmSafe.AccountAccess[] memory, Action[] memory)
    {
        return simulateRun(taskConfigFilePath, "", address(0));
    }

    /// @notice Executes the task with the given configuration file path and signatures.
    function executeRun(string memory taskConfigFilePath, bytes memory signatures)
        public
        returns (VmSafe.AccountAccess[] memory)
    {
        // sets safe to the safe specified by the current template from addresses.json
        _taskSetup(taskConfigFilePath, address(0));

        // gather mutative calls
        Action[] memory actions = build();

        // now execute task actions
        (VmSafe.AccountAccess[] memory accountAccesses, bytes32 txHash) = execute(signatures, actions);

        // validate all state transitions
        validate(accountAccesses, actions);

        // print out results of execution
        print(actions, accountAccesses, false, txHash);

        return accountAccesses;
    }

    /// @notice Child multisig of a nested multisig approves the task to be executed with the given
    /// configuration file path and signatures.
    function approveFromChildMultisig(string memory taskConfigFilePath, address _childMultisig, bytes memory signatures)
        public
    {
        _taskSetup(taskConfigFilePath, _childMultisig);
        Action[] memory actions = build();
        approve(_childMultisig, signatures, actions);
        console.log(
            "--------- Successfully %s Child Multisig %s Approval ---------",
            isBroadcastContext() ? "Broadcasted" : "Simulated",
            _childMultisig
        );
    }

    /// @notice Simulates a nested multisig task with the given configuration file path for a
    /// given child multisig. Prints the 'data to sign' which is used to sign with the eip712sign binary.
    function signFromChildMultisig(string memory taskConfigFilePath, address _childMultisig)
        public
        returns (VmSafe.AccountAccess[] memory, Action[] memory)
    {
        return simulateRun(taskConfigFilePath, "", _childMultisig);
    }

    /// @notice This function performs the same functionality as signFromChildMultisig but
    /// to keep the terminal output clean, we don't want to return the account accesses and actions.
    function simulateAsSigner(string memory taskConfigFilePath, address _childMultisig) public {
        simulateRun(taskConfigFilePath, "", _childMultisig);
    }

    /// @notice Using the tasks config.toml file, this function configures the task.
    /// by performing various setup functions e.g. setting the address registry and multicall target.
    function _taskSetup(string memory taskConfigFilePath, address optionalChildMultisig) internal {
        require(parentMultisig == address(0), "MultisigTask: already initialized");
        config.safeAddressString = loadSafeAddressString(taskConfigFilePath);
        IGnosisSafe _parentMultisig; // TODO parentMultisig should be of type IGnosisSafe
        (addrRegistry, _parentMultisig, multicallTarget) = _configureTask(taskConfigFilePath);

        parentMultisig = address(_parentMultisig);
        childMultisig = optionalChildMultisig;

        config.allowedStorageKeys = _taskStorageWrites();
        config.allowedStorageKeys.push(config.safeAddressString);
        config.allowedBalanceChanges = _taskBalanceChanges();

        _templateSetup(taskConfigFilePath);
        // Both parent and child nonce are set here.
        // They may be overridden later by user-defined state overrides.
        // See: '_overrideState(string memory taskConfigFilePath)'
        nonce = IGnosisSafe(parentMultisig).nonce();
        if (childMultisig != address(0)) {
            childNonce = IGnosisSafe(childMultisig).nonce();
        }

        vm.label(AddressRegistry.unwrap(addrRegistry), "AddrRegistry");
        vm.label(address(this), "MultisigTask");
    }

    /// @notice Get the safe address string from the config file.
    /// If the string is not found, use the value from the template.
    function loadSafeAddressString(string memory taskConfigFilePath) public view returns (string memory) {
        string memory file = vm.readFile(taskConfigFilePath);
        try vm.parseTomlString(file, ".safeAddressString") returns (string memory _safeAddressString) {
            console.log(
                vm.toUppercase("[INFO]").green().bold(),
                "Safe address string found in config file, this takes precedence over the template value:",
                _safeAddressString
            );
            return _safeAddressString;
        } catch (bytes memory) {
            return safeAddressString();
        }
    }

    /// @notice Get the calldata to be executed by safe.
    /// Callable only after the build function has been run and the calldata has been loaded up to storage.
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

    /// @notice Print the hash to approve by EOA for parent/root multisig.
    function _printParentHash(bytes memory callData) internal view {
        console.log("Parent Multisig: ", MultisigTaskPrinter.getAddressLabel(parentMultisig));
        bytes32 safeTxHash = getHash(callData, parentMultisig);
        console.log("Safe Transaction Hash: ", vm.toString(safeTxHash));

        bytes memory encodedTxData = getEncodedTransactionData(parentMultisig, callData);
        bytes32 domainSeparator = GnosisSafeHashes.calculateDomainSeparator(block.chainid, parentMultisig);
        bytes32 messageHash = GnosisSafeHashes.getMessageHashFromEncodedTransactionData(encodedTxData);
        console.log("Domain Hash:    ", vm.toString(domainSeparator));
        console.log("Message Hash:   ", vm.toString(messageHash));

        // Call the printer version of printOPTxVerifyLink
        MultisigTaskPrinter.printOPTxVerifyLink(
            parentMultisig,
            block.chainid,
            address(0), // No child multisig for single parent hash context
            callData,
            hex"", // No child calldata
            _nonceBeforeSim(parentMultisig),
            0, // No child nonce
            _getMulticallAddress(parentMultisig),
            address(0) // No child multicall target
        );
    }

    /// @notice Returns the nonce of a Safe prior to local execution.
    /// Local execution of the task increments the nonce of the Safe by 1.
    /// This function returns the original nonce before that simulation.
    /// If the Safe is the parent or child multisig, it returns the locally stored nonce.
    /// Otherwise, it returns the current on-chain nonce of the Safe.
    /// Limitation: If another Safe (besides the parent or child) has its nonce
    /// incremented by local execution, this function will not return the correct value.
    function _nonceBeforeSim(address safe) internal view returns (uint256) {
        if (safe == parentMultisig) {
            return nonce;
        } else if (safe == childMultisig) {
            return childNonce;
        } else {
            return IGnosisSafe(safe).nonce();
        }
    }

    /// @notice Get the data to sign by EOA.
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
            _nonce: _nonceBeforeSim(safe)
        });
        require(encodedTxData.length == 66, "MultisigTask: encodedTxData length is not 66 bytes.");
    }

    /// @notice Simulate the task by approving from owners and then executing.
    function simulate(bytes memory _signatures, Action[] memory actions)
        public
        returns (VmSafe.AccountAccess[] memory, bytes32 txHash_)
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
                // Manualy increment the nonce for each owner. If we executed the approveHash function from the owner directly (contract or EOA),
                // the nonce would be incremented by 1 and we wouldn't have to do this manually.
                _incrementOwnerNonce(owners[i]);
            }
            // Gather signatures after approval hashes have been made
            signatures = prepareSignatures(parentMultisig, hash);
        } else {
            signatures = Signatures.prepareSignatures(parentMultisig, hash, _signatures);
        }

        txHash_ = IGnosisSafe(parentMultisig).getTransactionHash(
            multicallTarget, 0, callData, Enum.Operation.DelegateCall, 0, 0, 0, address(0), payable(address(0)), nonce
        );

        require(hash == txHash_, "MultisigTask: hash mismatch");

        vm.startStateDiffRecording();

        // Execute the transaction
        execTransaction(parentMultisig, multicallTarget, 0, callData, Enum.Operation.DelegateCall, signatures);
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();
        return (accountAccesses, txHash_);
    }

    /// @notice Child multisig approves the task to be executed.
    function approve(address _childMultisig, bytes memory signatures, Action[] memory actions) public {
        bytes memory approveCalldata = generateApproveMulticallData(actions);
        bytes32 hash = keccak256(getEncodedTransactionData(_childMultisig, approveCalldata));
        signatures = Signatures.prepareSignatures(_childMultisig, hash, signatures);

        execTransaction(_childMultisig, MULTICALL3_ADDRESS, 0, approveCalldata, Enum.Operation.DelegateCall, signatures);
    }

    /// @notice Executes the task with the given signatures.
    function execute(bytes memory signatures, Action[] memory actions)
        public
        returns (VmSafe.AccountAccess[] memory, bytes32 txHash_)
    {
        bytes memory callData = getMulticall3Calldata(actions);
        txHash_ = getHash(callData, parentMultisig);

        if (signatures.length == 0) {
            // if no signatures are attached, this means we are dealing with a
            // nested safe that should already have all of its approve hashes in
            // child multisigs signed already.
            signatures = prepareSignatures(parentMultisig, txHash_);
        } else {
            // otherwise, if signatures are attached, this means EOA's have
            // signed, so we order the signatures based on how Gnosis Safe
            // expects signatures to be ordered by address cast to a number
            signatures = Signatures.sortUniqueSignatures(
                parentMultisig, signatures, txHash_, IGnosisSafe(parentMultisig).getThreshold(), signatures.length
            );
        }

        vm.startStateDiffRecording();

        execTransaction(parentMultisig, multicallTarget, 0, callData, Enum.Operation.DelegateCall, signatures);

        return (vm.stopAndReturnStateDiff(), txHash_);
    }

    /// @notice Helper function that returns whether or not the current context is a broadcast context.
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
        MultisigTaskPrinter.printGasForExecTransaction(gas);

        (bool success, bytes memory returnData) = multisig.call{gas: gas}(callData);

        if (!success) {
            MultisigTaskPrinter.printErrorExecutingMultisigTransaction(returnData);
            revert("MultisigTask: execute failed");
        }
    }

    /// @notice Returns the allowed storage accesses.
    function getAllowedStorageAccess() public view returns (address[] memory) {
        return _allowedStorageAccesses.values();
    }

    /// @notice Execute post-task checks. e.g. read state variables of the deployed contracts to make
    /// sure they are deployed and initialized correctly, or read states that are expected to have changed during the simulate step.
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
                        "MultisigTask: address ",
                        MultisigTaskPrinter.getAddressLabel(addr),
                        " not in allowed storage accesses"
                    )
                )
            );
        }

        require(IGnosisSafe(parentMultisig).nonce() == nonce + 1, "MultisigTask: nonce not incremented");

        _validate(accountAccesses, actions);

        // check that state diff is as expected
        checkStateDiff(accountAccesses);
    }

    /// @notice Get task actions. Splits the actions into targets, values, and arguments.
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

    /// @notice Build the task actions for all l2chains in the task.
    /// Contract calls must be performed in plain solidity.
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

    /// @notice Print task related data for task developers and signers.
    function print(
        Action[] memory actions,
        VmSafe.AccountAccess[] memory accountAccesses,
        bool isSimulate,
        bytes32 txHash
    ) public view {
        console.log("");
        MultisigTaskPrinter.printWelcomeMessage();

        accountAccesses.decodeAndPrint(parentMultisig, txHash);

        printSafe(actions, accountAccesses, isSimulate, txHash);
    }

    /// @notice Prints all relevant hashes to sign as well as the tenderly simulation link.
    function printSafe(
        Action[] memory actions,
        VmSafe.AccountAccess[] memory accountAccesses,
        bool isSimulate,
        bytes32 txHash
    ) private view {
        // Print calldata to be executed within the Safe.
        MultisigTaskPrinter.printTaskCalldata(getMulticall3Calldata(actions));

        // Only print data if the task is being simulated.
        if (isSimulate) {
            if (isNestedSafe(parentMultisig)) {
                printNestedData(actions);
            } else {
                printSingleData(actions);
            }

            printTenderlySimulationData(actions);
        }
        bytes32 normalizedHash = AccountAccessParser.normalizedStateDiffHash(accountAccesses, parentMultisig, txHash);
        MultisigTaskPrinter.printAuditReportInfo(normalizedHash);
    }

    /// @notice Helper function to print nested calldata.
    function printNestedData(Action[] memory actions) private view {
        require(
            childMultisig != address(0),
            "MultisigTask: Child multisig cannot be zero address when printing nested data to sign."
        );
        (, bytes memory dataToSign, bytes32 domainSeparator, bytes32 messageHash) = getApproveTransactionInfo(actions);
        bytes memory parentCallDataForLink = getMulticall3Calldata(actions); // For OPVerifyLink and hash display
        bytes32 parentHashToApprove = getHash(parentCallDataForLink, parentMultisig);

        MultisigTaskPrinter.printNestedDataInfo(
            MultisigTaskPrinter.getAddressLabel(parentMultisig),
            MultisigTaskPrinter.getAddressLabel(childMultisig),
            parentHashToApprove,
            dataToSign,
            domainSeparator,
            messageHash
        );

        MultisigTaskPrinter.printOPTxVerifyLink(
            parentMultisig,
            block.chainid,
            childMultisig,
            parentCallDataForLink,
            generateApproveMulticallData(actions), // This is the child's multicall calldata for approving parent
            _nonceBeforeSim(parentMultisig),
            _nonceBeforeSim(childMultisig),
            _getMulticallAddress(parentMultisig),
            _getMulticallAddress(childMultisig)
        );
    }

    /// @notice Helper function to print non-nested safe calldata.
    function printSingleData(Action[] memory actions) private view {
        bytes memory taskCallData = getMulticall3Calldata(actions);
        bytes memory dataToSign = getEncodedTransactionData(parentMultisig, taskCallData);
        MultisigTaskPrinter.printEncodedTransactionData(dataToSign);

        MultisigTaskPrinter.printTitle("SINGLE MULTISIG EOA HASH TO APPROVE");
        _printParentHash(taskCallData);
    }

    /// @notice Print the Tenderly simulation payload with the state overrides.
    function printTenderlySimulationData(Action[] memory actions) internal view {
        address targetAddress;
        bytes memory finalExec;
        if (childMultisig != address(0)) {
            targetAddress = MULTICALL3_ADDRESS;
            finalExec = getNestedSimulationMulticall3Calldata(actions);
        } else {
            targetAddress = parentMultisig;
            finalExec = _execTransactionCalldata(
                parentMultisig,
                getMulticall3Calldata(actions),
                Signatures.genPrevalidatedSignature(msg.sender),
                _getMulticallAddress(parentMultisig)
            );
        }

        MultisigTaskPrinter.printTenderlySimulationData(
            targetAddress, finalExec, msg.sender, getStateOverrides(parentMultisig, childMultisig)
        );
    }

    /// @notice Get the hash for this safe transaction.
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

    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------
    /// ------------------------- Internal functions -----------------------
    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------

    /// @notice Prank as the multisig.
    /// Override to prank with delegatecall flag set to true
    /// in case of OPCM tasks.
    function _prankMultisig() internal virtual {
        vm.startPrank(parentMultisig);
    }

    /// @notice Validate actions inclusion. Default implementation checks for duplicate actions.
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

    /// @notice Helper function to determine if the given safe is a nested multisig.
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

    /// @notice Helper function to prepare the signatures to be executed.
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

    /// @notice Get the multicall address for the given safe. Override to return required multicall address.
    function _getMulticallAddress(address safe) internal view virtual returns (address) {
        // Some child contracts may override this function and return a different multicall address
        // based on the safe address (e.g. whether it's the parent or child multisig).
        require(safe != address(0), "Safe address cannot be zero address");
        return multicallTarget;
    }

    /// @notice To show the full transaction trace in Tenderly, we build custom calldata
    /// that shows both the child multisig approving the hash, as well as the parent multisig
    /// executing the task. This is only used when simulating a nested multisig.
    function getNestedSimulationMulticall3Calldata(Action[] memory actions)
        internal
        view
        virtual
        returns (bytes memory data)
    {
        Call3Value[] memory calls = new Call3Value[](2);

        (bytes memory approveHashCallData,,,) = getApproveTransactionInfo(actions);
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
    function getApproveTransactionInfo(Action[] memory actions)
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
        _prankMultisig();

        _startSnapshot = vm.snapshotState();

        vm.startStateDiffRecording();
    }

    /// @notice To be used at the end of the build function to snapshot the actions performed by the task and revert these changes
    /// then, stop the prank and record the state diffs and actions that were taken by the task.
    function _endBuild() private returns (Action[] memory) {
        VmSafe.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        vm.stopPrank();

        // Roll back state changes.
        require(
            vm.revertToState(_startSnapshot),
            "MultisigTask: failed to revert back to snapshot, unsafe state to run task"
        );
        require(accesses.length > 0, "MultisigTask: no account accesses found");

        // Determine the minimum call depth to isolate top-level calls only.
        // This ensures subcalls are excluded when counting actions.
        // Since account accesses are ordered by call execution (in Foundry),
        // the first entry always corresponds to a top-level call.
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

    /// @notice Stores the state of the task prior to local simulation.
    /// Sets the parent and child nonces to their current values,
    /// ensuring subsequent calldata generation uses the correct
    /// nonce values even after the task has been executed locally.
    function _overrideState(string memory taskConfigFilePath) private {
        _setStateOverridesFromConfig(taskConfigFilePath); // Sets global '_stateOverrides' variable.
        nonce = _getNonceOrOverride(address(parentMultisig));
        if (childMultisig != address(0)) {
            address[] memory owners = IGnosisSafe(parentMultisig).getOwners();
            for (uint256 i = 0; i < owners.length; i++) {
                if (owners[i] == childMultisig) {
                    childNonce = _getNonceOrOverride(address(childMultisig));
                } else {
                    _getNonceOrOverride(owners[i]); // Nonce safety checks must be performed for each owner.
                }
            }
        }
        // We must do this after setting the nonces above. It allows us to make sure we're reading the correct network state when setting the nonces.
        _applyStateOverrides(); // Applies '_stateOverrides' to the current state.
    }

    /// @notice Returns true if the given address is a new contract.
    function _isNewContract(address addr, address[] memory newContracts) private pure returns (bool isNewContract_) {
        isNewContract_ = false;
        for (uint256 j; j < newContracts.length; j++) {
            if (newContracts[j] == addr) {
                isNewContract_ = true;
                break;
            }
        }
    }

    /// @notice Returns true if the given account access should be recorded as an action. This function is used to filter out
    /// actions that we defined in the `_build` function of our template. The actions selected by this function will get executed
    /// by the relevant Multicall3 contract (e.g. `Multicall3` or `Multicall3DelegateCall`).
    function _isValidAction(VmSafe.AccountAccess memory access, uint256 topLevelDepth) internal view returns (bool) {
        bool accountNotRegistryOrVm =
            (access.account != AddressRegistry.unwrap(addrRegistry) && access.account != address(vm));
        bool accessorNotRegistry = access.accessor != AddressRegistry.unwrap(addrRegistry);
        bool isCall = (access.kind == VmSafe.AccountAccessKind.Call && access.depth == topLevelDepth);
        bool isTopLevelDelegateCall =
            (access.kind == VmSafe.AccountAccessKind.DelegateCall && access.depth == topLevelDepth);
        bool accessorIsParent = (access.accessor == parentMultisig);
        return accountNotRegistryOrVm && accessorNotRegistry && (isCall || isTopLevelDelegateCall) && accessorIsParent;
    }

    /// @notice Composes a description string for the given access using the provided operation string.
    function _composeDescription(VmSafe.AccountAccess memory access, string memory opStr)
        internal
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                opStr,
                " ",
                MultisigTaskPrinter.getAddressLabel(access.account),
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

    /// @notice Increments the nonce of the given owner.
    /// If the owner is a contract, we need to increment the nonce manually.
    /// This is in lieu of executing approveHash from the owner contract.
    function _incrementOwnerNonce(address owner) private {
        if (address(owner).code.length > 0) {
            uint256 currentOwnerNonce = IGnosisSafe(owner).nonce();
            vm.store(owner, bytes32(uint256(0x5)), bytes32(uint256(currentOwnerNonce + 1)));
        } else {
            uint256 currentOwnerNonce = vm.getNonce(owner);
            vm.setNonce(owner, uint64(currentOwnerNonce + 1));
        }
    }

    /// @notice This function performs basic checks on the state diff.
    /// It checks that all touched accounts have code, that the balances are unchanged if not expected, and that no self-destructs occurred.
    function checkStateDiff(VmSafe.AccountAccess[] memory accountAccesses) internal view {
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

            if (!_allowedBalanceChanges.contains(accountAccess.account)) {
                // Skip balance change checks for newly deployed contracts.
                // Ensure that existing contracts, that haven't been allow listed, do not contain a value transfer.
                if (!_isNewContract(accountAccess.account, newContracts)) {
                    require(
                        !accountAccess.containsValueTransfer(),
                        string.concat("Unexpected balance change: ", vm.toString(accountAccess.account))
                    );
                }
            }

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
    /// This method is not storage-layout-aware and therefore is not perfect. It may return erroneous
    /// results for cases like packed slots, and silently show that things are okay when they are not.
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
