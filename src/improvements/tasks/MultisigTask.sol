// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";

import {Signatures} from "@base-contracts/script/universal/Signatures.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {AddressRegistry} from "src/improvements/AddressRegistry.sol";

abstract contract MultisigTask is Test, Script {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice nonce used for generating the safe transaction
    /// will be set to the value specified in the config file
    uint256 public nonce;

    /// @notice flag to determine if the safe is nested multisig
    bool public isNestedSafe;

    /// @notice owners the safe started with
    address[] public startingOwners;

    /// @notice AddressesRegistry contract
    AddressRegistry public addrRegistry;

    /// @notice The address of the multisig for this task
    address public parentMultisig;

    /// @notice struct to store allowed storage accesses read in from config file
    /// uses OpenZeppelin EnumerableSet for allowed storage accesses
    EnumerableSet.AddressSet private _allowedStorageAccesses;

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

    /// @notice list of actions to be executed, regardless of task type
    /// they all follow the same structure
    Action[] public actions;

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
        string[] allowedStorageWriteAccesses;
        string safeAddressString;
    }

    /// @notice configuration set at initialization
    TaskConfig public config;

    /// @notice flag to determine if the task is being simulated
    bool private _buildStarted;

    /// @notice The address of the child multisig for this task
    address public childMultisig;

    /// @notice The address of the multicall target for this task
    /// @dev set in _setMulticallAddress
    address public multicallTarget;

    /// @notice buildModifier to be used by the build function to populate the
    /// actions array
    modifier buildModifier() {
        require(parentMultisig != address(0), "Must set address registry for multisig address to be set");

        require(!_buildStarted, "Build already started");
        _buildStarted = true;

        _startBuild();
        _;
        _endBuild();

        _buildStarted = false;
    }

    /// @notice abstract function to be implemented by the inheriting contract
    /// specifies the safe address string to run the template from
    function safeAddressString() public pure virtual returns (string memory);

    /// @notice abstract function to be implemented by the inheriting contract
    /// specifies the addresses that must have their storage written to
    function _taskStorageWrites() internal pure virtual returns (string[] memory);

    /// @notice Runs the task with the given configuration file path.
    /// Sets the address registry, initializes and simulates the single multisig
    /// as well as the nested multisig. For single multisig,
    /// prints the data to sign and the hash to approve which is used to sign with the eip712sign binary.
    /// For nested multisig, prints the data to sign and the hash to approve for each of the child multisigs.
    /// @param taskConfigFilePath The path to the task configuration file.
    function simulateRun(string memory taskConfigFilePath, bytes memory signatures)
        public
        returns (VmSafe.AccountAccess[] memory)
    {
        /// sets safe to the safe specified by the current template from addresses.json
        _taskSetup(taskConfigFilePath);

        /// now execute task actions
        build();
        VmSafe.AccountAccess[] memory accountAccesses = simulate(signatures);
        validate(accountAccesses);
        print();

        return accountAccesses;
    }

    /// @notice Runs the task with the given configuration file path.
    /// Sets the address registry, initializes and simulates the single multisig
    /// as well as the nested multisig. For single multisig,
    /// prints the data to sign and the hash to approve which is used to sign with the eip712sign binary.
    /// For nested multisig, prints the data to sign and the hash to approve for each of the child multisigs.
    /// @param taskConfigFilePath The path to the task configuration file.
    function simulateRun(string memory taskConfigFilePath) public returns (VmSafe.AccountAccess[] memory) {
        return simulateRun(taskConfigFilePath, "");
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
        /// sets safe to the safe specified by the current template from addresses.json
        _taskSetup(taskConfigFilePath);

        /// gather mutative calls
        build();

        /// now execute task actions
        VmSafe.AccountAccess[] memory accountAccesses = execute(signatures);

        /// validate all state transitions
        validate(accountAccesses);

        /// print out results of execution
        print();

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
        build();
        approve(_childMultisig, signatures);
        console.log(
            "--------- Successfully %s Child Multisig %s Approval ---------",
            vm.isContext(VmSafe.ForgeContext.ScriptBroadcast || VmSafe.ForgeContext.ScriptResume) ? "Broadcasted" : "Simulated",
            _childMultisig
        );
    }

    /// @notice Simulates a nested multisig task with the given configuration file path for a
    /// given child multisig. Prints the data to sign and the hash to approve corresponding to
    /// the _childMultisig, printed data to sign is used to sign with the eip712sign binary.
    /// @param taskConfigFilePath The path to the task configuration file.
    /// @param _childMultisig The address of the child multisig.
    function signFromChildMultisig(string memory taskConfigFilePath, address _childMultisig) public {
        childMultisig = _childMultisig;
        simulateRun(taskConfigFilePath);
        require(isNestedSafe, "MultisigTask: multisig must be nested");
    }

    /// @notice Sets the address registry, initializes the task.
    /// @param taskConfigFilePath The path to the task configuration file.
    function _taskSetup(string memory taskConfigFilePath) internal {
        AddressRegistry _addrRegistry = new AddressRegistry(taskConfigFilePath);

        _templateSetup(taskConfigFilePath);

        _setMulticallAddress();

        /// set the task config
        require(
            bytes(config.safeAddressString).length == 0 && address(addrRegistry) == address(0x0),
            "MultisigTask: already initialized"
        );
        require(
            block.chainid == getChain("mainnet").chainId || block.chainid == getChain("sepolia").chainId,
            string.concat("Unsupported network: ", vm.toString(block.chainid))
        );

        config.safeAddressString = safeAddressString();
        config.allowedStorageWriteAccesses = _taskStorageWrites();
        config.allowedStorageWriteAccesses.push(safeAddressString());

        // set the AddressRegistry
        addrRegistry = _addrRegistry;

        // get chains
        AddressRegistry.ChainInfo[] memory chains = addrRegistry.getChains();
        require(chains.length > 0, "MultisigTask: no chains found");

        // check that the safe address is the same for all chains and then set safe in storage
        parentMultisig = addrRegistry.getAddress(config.safeAddressString, chains[0].chainId);

        // TODO change this once we implement task stacking
        nonce = IGnosisSafe(parentMultisig).nonce();

        address[] memory owners = IGnosisSafe(parentMultisig).getOwners();
        {
            uint256 quorum = IGnosisSafe(parentMultisig).getThreshold();
            uint256 eoaOwnerCount;
            for (uint256 i = 0; i < owners.length; i++) {
                if (owners[i].code.length == 0) {
                    eoaOwnerCount++;
                }
            }

            isNestedSafe = eoaOwnerCount >= quorum ? false : true;
        }

        vm.label(address(addrRegistry), "AddrRegistry");
        vm.label(address(this), "MultisigTask");

        for (uint256 i = 1; i < chains.length; i++) {
            require(
                parentMultisig == addrRegistry.getAddress(config.safeAddressString, chains[i].chainId),
                string.concat(
                    "MultisigTask: safe address mismatch. Caller: ",
                    getAddressLabel(parentMultisig),
                    ". Actual address: ",
                    getAddressLabel(addrRegistry.getAddress(config.safeAddressString, chains[i].chainId))
                )
            );
        }

        // Fetch starting owners
        IGnosisSafe safe = IGnosisSafe(parentMultisig);
        startingOwners = safe.getOwners();

        // this loads the allowed storage write accesses to storage for this task
        // if this task changes storage slots outside of the allowed write accesses,
        // then the task will fail at runtime and the task developer will need to
        // update the config to include the addresses whose storage slots changed,
        // or figure out why the storage slots are being changed when they should not be.
        for (uint256 i = 0; i < config.allowedStorageWriteAccesses.length; i++) {
            for (uint256 j = 0; j < chains.length; j++) {
                _allowedStorageAccesses.add(
                    addrRegistry.getAddress(config.allowedStorageWriteAccesses[i], chains[j].chainId)
                );
            }
        }
    }

    /// @notice get the calldata to be executed by safe
    /// @dev callable only after the build function has been run and the
    /// calldata has been loaded up to storage
    /// @return data The calldata to be executed
    function getCalldata() public view virtual returns (bytes memory data) {
        // get task actions
        (address[] memory targets, uint256[] memory values, bytes[] memory arguments) = getTaskActions();

        // create calls array with targets and arguments
        Call3Value[] memory calls = new Call3Value[](targets.length);

        for (uint256 i; i < calls.length; i++) {
            require(targets[i] != address(0), "Invalid target for multisig");
            calls[i] = Call3Value({target: targets[i], allowFailure: false, value: values[i], callData: arguments[i]});
        }

        // generate calldata
        data = abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
    }

    /// @notice print the data to sig by EOA for single multisig
    function printDataToSign() public view {
        // logs required for using eip712sign binary to sign the data to sign with Ledger
        console.log("vvvvvvvv");
        console.logBytes(getDataToSign(parentMultisig, getCalldata()));
        console.log("^^^^^^^^\n");
    }

    /// @notice print the hash to approve by EOA for single multisig
    function printHashToApprove() public view {
        console.logBytes32(getHash());
    }

    function _getNonce(address safe) internal view returns (uint256) {
        return (safe == parentMultisig) ? nonce : IGnosisSafe(safe).nonce();
    }

    /// @notice get the data to sign by EOA
    /// @param safe The address of the safe
    /// @param data The calldata to be executed
    /// @return The data to sign
    function getDataToSign(address safe, bytes memory data) public view returns (bytes memory) {
        return IGnosisSafe(safe).encodeTransactionData({
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
    }

    /// @notice simulate the task by approving from owners and then executing
    function simulate(bytes memory _signatures) public returns (VmSafe.AccountAccess[] memory) {
        bytes memory data = getCalldata();
        bytes32 hash = getHash();
        bytes memory signatures;

        // Approve the hash from each owner
        address[] memory owners = IGnosisSafe(parentMultisig).getOwners();
        if (_signatures.length == 0) {
            for (uint256 i = 0; i < owners.length; i++) {
                vm.prank(owners[i]);
                IGnosisSafe(parentMultisig).approveHash(hash);
            }
            /// gather signatures after approval hashes have been made
            signatures = prepareSignatures(parentMultisig, hash);
        } else {
            signatures = Signatures.prepareSignatures(parentMultisig, hash, _signatures);
        }

        bytes32 txHash = IGnosisSafe(parentMultisig).getTransactionHash(
            multicallTarget, 0, data, Enum.Operation.DelegateCall, 0, 0, 0, address(0), payable(address(0)), nonce
        );

        require(hash == txHash, "MultisigTask: hash mismatch");

        vm.startStateDiffRecording();

        // Execute the transaction
        execTransaction(parentMultisig, multicallTarget, 0, data, Enum.Operation.DelegateCall, signatures);

        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();

        return accountAccesses;
    }

    /// @notice child multisig approves the task to be executed.
    /// @param _childMultisig The address of the child multisig that is approving the task.
    /// @param signatures The signatures to approve the task transaction hash.
    function approve(address _childMultisig, bytes memory signatures) public {
        bytes memory approveCalldata = generateApproveMulticallData();
        bytes32 hash = keccak256(getDataToSign(_childMultisig, approveCalldata));
        signatures = Signatures.prepareSignatures(_childMultisig, hash, signatures);

        if (vm.isContext(VmSafe.ForgeContext.ScriptBroadcast)) {
            // only broadcast if we are running forge script with the --broadcast flag
            vm.broadcast();
        }

        execTransaction(_childMultisig, MULTICALL3_ADDRESS, 0, approveCalldata, Enum.Operation.DelegateCall, signatures);
    }

    /// @notice Executes the task with the given signatures.
    /// @param signatures The signatures to execute the task.
    function execute(bytes memory signatures) public returns (VmSafe.AccountAccess[] memory) {
        bytes memory data = getCalldata();
        bytes32 hash = getHash();

        // if no signatures are attached, create them
        if (signatures.length == 0) {
            signatures = prepareSignatures(parentMultisig, hash);
        } else {
            /// otherwise we assume the signatures are already ordered
            Signatures.sortUniqueSignatures(
                parentMultisig, signatures, hash, IGnosisSafe(parentMultisig).getThreshold(), signatures.length
            );
        }

        vm.startStateDiffRecording();
        if (vm.isContext(VmSafe.ForgeContext.ScriptBroadcast)) {
            /// only broadcast if we are running forge script with the --broadcast flag
            vm.broadcast();
        }

        execTransaction(parentMultisig, multicallTarget, 0, data, Enum.Operation.DelegateCall, signatures);

        return vm.stopAndReturnStateDiff();
    }

    function execTransaction(
        address multisig,
        address target,
        uint256 value,
        bytes memory data,
        Enum.Operation operationType,
        bytes memory signatures
    ) internal {
        (bool success) = IGnosisSafe(multisig).execTransaction(
            target, value, data, operationType, 0, 0, 0, address(0), payable(address(0)), signatures
        );
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
    function validate(VmSafe.AccountAccess[] memory accountAccesses) public virtual {
        /// write all state changes to storage
        _processStateDiffChanges(accountAccesses);

        /// check that all state change addresses are in allowed storage accesses
        for (uint256 i; i < _taskStateChangeAddresses.length(); i++) {
            address addr = _taskStateChangeAddresses.at(i);
            require(
                _allowedStorageAccesses.contains(addr),
                string(
                    abi.encodePacked(
                        "MultisigTask: address ", getAddressLabel(addr), " not in allowed storage accesses"
                    )
                )
            );
        }

        // check that all allowed storage accesses are in task state change addresses
        for (uint256 i; i < _allowedStorageAccesses.length(); i++) {
            address addr = _allowedStorageAccesses.at(i);
            require(
                _taskStateChangeAddresses.contains(addr),
                string(
                    abi.encodePacked(
                        "MultisigTask: address ", getAddressLabel(addr), " not in task state change addresses"
                    )
                )
            );
        }

        require(IGnosisSafe(parentMultisig).nonce() == nonce + 1, "MultisigTask: nonce not incremented");

        AddressRegistry.ChainInfo[] memory chains = addrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            _validate(chains[i].chainId);
        }

        /// check that state diff is as expected
        checkStateDiff(accountAccesses);
    }

    /// @notice get task actions
    /// @return targets The targets of the actions
    /// @return values The values of the actions
    /// @return arguments The arguments of the actions
    function getTaskActions()
        public
        view
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
    function build() public buildModifier {
        _buildSingle();

        AddressRegistry.ChainInfo[] memory chains = addrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            _buildPerChain(chains[i].chainId);
        }
    }

    /// @notice print task description, actions, transfers, state changes and EOAs datas to sign
    function print() public view {
        console.log("\n------------------ Task Actions ------------------");
        for (uint256 i; i < actions.length; i++) {
            console.log("%d). %s", i + 1, actions[i].description);
            console.log("target: %s\npayload", getAddressLabel(actions[i].target));
            console.logBytes(actions[i].arguments);
            console.log("\n");
        }

        console.log("\n----------------- Task Transfers -------------------");
        if (_taskTransferFromAddresses.length() == 0) {
            console.log("\nNo Transfers\n");
        }
        for (uint256 i; i < _taskTransferFromAddresses.length(); i++) {
            address account = _taskTransferFromAddresses.at(i);

            console.log("\n\n", string.concat(getAddressLabel(account), ":"));

            // print token transfers
            TransferInfo[] memory transfers = _taskTransfers[account];
            if (transfers.length > 0) {
                console.log("\n Transfers:");
            }
            for (uint256 j; j < transfers.length; j++) {
                if (transfers[j].tokenAddress == address(0)) {
                    console.log(
                        string(
                            abi.encodePacked(
                                "Sent ", vm.toString(transfers[j].value), " ETH to ", getAddressLabel(transfers[j].to)
                            )
                        )
                    );
                } else {
                    console.log(
                        string(
                            abi.encodePacked(
                                "Sent ",
                                vm.toString(transfers[j].value),
                                " ",
                                getAddressLabel(transfers[j].tokenAddress),
                                " to ",
                                getAddressLabel(transfers[j].to)
                            )
                        )
                    );
                }
            }
        }

        console.log("\n----------------- Task State Changes -------------------");
        // print state changes
        for (uint256 k; k < _taskStateChangeAddresses.length(); k++) {
            address account = _taskStateChangeAddresses.at(k);
            StateInfo[] memory stateChanges = _stateInfos[account];
            if (stateChanges.length > 0) {
                console.log("\n State Changes for account:", getAddressLabel(account));
            }
            for (uint256 j; j < stateChanges.length; j++) {
                console.log("Slot:", vm.toString(stateChanges[j].slot));
                console.log("- ", vm.toString(stateChanges[j].oldValue));
                console.log("+ ", vm.toString(stateChanges[j].newValue));
            }
        }

        // print calldata to be executed within the Safe
        console.log("\n\n------------------ Task Calldata ------------------");
        console.logBytes(getCalldata());

        if (isNestedSafe) {
            console.log("\n\n------------------ Nested Multisig EOAs Data to Sign ------------------");
            printNestedDataToSign();
            console.log("\n\n------------------ Nested Multisig EOAs Hash to Approve ------------------");
            printNestedHashToApprove();
        } else {
            console.log("\n\n------------------ Single Multisig EOA Data to Sign ------------------");
            printDataToSign();
            console.log("\n\n------------------ Single Multisig EOA Hash to Approve ------------------");
            printHashToApprove();
        }
        console.log("\n\n------------------ Tenderly Simulation Link ------------------");
        printTenderlySimulationLink();
    }

    /// @notice print the data to sign by EOA for nested multisig
    function printNestedDataToSign() public view {
        bytes memory callData = generateApproveMulticallData();

        if (childMultisig != address(0) && childMultisig.code.length != 0) {
            console.log("Child multisig: %s", getAddressLabel(childMultisig));
            // logs required for using eip712sign binary to sign the data to sign with Ledger
            console.log("vvvvvvvv");
            console.logBytes(getDataToSign(childMultisig, callData));
            console.log("^^^^^^^^\n");
        } else {
            for (uint256 i; i < startingOwners.length; i++) {
                if (startingOwners[i].code.length == 0) {
                    continue;
                }
                console.log("Nested multisig: %s", getAddressLabel(startingOwners[i]));
                console.logBytes(getDataToSign(startingOwners[i], callData));
            }
        }
    }

    /// @notice print the hash to approve by EOA for nested multisig
    function printNestedHashToApprove() public view {
        bytes memory callData = generateApproveMulticallData();

        if (childMultisig != address(0) && childMultisig.code.length != 0) {
            console.log("Nested multisig: %s", getAddressLabel(childMultisig));
            console.logBytes32(keccak256(getDataToSign(childMultisig, callData)));
        } else {
            for (uint256 i; i < startingOwners.length; i++) {
                /// do not get data to sign if owner is an EOA (not a multisig)
                if (startingOwners[i].code.length == 0) {
                    continue;
                }

                bytes32 hash = keccak256(getDataToSign(startingOwners[i], callData));
                console.log("Nested multisig: %s", getAddressLabel(startingOwners[i]));
                console.logBytes32(hash);
            }
        }
    }

    /// @notice print the tenderly simulation link with the state overrides
    function printTenderlySimulationLink() internal view {
        Simulation.StateOverride[] memory overrides = new Simulation.StateOverride[](1);
        overrides[0] =
            Simulation.overrideSafeThresholdOwnerAndNonce(parentMultisig, msg.sender, _getNonce(parentMultisig));
        bytes memory txData =
            _execTransationCalldata(parentMultisig, getCalldata(), Signatures.genPrevalidatedSignature(msg.sender));
        Simulation.logSimulationLink({_to: parentMultisig, _data: txData, _from: msg.sender, _overrides: overrides});
    }

    /// @notice get the hash for this safe transaction
    /// can only be called after the build function, otherwise it reverts
    function getHash() public view returns (bytes32) {
        bytes memory data = getCalldata();
        return keccak256(getDataToSign(parentMultisig, data));
    }

    /// @notice helper function to generate the approveHash calldata to be executed by child multisig owner on parent multisig
    function generateApproveMulticallData() public view returns (bytes memory) {
        bytes32 hash = getHash();
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

    /// The functions are called in the following order during the task lifecycle:

    /// 1. template setup is the common entrypoint to the MultisigTask regardless of which function is run
    /// @notice abstract function to be implemented by the inheriting contract to setup the template
    function _templateSetup(string memory taskConfigFilePath) internal virtual;

    /// 2. _buildSingle function is the main function for crafting calldata for templates that have calls to be
    /// made outside of the for loop that iterates over the chains in the task. This function can be used for
    /// calls to contracts that may or may not be chain specific.
    /// Does not have to be overridden in inheriting contracts.
    function _buildSingle() internal virtual {}

    /// 3. _buildPerChain function is the main function for crafting calldata for templates that can be used across
    /// multiple chains, it is called in a for loop, which iterates over the chains in the task. The _buildPerChain
    /// function is called with the chainId as an argument the buildModifier captures all of the actions taken in
    /// this function.
    /// @notice build the task actions for a given l2chain
    /// @dev override to add additional task specific build logic
    function _buildPerChain(uint256 chainId) internal virtual;

    /// 4. _validate function is called after the build function has been run for all chains and the results
    /// of this tasks state transitions have been applied. This checks that the state transitions are valid
    /// and applied correctly.
    /// @notice task specific validations
    /// @dev override to add additional task specific validations
    /// @param chainId The l2chainId
    function _validate(uint256 chainId) internal view virtual;

    /// @notice validate actions inclusion
    /// default implementation check for duplicate actions
    function _validateAction(address target, uint256 value, bytes memory data) internal view {
        uint256 actionsLength = actions.length;
        for (uint256 i = 0; i < actionsLength; i++) {
            // Check if the target, arguments and value matches with other existing actions.
            bool isDuplicateTarget = actions[i].target == target;
            bool isDuplicateArguments = keccak256(actions[i].arguments) == keccak256(data);
            bool isDuplicateValue = actions[i].value == value;

            require(!(isDuplicateTarget && isDuplicateArguments && isDuplicateValue), "Duplicated action found");
        }
    }

    /// @notice overridden in templates
    function getCodeExceptions() internal view virtual returns (address[] memory);

    /// @notice helper function to prepare the signatures to be executed
    /// @param _safe The address of the parent multisig
    /// @param hash The hash to be approved
    /// @return The signatures to be executed
    function prepareSignatures(address _safe, bytes32 hash) internal view returns (bytes memory) {
        // prepend the prevalidated signatures to the signatures
        address[] memory approvers = Signatures.getApprovers(_safe, hash);
        return Signatures.genPrevalidatedSignatures(approvers);
    }

    function _execTransationCalldata(address _safe, bytes memory _data, bytes memory _signatures)
        internal
        view
        returns (bytes memory)
    {
        return abi.encodeCall(
            IGnosisSafe(_safe).execTransaction,
            (
                multicallTarget,
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

    /// @notice set the multicall address
    /// @dev override to set the multicall address to the delegatecall multicall address
    /// in case of opcm tasks
    function _setMulticallAddress() internal virtual {
        multicallTarget = MULTICALL3_ADDRESS;
    }

    /// @notice prank the multisig
    /// @dev override to prank with delegatecall flag set to true
    /// in case of opcm tasks, the multisig is not pranked
    function _prankMultisig() internal virtual {
        vm.startPrank(parentMultisig);
    }

    /// @notice get the multicall address for the given safe
    /// it will be the regular multicall address for parent as well as child multisigs
    /// @param safe The address of the safe
    /// @return The address of the multicall
    /// @dev override to return required multicall address
    function _getMulticallAddress(address safe) internal view virtual returns (address) {
        require(safe != address(0), "Safe address cannot be zero address");
        return multicallTarget;
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

        _startSnapshot = vm.snapshot();

        vm.startStateDiffRecording();
    }

    /// @notice to be used at the end of the build function to snapshot
    /// the actions performed by the task and revert these changes
    /// then, stop the prank and record the state diffs and actions that
    /// were taken by the task.
    function _endBuild() private {
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();

        vm.stopPrank();

        // roll back all state changes made during the task
        require(
            vm.revertTo(_startSnapshot), "MultisigTask: failed to revert back to snapshot, unsafe state to run task"
        );

        // there should be at least one account access
        require(accountAccesses.length > 0, "MultisigTask: no account accesses found");

        // get the minimum depth of the calls, we only care about the top level calls
        // this is to avoid counting subcalls as actions.
        // the account accesses are in order of the calls, so the first one is always the top level call
        uint256 topLevelDepth = accountAccesses[0].depth;

        for (uint256 i = 0; i < accountAccesses.length; i++) {
            // store all gnosis safe storage accesses that are writes
            for (uint256 j = 0; j < accountAccesses[i].storageAccesses.length; j++) {
                if (accountAccesses[i].account == parentMultisig && accountAccesses[i].storageAccesses[j].isWrite) {
                    _accountAccesses.push(accountAccesses[i].storageAccesses[j]);
                }
            }

            // calls to and from AddressRegistry and the vm contract are ignored
            bool accountIsNotAddressRegistryOrVm =
                accountAccesses[i].account != address(addrRegistry) && accountAccesses[i].account != address(vm);
            bool accessorIsNotAddressRegistry = accountAccesses[i].accessor != address(addrRegistry);
            // only care about calls or top leveldelegate calls from the multisig, static calls are ignored
            bool isCall = accountAccesses[i].kind == VmSafe.AccountAccessKind.Call;
            bool isTopLevelDelegateCall = accountAccesses[i].kind == VmSafe.AccountAccessKind.DelegateCall
                && accountAccesses[i].depth == topLevelDepth;
            // only record actions from the parent multisig
            bool accessorIsParentMultisig = accountAccesses[i].accessor == parentMultisig;

            if (
                accountIsNotAddressRegistryOrVm && accessorIsNotAddressRegistry && (isCall || isTopLevelDelegateCall)
                    && accessorIsParentMultisig
            ) {
                // caller is multisig, not a subcall, check that this action is not duplicated
                _validateAction(accountAccesses[i].account, accountAccesses[i].value, accountAccesses[i].data);

                string memory operationStr;
                Enum.Operation operation;
                if (accountAccesses[i].kind == VmSafe.AccountAccessKind.Call) {
                    operationStr = "Call";
                    operation = Enum.Operation.Call;
                } else if (accountAccesses[i].kind == VmSafe.AccountAccessKind.DelegateCall) {
                    operationStr = "DelegateCall";
                    operation = Enum.Operation.DelegateCall;
                } else {
                    revert("Unknown account access kind");
                }

                string memory description = string(
                    abi.encodePacked(
                        operationStr,
                        " ",
                        getAddressLabel(accountAccesses[i].account),
                        " with ",
                        vm.toString(accountAccesses[i].value),
                        " eth and ",
                        vm.toString(accountAccesses[i].data),
                        " data."
                    )
                );

                actions.push(
                    Action({
                        value: accountAccesses[i].value,
                        target: accountAccesses[i].account,
                        arguments: accountAccesses[i].data,
                        operation: operation,
                        description: description
                    })
                );
            }
        }
    }

    /// @notice helper function that can be overridden by template contracts to
    /// check the state changes applied by the task. This function can check
    /// that only the nonce changed in the parent multisig when executing a task
    /// by checking the slot and address where the slot changed.
    function checkStateDiff(VmSafe.AccountAccess[] memory accountAccesses) internal view virtual {
        console.log("Running assertions on the state diff");
        require(accountAccesses.length > 0, "No account accesses");
        address[] memory allowedAccesses = getAllowedStorageAccess();
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
                    allowed = allowed || (account == allowedAccesses[k]);
                }
                require(allowed, string.concat("Unallowed Storage access: ", vm.toString(account)));
            }
        }
    }

    /// @notice helper method to get transfers and state changes of task affected addresses
    function _processStateDiffChanges(VmSafe.AccountAccess[] memory accountAccesses) private {
        // first check that no tokens or eth were sent that should not have been
        // then check that all state changes that happened were in contracts that were allowed to have state changes
        for (uint256 i = 0; i < accountAccesses.length; i++) {
            // process ETH transfer changes
            _processETHTransferChanges(accountAccesses[i]);

            // process ERC20 transfer changes
            _processERC20TransferChanges(accountAccesses[i]);

            // process state changes
            _processStateChanges(accountAccesses[i].storageAccesses);
        }
    }

    /// @notice helper method to get eth transfers of task affected addresses
    function _processETHTransferChanges(VmSafe.AccountAccess memory accountAccess) private {
        address account = accountAccess.account;
        // get eth transfers
        if (accountAccess.value != 0) {
            // add address to task transfer from addresses array only if not already added
            if (!_taskTransferFromAddresses.contains(accountAccess.accessor)) {
                _taskTransferFromAddresses.add(accountAccess.accessor);
            }
            _taskTransfers[accountAccess.accessor].push(
                TransferInfo({to: account, value: accountAccess.value, tokenAddress: address(0)})
            );
        }
    }

    /// @notice helper method to get ERC20 token transfers of task affected addresses
    function _processERC20TransferChanges(VmSafe.AccountAccess memory accountAccess) private {
        bytes memory data = accountAccess.data;
        if (data.length <= 4) {
            return;
        }

        // get function selector from calldata
        bytes4 selector = bytes4(data);

        // get function params
        bytes memory params = new bytes(data.length - 4);
        for (uint256 j = 0; j < data.length - 4; j++) {
            params[j] = data[j + 4];
        }

        address from;
        address to;
        uint256 value;
        // 'transfer' selector in ERC20 token
        if (selector == 0xa9059cbb) {
            (to, value) = abi.decode(params, (address, uint256));
            from = accountAccess.accessor;
        }
        // 'transferFrom' selector in ERC20 token
        else if (selector == 0x23b872dd) {
            (from, to, value) = abi.decode(params, (address, address, uint256));
        } else {
            return;
        }

        // add address to task transfer from addresses array only if not already added
        if (!_taskTransferFromAddresses.contains(from)) {
            _taskTransferFromAddresses.add(from);
        }

        _taskTransfers[from].push(TransferInfo({to: to, value: value, tokenAddress: accountAccess.account}));
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
