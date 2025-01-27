// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ITask} from "src/fps/task/ITask.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";
import {SAFE_NONCE_SLOT, MULTICALL3_ADDRESS} from "src/fps/utils/Constants.sol";
import {Signatures} from "@base-contracts/script/universal/Signatures.sol";

abstract contract MultisigTask is Test, Script, ITask {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice nonce used for generating the safe transaction
    /// will be set to the value specified in the config file
    uint256 public nonce;

    /// @notice flag to determine if the safe is nested multisig
    bool public isNestedSafe;

    /// @notice owners the safe started with
    address[] public startingOwners;

    /// @notice array of L2 ChainIds this task will interface with
    uint256[] public l2ChainIds;

    /// @notice configured chain id
    uint256 public configChainId;

    /// @notice Addresses contract
    Addresses public addresses;

    /// @notice The address of the multisig for this task
    address public multisig;

    /// @notice struct to store allowed storage accesses read in from config file
    /// uses OpenZeppelin EnumerableSet for allowed storage accesses
    EnumerableSet.AddressSet private _allowedStorageAccesses;

    /// @notice Struct to store information about an action
    /// @param target The address of the target contract
    /// @param value The amount of ETH to send with the action
    /// @param arguments The calldata to send with the action
    /// @param description A description of the action
    struct Action {
        address target;
        uint256 value;
        bytes arguments;
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
    mapping(address => StateInfo[]) private _stateInfos;

    /// @notice addresses involved in state changes or token transfers
    EnumerableSet.AddressSet private _taskTransferFromAddresses;

    /// @notice addresses whose state is updated in task execution
    EnumerableSet.AddressSet internal _taskStateChangeAddresses;

    /// @notice stores the gnosis safe accesses for the task
    VmSafe.StorageAccess[] internal _accountAccesses;

    /// @notice starting snapshot of the contract state before the calls are made
    uint256 private _startSnapshot;

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

    /// @notice buildModifier to be used by the build function to populate the
    /// actions array
    modifier buildModifier() {
        require(multisig != address(0), "Must set addresses object for multisig address to be set");

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

    /// @notice Runs the task with the given configuration file paths.
    /// Sets the address registry, initializes the task and simulates the task.
    /// @param taskConfigFilePath The path to the task configuration file.
    function run(string memory taskConfigFilePath) public {
        Addresses _addresses = new Addresses(taskConfigFilePath);

        _templateSetup(taskConfigFilePath);

        /// set the task config
        require(
            bytes(config.safeAddressString).length == 0 && address(addresses) == address(0x0),
            "MultisigTask: already initialized"
        );
        require(
            block.chainid == getChain("mainnet").chainId || block.chainid == getChain("sepolia").chainId,
            string.concat("Unsupported network: ", vm.toString(block.chainid))
        );

        config.safeAddressString = safeAddressString();
        config.allowedStorageWriteAccesses = _taskStorageWrites();

        /// set the addresses object
        addresses = _addresses;

        /// assume safe is nested unless there is an EOA owner
        isNestedSafe = true;

        /// get chains
        Addresses.ChainInfo[] memory chains = addresses.getChains();
        require(chains.length > 0, "MultisigTask: no chains found");

        /// check that the safe address is the same for all chains and then set safe in storage
        multisig = addresses.getAddress(config.safeAddressString, chains[0].chainId);

        /// TODO change this once we implement task stacking
        nonce = IGnosisSafe(multisig).nonce();

        address[] memory owners = IGnosisSafe(multisig).getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i].code.length == 0) {
                isNestedSafe = false;
            }
        }

        for (uint256 i = 1; i < chains.length; i++) {
            require(
                multisig == addresses.getAddress(config.safeAddressString, chains[i].chainId),
                string.concat(
                    "MultisigTask: safe address mismatch. Caller: ",
                    vm.getLabel(multisig),
                    ". Actual address: ",
                    vm.getLabel(addresses.getAddress(config.safeAddressString, chains[i].chainId))
                )
            );
        }

        /// Fetch starting owners
        IGnosisSafe safe = IGnosisSafe(multisig);
        startingOwners = safe.getOwners();

        /// this loads the allowed storage write accesses to storage for this task
        /// if this task changes storage slots outside of the allowed write accesses,
        /// then the task will fail at runtime and the task developer will need to
        /// update the config to include the addresses whose storage slots changed,
        /// or figure out why the storage slots are being changed when they should not be.
        for (uint256 i = 0; i < config.allowedStorageWriteAccesses.length; i++) {
            for (uint256 j = 0; j < chains.length; j++) {
                _allowedStorageAccesses.add(
                    addresses.getAddress(config.allowedStorageWriteAccesses[i], chains[j].chainId)
                );
            }
        }

        /// now execute proposal
        build();
        simulate();
        validate();
        print();
    }

    /// @notice abstract function to be implemented by the inheriting contract to setup the template
    function _templateSetup(string memory taskConfigFilePath) internal virtual;

    /// @notice get the calldata to be executed by safe
    /// @dev callable only after the build function has been run and the
    /// calldata has been loaded up to storage
    /// @return data The calldata to be executed
    function getCalldata() public view override returns (bytes memory data) {
        /// get task actions
        (address[] memory targets, uint256[] memory values, bytes[] memory arguments) = getProposalActions();

        /// create calls array with targets and arguments
        Call3Value[] memory calls = new Call3Value[](targets.length);

        for (uint256 i; i < calls.length; i++) {
            require(targets[i] != address(0), "Invalid target for multisig");
            calls[i] = Call3Value({target: targets[i], allowFailure: false, value: values[i], callData: arguments[i]});
        }

        /// generate calldata
        data = abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
    }

    /// @notice print the data to sig by EOA for single multisig
    function printDataToSign() public view {
        console.logBytes(_getDataToSign(multisig, getCalldata()));
    }

    /// @notice print the hash to approve by EOA for single multisig
    function printHashToApprove() public view {
        console.logBytes32(getHash());
    }

    /// @notice get the data to sign by EOA for single multisig
    /// @param data The calldata to be executed
    /// @return The data to sign
    function _getDataToSign(address safe, bytes memory data) internal view returns (bytes memory) {
        uint256 useNonce;

        if (safe == multisig) {
            useNonce = nonce;
        } else {
            useNonce = IGnosisSafe(safe).nonce();
        }

        return IGnosisSafe(safe).encodeTransactionData({
            to: MULTICALL3_ADDRESS,
            value: 0,
            data: data,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: useNonce
        });
    }

    /// @notice simulate the task by approving from owners and then executing
    function simulate() public override {
        bytes memory data = getCalldata();
        bytes32 hash = getHash();

        // Approve the hash from each owner
        address[] memory owners = IGnosisSafe(multisig).getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            vm.prank(owners[i]);
            IGnosisSafe(multisig).approveHash(hash);
        }

        bytes memory signatures = prepareSignatures(multisig, hash);

        bytes32 txHash = IGnosisSafe(multisig).getTransactionHash(
            MULTICALL3_ADDRESS, 0, data, Enum.Operation.DelegateCall, 0, 0, 0, address(0), payable(address(0)), nonce
        );

        require(hash == txHash, "MultisigTask: hash mismatch");

        // Execute the transaction
        (bool success) = IGnosisSafe(multisig).execTransaction(
            MULTICALL3_ADDRESS,
            0,
            data,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            signatures
        );

        require(success, "MultisigTask: simulateActions failed");
    }

    /// @notice returns the allowed storage accesses
    /// @return _allowedStorageAccesses The allowed storage accesses
    function getAllowedStorageAccess() public view override returns (address[] memory) {
        return _allowedStorageAccesses.values();
    }

    /// @notice execute post-task checks.
    ///          e.g. read state variables of the deployed contracts to make
    ///          sure they are deployed and initialized correctly, or read
    ///          states that are expected to have changed during the simulate step.
    function validate() public view override {
        /// check that all state change addresses are in allowed storage accesses
        for (uint256 i; i < _taskStateChangeAddresses.length(); i++) {
            address addr = _taskStateChangeAddresses.at(i);
            require(
                _allowedStorageAccesses.contains(addr),
                string(
                    abi.encodePacked(
                        "MultisigTask: address ", _getAddressLabel(addr), " not in allowed storage accesses"
                    )
                )
            );
        }

        /// check that all allowed storage accesses are in task state change addresses
        for (uint256 i; i < _allowedStorageAccesses.length(); i++) {
            address addr = _allowedStorageAccesses.at(i);
            require(
                _taskStateChangeAddresses.contains(addr),
                string(
                    abi.encodePacked(
                        "MultisigTask: address ", _getAddressLabel(addr), " not in task state change addresses"
                    )
                )
            );
        }

        require(IGnosisSafe(multisig).nonce() == nonce + 1, "MultisigTask: nonce not incremented");

        Addresses.ChainInfo[] memory chains = addresses.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            _validate(chains[i].chainId);
        }
    }

    /// @notice task specific validations
    /// @dev override to add additional task specific validations
    /// @param chainId The l2chainId
    function _validate(uint256 chainId) internal view virtual;

    /// @notice get task actions
    /// @return targets The targets of the actions
    /// @return values The values of the actions
    /// @return arguments The arguments of the actions
    function getProposalActions()
        public
        view
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory arguments)
    {
        uint256 actionsLength = actions.length;
        require(actionsLength > 0, "No actions found");

        targets = new address[](actionsLength);
        values = new uint256[](actionsLength);
        arguments = new bytes[](actionsLength);

        for (uint256 i; i < actionsLength; i++) {
            require(actions[i].target != address(0), "Invalid target for task");
            /// if there are no args and no eth, the action is not valid
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
    function build() public override buildModifier {
        Addresses.ChainInfo[] memory chains = addresses.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            _build(chains[i].chainId);
        }
    }

    /// @notice build the task actions for a given l2chain
    /// @dev override to add additional task specific build logic
    function _build(uint256 chainId) internal virtual;

    /// @notice print task description, actions, transfers, state changes and EOAs datas to sign
    function print() public virtual override {
        console.log("\n------------------ Proposal Actions ------------------");
        for (uint256 i; i < actions.length; i++) {
            console.log("%d). %s", i + 1, actions[i].description);
            console.log("target: %s\npayload", _getAddressLabel(actions[i].target));
            console.logBytes(actions[i].arguments);
            console.log("\n");
        }

        console.log("\n----------------- Proposal Transfers -------------------");
        if (_taskTransferFromAddresses.length() == 0) {
            console.log("\nNo Transfers\n");
        }
        for (uint256 i; i < _taskTransferFromAddresses.length(); i++) {
            address account = _taskTransferFromAddresses.at(i);

            console.log("\n\n", string(abi.encodePacked(_getAddressLabel(account), ":")));

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
                                "Sent ", vm.toString(transfers[j].value), " ETH to ", _getAddressLabel(transfers[j].to)
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
                                _getAddressLabel(transfers[j].tokenAddress),
                                " to ",
                                _getAddressLabel(transfers[j].to)
                            )
                        )
                    );
                }
            }
        }

        console.log("\n----------------- Proposal State Changes -------------------");
        // print state changes
        for (uint256 k; k < _taskStateChangeAddresses.length(); k++) {
            address account = _taskStateChangeAddresses.at(k);
            StateInfo[] memory stateChanges = _stateInfos[account];
            if (stateChanges.length > 0) {
                console.log("\n State Changes for account:", _getAddressLabel(account));
            }
            for (uint256 j; j < stateChanges.length; j++) {
                console.log("Slot:", vm.toString(stateChanges[j].slot));
                console.log("- ", vm.toString(stateChanges[j].oldValue));
                console.log("+ ", vm.toString(stateChanges[j].newValue));
            }
        }

        _printProposalCalldata();

        if (isNestedSafe) {
            console.log("\n\n------------------ Nested Multisig EOAs Data to Sign ------------------");
            printNestedDataToSign();
            // todo: check with op team if this is required
            console.log("\n\n------------------ Nested Multisig EOAs Hash to Approve ------------------");
            printNestedHashToApprove();
        } else {
            console.log("\n\n------------------ Single Multisig EOA Data to Sign ------------------");
            printDataToSign();
            // todo: check with op team if this is required
            console.log("\n\n------------------ Single Multisig EOA Hash to Approve ------------------");
            printHashToApprove();
        }
    }

    /// @notice print the data to sign by EOA for nested multisig
    function printNestedDataToSign() public view {
        bytes memory callData = _generateApproveMulticallData();

        for (uint256 i; i < startingOwners.length; i++) {
            bytes memory dataToSign = _getDataToSign(startingOwners[i], callData);
            console.log("Nested multisig: %s", _getAddressLabel(startingOwners[i]));
            console.logBytes(dataToSign);
        }
    }

    /// @notice print the hash to approve by EOA for nested multisig
    function printNestedHashToApprove() public view {
        bytes memory callData = _generateApproveMulticallData();
        for (uint256 i; i < startingOwners.length; i++) {
            bytes32 hash = keccak256(_getDataToSign(startingOwners[i], callData));
            console.log("Nested multisig: %s", _getAddressLabel(startingOwners[i]));
            console.logBytes32(hash);
        }
    }

    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------
    /// ------------------------- Internal functions -----------------------
    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------

    /// @notice get the hash for this safe transaction
    /// can only be called after the build function, otherwise it reverts
    function getHash() internal view returns (bytes32) {
        bytes memory data = getCalldata();
        return keccak256(_getDataToSign(multisig, data));
    }

    /// @notice validate actions inclusion
    /// default implementation check for duplicate actions
    function _validateAction(address target, uint256 value, bytes memory data) internal virtual {
        uint256 actionsLength = actions.length;
        for (uint256 i = 0; i < actionsLength; i++) {
            // Check if the target, arguments and value matches with other existing actions.
            bool isDuplicateTarget = actions[i].target == target;
            bool isDuplicateArguments = keccak256(actions[i].arguments) == keccak256(data);
            bool isDuplicateValue = actions[i].value == value;

            require(!(isDuplicateTarget && isDuplicateArguments && isDuplicateValue), "Duplicated action found");
        }
    }

    /// @notice print the calldata to be executed by safe
    function _printProposalCalldata() internal virtual {
        console.log("\n\n------------------ Proposal Calldata ------------------");
        console.logBytes(getCalldata());
    }

    /// @notice helper function to generate the approveHash calldata to be executed by child multisig owner on parent multisig
    function _generateApproveMulticallData() internal view returns (bytes memory) {
        bytes32 hash = getHash();
        Call3Value memory call = Call3Value({
            target: multisig,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe(multisig).approveHash, (hash))
        });

        Call3Value[] memory calls = new Call3Value[](1);
        calls[0] = call;
        return abi.encodeWithSignature("aggregate3Value((address,bool,uint256,bytes)[])", calls);
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
        vm.startPrank(multisig);

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

        /// roll back all state changes made during the task
        require(vm.revertTo(_startSnapshot), "failed to revert back to snapshot, unsafe state to run task");

        _processStateDiffChanges(accountAccesses);

        for (uint256 i = 0; i < accountAccesses.length; i++) {
            /// store all gnosis safe storage accesses that are writes
            for (uint256 j = 0; j < accountAccesses[i].storageAccesses.length; j++) {
                if (accountAccesses[i].account == multisig && accountAccesses[i].storageAccesses[j].isWrite) {
                    _accountAccesses.push(accountAccesses[i].storageAccesses[j]);
                }
            }

            /// only care about top level calls from the multisig,
            /// static calls are ignored,
            /// calls to and from Addresses and the vm contract are ignored
            /// ignore calls to vm in the build function
            if (
                accountAccesses[i].account != address(addresses) && accountAccesses[i].account != address(vm)
                    && accountAccesses[i].accessor != address(addresses)
                    && accountAccesses[i].kind == VmSafe.AccountAccessKind.Call && accountAccesses[i].accessor == multisig
            ) {
                /// caller is multisig, not a subcall, check that this action is not duplicated
                _validateAction(accountAccesses[i].account, accountAccesses[i].value, accountAccesses[i].data);

                actions.push(
                    Action({
                        value: accountAccesses[i].value,
                        target: accountAccesses[i].account,
                        arguments: accountAccesses[i].data,
                        description: string(
                            abi.encodePacked(
                                "calling ",
                                _getAddressLabel(accountAccesses[i].account),
                                " with ",
                                vm.toString(accountAccesses[i].value),
                                " eth and ",
                                vm.toString(accountAccesses[i].data),
                                " data."
                            )
                        )
                    })
                );
            }
        }
    }

    /// @notice helper method to get transfers and state changes of task affected addresses
    function _processStateDiffChanges(VmSafe.AccountAccess[] memory accountAccesses) internal {
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
    function _processETHTransferChanges(VmSafe.AccountAccess memory accountAccess) internal {
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
    function _processERC20TransferChanges(VmSafe.AccountAccess memory accountAccess) internal {
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
    function _processStateChanges(VmSafe.StorageAccess[] memory storageAccess) internal {
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

    /// @notice helper method to get labels for addresses
    function _getAddressLabel(address contractAddress) internal view returns (string memory) {
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
}
