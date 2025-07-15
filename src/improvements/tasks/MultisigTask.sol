// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {StdStyle} from "forge-std/StdStyle.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {Signatures} from "@base-contracts/script/universal/Signatures.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";
import {Action, TemplateConfig, TaskType, TaskPayload, SafeData} from "src/libraries/MultisigTypes.sol";
import {StateOverrideManager} from "src/improvements/tasks/StateOverrideManager.sol";
import {Utils} from "src/libraries/Utils.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {TaskManager} from "src/improvements/tasks/TaskManager.sol";
import {Solarray} from "lib/optimism/packages/contracts-bedrock/scripts/libraries/Solarray.sol";

type AddressRegistry is address;

abstract contract MultisigTask is Test, Script, StateOverrideManager, TaskManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using AccountAccessParser for VmSafe.AccountAccess[];
    using AccountAccessParser for VmSafe.AccountAccess;
    using StdStyle for string;

    /// @notice The root safe address for the task
    address public root; // TODO: remove this in preference of passing it as a parameter.

    /// @notice AddressesRegistry contract
    AddressRegistry public addrRegistry;

    /// @notice Configuration set by the task's template
    TemplateConfig public templateConfig;

    /// @notice The address of the multicall target for this task
    address public multicallTarget;

    /// @notice struct to store the addresses that are expected to have storage accesses
    EnumerableSet.AddressSet internal _allowedStorageAccesses;

    /// @notice struct to store the addresses that are expected to have balance changes
    EnumerableSet.AddressSet internal _allowedBalanceChanges;

    /// @notice starting snapshot of the contract state before the calls are made
    uint256 private _startSnapshot;

    /// @notice flag to determine if the task is being simulated
    uint256 private _buildStarted;

    /// ==================================================
    /// ============== EntryPoint Functions ==============
    /// ==================================================

    /// @notice Simulates the root safe transaction of the task.
    function simulate(string memory taskConfigFilePath)
        public
        returns (VmSafe.AccountAccess[] memory, Action[] memory, bytes32, bytes memory)
    {
        return _runTask(taskConfigFilePath, "", address(0), true);
    }

    /// @notice Simulates the nested safe transaction of the task.
    /// This works by printing the 'data to sign' for the nested safe which is then passed to the eip712sign binary for signing.
    function simulate(string memory taskConfigFilePath, address _childMultisig)
        public
        returns (VmSafe.AccountAccess[] memory, Action[] memory, bytes32, bytes memory)
    {
        return _runTask(taskConfigFilePath, "", _childMultisig, true);
    }

    /// @notice Simulates the nested safe transaction of the task without logging the return values to the console.
    function simulateQuietly(string memory taskConfigFilePath, address _childMultisig) public {
        _runTask(taskConfigFilePath, "", _childMultisig, true);
    }

    /// @notice Executes the root safe transaction of the task with the given configuration file path and signatures.
    function execute(string memory taskConfigFilePath, bytes memory signatures)
        public
        returns (VmSafe.AccountAccess[] memory)
    {
        (VmSafe.AccountAccess[] memory accountAccesses,,,) = _runTask(taskConfigFilePath, signatures, address(0), false);
        return accountAccesses;
    }

    /// @notice Approves the the root safe transaction from a nested safe.
    function approve(string memory taskConfigFilePath, address _childMultisig, bytes memory signatures) public {
        // TODO: Remove this when the interface tasks an array of safes.
        address[] memory childSafes = Solarray.addresses(_childMultisig);
        (TaskPayload memory payload,) = _taskSetup(taskConfigFilePath, childSafes);

        // TODO: in the future this index may be different. Any safe that is not the root safe will be eligible to approve.
        uint256 childSafeIndex = 0;
        executeTaskStep(signatures, payload, childSafeIndex);
        console.log(
            "--------- Successfully %s Child Multisig %s Approval ---------",
            _isBroadcastContext() ? "Broadcasted" : "Simulated",
            _childMultisig
        );
    }

    /// @notice Executes a task for a given safe. The 'executionSafeIdx' is the index of the safe in the payload.safes array.
    function executeTaskStep(bytes memory signatures, TaskPayload memory payload, uint256 executionSafeIdx)
        public
        returns (VmSafe.AccountAccess[] memory, bytes32 txHash_)
    {
        SafeData memory safeData = Utils.getSafeData(payload, executionSafeIdx);
        txHash_ = getHash(safeData.callData, safeData.safe, 0, safeData.nonce, payload.safes);

        // If we are simulating, we need to approve the hash from each owner.
        // Otherwise, we are executing the task and all approvals are already done.
        // No signatures means we are simulating.
        if (signatures.length == 0) {
            address[] memory owners = IGnosisSafe(safeData.safe).getOwners();
            for (uint256 i = 0; i < owners.length; i++) {
                vm.prank(owners[i]);
                IGnosisSafe(safeData.safe).approveHash(txHash_);
                // Manually increment the nonce for each owner. If we executed the approveHash function from the owner directly (contract or EOA),
                // the nonce would be incremented by 1 and we wouldn't have to do this manually.
                _incrementOwnerNonce(owners[i]);
            }
            signatures = _prepareSignatures(safeData.safe, txHash_);
        } else {
            // If signatures are attached, this means EOA's have signed, so we order the signatures.
            signatures = Signatures.sortUniqueSignatures(
                safeData.safe, signatures, txHash_, IGnosisSafe(safeData.safe).getThreshold(), signatures.length
            );
        }

        address safeMulticallTarget;
        if (executionSafeIdx == payload.safes.length - 1) {
            safeMulticallTarget = _getMulticallAddress(safeData.safe, payload.safes);
        } else {
            safeMulticallTarget = MULTICALL3_ADDRESS; // For any non-root safe, we use the multicall3 address.
        }

        bytes32 recomputedHash = IGnosisSafe(safeData.safe).getTransactionHash(
            safeMulticallTarget,
            0,
            safeData.callData,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            safeData.nonce
        );

        require(recomputedHash == txHash_, "MultisigTask: hash mismatch");

        vm.startStateDiffRecording();

        _execTransaction(
            safeData.safe, safeMulticallTarget, 0, safeData.callData, Enum.Operation.DelegateCall, signatures
        );

        return (vm.stopAndReturnStateDiff(), txHash_);
    }

    /// ==================================================
    /// ============== Public Misc Functions =============
    /// ==================================================

    /// @notice Returns the allowed storage accesses.
    function getAllowedStorageAccess() public view returns (address[] memory) {
        return _allowedStorageAccesses.values();
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

    /// @notice Build the task actions for all l2chains in the task.
    /// Contract calls must be performed in plain solidity.
    function build(address rootSafe) public returns (Action[] memory actions) {
        require(rootSafe != address(0), "Must set address registry for multisig address to be set");
        require(_buildStarted == uint256(0), "Build already started");

        _buildStarted = 1;

        _startBuild(rootSafe);
        _build(rootSafe);
        actions = _endBuild(rootSafe);

        _buildStarted = 0;

        return actions;
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

    /// @notice Get the hash for this safe transaction.
    function getHash(
        bytes memory callData,
        address safe,
        uint256 value,
        uint256 originalNonce,
        address[] memory allSafes
    ) public view returns (bytes32) {
        address multicallAddress = _getMulticallAddress(safe, allSafes);
        return keccak256(
            GnosisSafeHashes.getEncodedTransactionData(safe, callData, value, originalNonce, multicallAddress)
        );
    }

    /// @notice Get the safe address string from the config file. If the string is not found, use the value from the template.
    function loadSafeAddressString(MultisigTask task, string memory taskConfigFilePath)
        public
        view
        returns (string memory)
    {
        string memory file = vm.readFile(taskConfigFilePath);
        try vm.parseTomlString(file, ".safeAddressString") returns (string memory _safeAddressString) {
            console.log(
                vm.toUppercase("[INFO]").green().bold(),
                "Safe address string found in config file, this takes precedence over the template value:",
                _safeAddressString
            );
            return _safeAddressString;
        } catch (bytes memory) {
            return task.safeAddressString();
        }
    }

    /// @notice Execute post-task checks. e.g. read state variables of the deployed contracts to make
    /// sure they are deployed and initialized correctly, or read states that are expected to have changed during the simulate step.
    function validate(
        VmSafe.AccountAccess[] memory accountAccesses,
        Action[] memory actions,
        TaskPayload memory payload
    ) public virtual {
        uint256 rootSafeIndex = payload.safes.length - 1;
        address rootSafe = payload.safes[rootSafeIndex];
        uint256 originalRootSafeNonce = payload.originalNonces[rootSafeIndex];
        address[] memory accountsWithWrites = accountAccesses.getUniqueWrites(false);
        // By default, we allow storage accesses to newly created contracts.
        address[] memory newContracts = accountAccesses.getNewContracts();

        for (uint256 i; i < accountsWithWrites.length; i++) {
            address addr = accountsWithWrites[i];
            require(
                _allowedStorageAccesses.contains(addr) || Utils.contains(newContracts, addr),
                string(
                    abi.encodePacked(
                        "MultisigTask: address ",
                        MultisigTaskPrinter.getAddressLabel(addr),
                        " not in allowed storage accesses"
                    )
                )
            );
        }

        require(IGnosisSafe(rootSafe).nonce() == originalRootSafeNonce + 1, "MultisigTask: nonce not incremented");

        _validate(accountAccesses, actions, rootSafe);

        _checkStateDiff(accountAccesses);
    }

    /// @notice Get the build started flag. Useful for finding slot number of state variable using StdStorage.
    function getBuildStarted() public view returns (uint256) {
        return _buildStarted;
    }

    /// @notice Get the start snapshot. Useful for finding slot number of state variable using StdStorage.
    function getStartSnapshot() public view returns (uint256) {
        return _startSnapshot;
    }

    /// @notice This function builds a series of nested transactions where each safe in the chain
    /// must approve the transaction of the next safe, creating a left-to-right execution
    /// dependency. The rightmost safe executes the actual actions, while all preceding
    /// safes generate approval transactions for their successor.
    /// Vendored from: https://github.com/base/contracts/blob/ea4a921ba601b1c385a363777d6fc52b7392327b/script/universal/MultisigScript.sol#L335-L358
    function transactionDatas(Action[] memory _actions, address[] memory _allSafes, uint256[] memory _originalNonces)
        public
        view
        returns (bytes[] memory calldatas_)
    {
        // The very last call is the actual (aggregated) call to execute
        calldatas_ = new bytes[](_allSafes.length);
        calldatas_[calldatas_.length - 1] = _getMulticall3Calldata(_actions);

        // The first n-1 calls are the nested approval calls
        for (uint256 i = _allSafes.length - 1; i > 0; i--) {
            address targetSafe = _allSafes[i];
            bytes memory callToApprove = calldatas_[i];

            calldatas_[i - 1] = _generateApproveCalldata(targetSafe, callToApprove, 0, _originalNonces[i], _allSafes);
        }
    }

    /// ==================================================
    /// =============== Internal Functions ===============
    /// ==================================================

    /// @notice Get the calldata to be executed by the root safe.
    function _getMulticall3Calldata(Action[] memory actions) internal view virtual returns (bytes memory data) {
        (address[] memory targets, uint256[] memory values, bytes[] memory arguments) = processTaskActions(actions);
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](targets.length);

        for (uint256 i; i < calls.length; i++) {
            require(targets[i] != address(0), "Invalid target for multisig");
            calls[i] = IMulticall3.Call3Value({
                target: targets[i],
                allowFailure: false,
                value: values[i],
                callData: arguments[i]
            });
        }

        data = abi.encodeCall(IMulticall3.aggregate3Value, (calls));
    }

    /// @notice Validate that the safes are in the correct order.
    function _validateSafes(address[] memory _allSafes) private view {
        require(_allSafes.length > 0, "MultisigTask: no safes provided");
        // TODO: remove this check once we support an arbitrary number of safes in the future.
        require(_allSafes.length <= 2, "MultisigTask: currently only supports 1 level of nesting.");
        for (uint256 i = 1; i < _allSafes.length; i++) {
            require(
                IGnosisSafe(_allSafes[i]).isOwner(_allSafes[i - 1]),
                string.concat(
                    "MultisigTask: Safe ",
                    vm.toString(_allSafes[i - 1]),
                    " is not an owner of ",
                    vm.toString(_allSafes[i])
                )
            );
        }
    }

    /// @notice Validate that the payload is valid.
    function _validatePayload(TaskPayload memory payload) internal view {
        // All arrays must be the same length.
        require(payload.calldatas.length == payload.safes.length, "MultisigTask: datas and safes length mismatch");
        require(
            payload.calldatas.length == payload.originalNonces.length, "MultisigTask: datas and nonces length mismatch"
        );
        require(payload.calldatas.length > 0, "MultisigTask: no calldatas provided");
        // TODO: remove this check once we support an arbitrary number of safes in the future.
        require(payload.calldatas.length <= 2, "MultisigTask: currently only supports 1 level of nesting.");
        _validateSafes(payload.safes);

        // For nested calls, validate that each predecessor contains the hash of its successor
        if (payload.calldatas.length > 1) {
            for (uint256 i = 0; i < payload.calldatas.length - 1; i++) {
                bytes memory predecessorCalldata = payload.calldatas[i];
                bytes memory successorCalldata = payload.calldatas[i + 1];
                address successorSafe = payload.safes[i + 1];
                uint256 successorNonce = payload.originalNonces[i + 1];

                bytes32 hashFromPredecessor = GnosisSafeHashes.decodeMulticallApproveHash(predecessorCalldata);
                bytes32 expectedSuccessorHash =
                    getHash(successorCalldata, successorSafe, 0, successorNonce, payload.safes);
                require(
                    hashFromPredecessor == expectedSuccessorHash,
                    "MultisigTask: predecessor hash does not match successor hash"
                );
            }
        }
    }

    /// @notice Prank as the multisig. Override to prank with delegatecall flag set to true in case of OPCM tasks.
    function _prankMultisig(address rootSafe) internal virtual {
        vm.startPrank(rootSafe);
    }

    /// @notice Helper function to prepare the signatures to be executed.
    function _prepareSignatures(address _safe, bytes32 hash) internal view returns (bytes memory) {
        // prepend the prevalidated signatures to the signatures
        address[] memory approvers = Signatures.getApprovers(_safe, hash);
        return Signatures.genPrevalidatedSignatures(approvers);
    }

    /// @notice Returns true if the given account access should be recorded as an action. This function is used to filter out
    /// actions that we defined in the `_build` function of our template. The actions selected by this function will get executed
    /// by the relevant Multicall3 contract (e.g. `Multicall3` or `Multicall3DelegateCall`).
    function _isValidAction(VmSafe.AccountAccess memory access, uint256 topLevelDepth, address rootSafe)
        internal
        view
        returns (bool)
    {
        bool accountNotRegistryOrVm =
            (access.account != AddressRegistry.unwrap(addrRegistry) && access.account != address(vm));
        bool accessorNotRegistry = access.accessor != AddressRegistry.unwrap(addrRegistry);
        bool isCall = (access.kind == VmSafe.AccountAccessKind.Call && access.depth == topLevelDepth);
        bool isTopLevelDelegateCall =
            (access.kind == VmSafe.AccountAccessKind.DelegateCall && access.depth == topLevelDepth);
        bool accessorIsRootSafe = (access.accessor == rootSafe);
        return accountNotRegistryOrVm && accessorNotRegistry && (isCall || isTopLevelDelegateCall) && accessorIsRootSafe;
    }

    /// @notice This function performs basic checks on the state diff.
    /// It checks that all touched accounts have code, that the balances are unchanged if not expected, and that no self-destructs occurred.
    function _checkStateDiff(VmSafe.AccountAccess[] memory accountAccesses) internal view {
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
                if (!Utils.contains(newContracts, accountAccess.account)) {
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
                if (Utils.isLikelyAddressThatShouldHaveCode(value, _getCodeExceptions())) {
                    // Log account, slot, and value if there is no code.
                    // forgefmt: disable-start
                    string memory err = string.concat("Likely address in storage has no code\n", "  account: ", vm.toString(account), "\n  slot:    ", vm.toString(storageAccess.slot), "\n  value:   ", vm.toString(bytes32(value)));
                    // forgefmt: disable-end
                    require(address(uint160(value)).code.length != 0, err);
                } else {
                    // Log account, slot, and value if there is code.
                    // forgefmt: disable-start
                    string memory err = string.concat("Likely address in storage has unexpected code\n", "  account: ", vm.toString(account), "\n  slot:    ", vm.toString(storageAccess.slot), "\n  value:   ", vm.toString(bytes32(value)));
                    // forgefmt: disable-end
                    require(address(uint160(value)).code.length == 0, err);
                }
                require(account.code.length != 0, string.concat("Storage account has no code: ", vm.toString(account)));
                require(!storageAccess.reverted, string.concat("Storage access reverted: ", vm.toString(account)));
                bool allowed;
                for (uint256 k; k < allowedAccesses.length; k++) {
                    allowed = allowed || (account == allowedAccesses[k]) || Utils.contains(newContracts, account);
                }
                require(allowed, string.concat("Unallowed Storage access: ", vm.toString(account)));
            }
        }
    }

    /// @notice Helper function that returns whether or not the current context is a broadcast context.
    function _isBroadcastContext() internal view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptBroadcast) || vm.isContext(VmSafe.ForgeContext.ScriptResume);
    }

    /// @notice Executes a transaction to the target multisig.
    function _execTransaction(
        address multisig,
        address target,
        uint256 value,
        bytes memory data,
        Enum.Operation operationType,
        bytes memory signatures
    ) internal {
        if (_isBroadcastContext()) {
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

    /// @notice To show the full transaction trace in Tenderly, we build custom calldata
    /// that shows both the child multisig approving the hash, as well as the root safe
    /// executing the task. This is only used when simulating a nested multisig.
    function _getNestedSimulationMulticall3Calldata(address[] memory allSafes, bytes[] memory allCalldatas)
        internal
        view
        returns (bytes memory data)
    {
        // TODO: support arbitrary number of safes.
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](2);

        address childSafe = allSafes[0];
        bytes memory childSafeCalldata = allCalldatas[0];
        bytes memory approveHashExec = GnosisSafeHashes.encodeExecTransactionCalldata(
            childSafe, childSafeCalldata, Signatures.genPrevalidatedSignature(MULTICALL3_ADDRESS), MULTICALL3_ADDRESS
        );
        calls[0] = IMulticall3.Call3Value({target: childSafe, allowFailure: false, value: 0, callData: approveHashExec});

        address rootSafe = allSafes[allSafes.length - 1];
        bytes memory rootSafeCalldata = allCalldatas[allCalldatas.length - 1];
        bytes memory customExec = GnosisSafeHashes.encodeExecTransactionCalldata(
            rootSafe,
            rootSafeCalldata,
            Signatures.genPrevalidatedSignature(childSafe),
            _getMulticallAddress(rootSafe, allSafes)
        );
        calls[1] = IMulticall3.Call3Value({target: rootSafe, allowFailure: false, value: 0, callData: customExec});

        return abi.encodeCall(IMulticall3.aggregate3Value, (calls));
    }

    /// @notice Runs the task with the given configuration file path.
    function _runTask(
        string memory _taskConfigFilePath,
        bytes memory _signatures,
        address _optionalChildMultisig,
        bool isSimulate
    )
        internal
        returns (VmSafe.AccountAccess[] memory, Action[] memory, bytes32 normalizedHash_, bytes memory dataToSign_)
    {
        // TODO: Remove this when the interface tasks an array of safes.
        address[] memory childSafes;
        if (_optionalChildMultisig != address(0)) {
            childSafes = new address[](1);
            childSafes[0] = _optionalChildMultisig;
        } else {
            childSafes = new address[](0);
        }

        (TaskPayload memory payload, Action[] memory actions) = _taskSetup(_taskConfigFilePath, childSafes);
        uint256 rootSafeIndex = payload.safes.length - 1;
        (VmSafe.AccountAccess[] memory accountAccesses, bytes32 txHash) =
            executeTaskStep(_signatures, payload, rootSafeIndex);

        validate(accountAccesses, actions, payload);
        (normalizedHash_, dataToSign_) = print(accountAccesses, isSimulate, txHash, payload);

        // Sanity check that the root safe is a nested safe.
        if (payload.safes.length > 1) {
            require(isNestedSafe(payload.safes[rootSafeIndex]), "MultisigTask: multisig must be a nested safe.");
        }

        return (accountAccesses, actions, normalizedHash_, dataToSign_);
    }

    /// @notice Using the tasks config.toml file, this function configures the task.
    function _taskSetup(string memory _taskConfigFilePath, address[] memory _childSafes)
        internal
        returns (TaskPayload memory payload_, Action[] memory actions_)
    {
        require(root == address(0), "MultisigTask: already initialized");
        templateConfig.safeAddressString = loadSafeAddressString(MultisigTask(address(this)), _taskConfigFilePath);
        IGnosisSafe _root;
        (addrRegistry, _root, multicallTarget) = _configureTask(_taskConfigFilePath);
        root = address(_root);

        // Appends the root safe. The earlier a safe address appears in the array, the deeper its level of nesting.
        address[] memory allSafes = Solarray.extend(_childSafes, Solarray.addresses(root));

        templateConfig.allowedStorageKeys = _taskStorageWrites();
        templateConfig.allowedStorageKeys.push(templateConfig.safeAddressString);
        templateConfig.allowedBalanceChanges = _taskBalanceChanges();

        _templateSetup(_taskConfigFilePath, root);
        (uint256[] memory allOriginalNonces) = _overrideState(_taskConfigFilePath, allSafes); // Overrides only matter for simulation and signing.

        vm.label(AddressRegistry.unwrap(addrRegistry), "AddrRegistry");
        vm.label(address(this), "MultisigTask");

        actions_ = build(root);
        bytes[] memory allCalldatas = transactionDatas(actions_, allSafes, allOriginalNonces);
        payload_ = TaskPayload({safes: allSafes, calldatas: allCalldatas, originalNonces: allOriginalNonces});
        _validatePayload(payload_);
    }

    /// @notice Get the multicall address for the given safe. Override to return required multicall address.
    function _getMulticallAddress(address safe, address[] memory) internal view virtual returns (address) {
        require(safe != address(0), "Safe address cannot be zero address");
        return multicallTarget;
    }

    /// @notice Creates calldata for a safe to pre-approve a transaction that will be
    /// executed by a safe higher in the hierarchy chain.
    function _generateApproveCalldata(
        address _safe,
        bytes memory _data,
        uint256 _value,
        uint256 _originalNonce,
        address[] memory allSafes
    ) internal view returns (bytes memory) {
        bytes32 hash = getHash(_data, _safe, _value, _originalNonce, allSafes);
        IMulticall3.Call3Value[] memory approvalCall = new IMulticall3.Call3Value[](1);
        approvalCall[0] = IMulticall3.Call3Value({
            target: _safe,
            allowFailure: false,
            value: _value,
            callData: abi.encodeCall(IGnosisSafe(_safe).approveHash, (hash))
        });
        return abi.encodeCall(IMulticall3.aggregate3Value, (approvalCall));
    }

    /// ==================================================
    /// =============== Private Functions ================
    /// ==================================================

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

    /// @notice to be used by the build function to capture the state changes applied by a given task.
    /// These state changes will inform whether or not the task will be executed onchain.
    function _startBuild(address rootSafe) private {
        _prankMultisig(rootSafe);

        _startSnapshot = vm.snapshotState();

        vm.startStateDiffRecording();
    }

    /// @notice To be used at the end of the build function to snapshot the actions performed by the task and revert these changes
    /// then, stop the prank and record the state diffs and actions that were taken by the task.
    function _endBuild(address rootSafe) private returns (Action[] memory) {
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
            if (_isValidAction(accesses[i], topLevelDepth, rootSafe)) {
                validCount++;
            }
        }

        // Allocate a memory array with exactly enough room.
        Action[] memory validActions = new Action[](validCount);
        uint256 index = 0;
        for (uint256 i = 0; i < accesses.length; i++) {
            if (_isValidAction(accesses[i], topLevelDepth, rootSafe)) {
                // Ensure action uniqueness.
                validateAction(accesses[i].account, accesses[i].value, accesses[i].data, validActions);

                (string memory opStr, Enum.Operation op) = GnosisSafeHashes.getOperationDetails(accesses[i].kind);

                validActions[index] = Action({
                    value: accesses[i].value,
                    target: accesses[i].account,
                    arguments: accesses[i].data,
                    operation: op,
                    description: string(
                        abi.encodePacked(
                            opStr,
                            " ",
                            MultisigTaskPrinter.getAddressLabel(accesses[i].account),
                            " with ",
                            vm.toString(accesses[i].value),
                            " eth and ",
                            vm.toString(accesses[i].data),
                            " data."
                        )
                    )
                });
                index++;
            }
        }

        return validActions;
    }

    /// @notice Applies user-defined state overrides to the current state and stores the original nonces before simulation.
    function _overrideState(string memory _taskConfigFilePath, address[] memory _allSafes)
        private
        returns (uint256[] memory allOriginalNonces_)
    {
        _setStateOverridesFromConfig(_taskConfigFilePath); // Sets global '_stateOverrides' variable.
        allOriginalNonces_ = new uint256[](_allSafes.length);
        for (uint256 i = 0; i < _allSafes.length; i++) {
            allOriginalNonces_[i] = _getNonceOrOverride(_allSafes[i]);
            address[] memory owners = IGnosisSafe(_allSafes[i]).getOwners();
            for (uint256 j = 0; j < owners.length; j++) {
                if (owners[j].code.length > 0) _getNonceOrOverride(owners[j]); // Nonce safety checks performed for each owner that is a safe.
            }
        }
        // We must do this after setting the nonces above. It allows us to make sure we're reading the correct network state when setting the nonces.
        _applyStateOverrides(); // Applies '_stateOverrides' to the current state.
    }

    /// ==================================================
    /// =============== Print Functions ==================
    /// ==================================================

    /// @notice Print task related data for task developers and signers.
    function print(
        VmSafe.AccountAccess[] memory accountAccesses,
        bool isSimulate,
        bytes32 txHash,
        TaskPayload memory payload
    ) public view returns (bytes32 normalizedHash_, bytes memory dataToSign_) {
        console.log("");
        MultisigTaskPrinter.printWelcomeMessage();

        SafeData memory rootSafe = Utils.getSafeData(payload, payload.safes.length - 1);
        accountAccesses.decodeAndPrint(rootSafe.safe, txHash);
        MultisigTaskPrinter.printTaskCalldata(rootSafe.callData);

        // Only print safe and execution data if the task is being simulated.
        if (isSimulate) {
            for (uint256 i = payload.safes.length - 1; i >= 0; i--) {
                bytes32 safeHash =
                    getHash(payload.calldatas[i], payload.safes[i], 0, payload.originalNonces[i], payload.safes);
                console.log("");
                uint256 level = payload.safes.length - i - 1;
                MultisigTaskPrinter.printTitle(string.concat("Safe (Depth: ", vm.toString(level), ")"));
                console.log("Safe Address:   ", MultisigTaskPrinter.getAddressLabel(payload.safes[i]));
                console.log("Safe Hash:      ", vm.toString(safeHash));
                address multicallAddress = _getMulticallAddress(payload.safes[i], payload.safes);
                dataToSign_ = GnosisSafeHashes.getEncodedTransactionData(
                    payload.safes[i], payload.calldatas[i], 0, payload.originalNonces[i], multicallAddress
                );

                bool isLastTask = i == 0;
                if (isLastTask) {
                    _printLastSafe(dataToSign_, rootSafe.safe, payload);
                    break;
                }
            }
            _printTenderlySimulationData(payload);
        }
        normalizedHash_ = AccountAccessParser.normalizedStateDiffHash(accountAccesses, rootSafe.safe, txHash);
        MultisigTaskPrinter.printAuditReportInfo(normalizedHash_);
    }

    /// @notice Helper function to print the final safe information.
    function _printLastSafe(bytes memory dataToSign, address rootSafe, TaskPayload memory payload) private view {
        (bytes32 domainSeparator, bytes32 messageHash) =
            GnosisSafeHashes.getDomainAndMessageHashFromEncodedTransactionData(dataToSign);
        console.log("Domain Hash:    ", vm.toString(domainSeparator));
        console.log("Message Hash:   ", vm.toString(messageHash));
        MultisigTaskPrinter.printEncodedTransactionData(dataToSign);
        address rootMulticallTarget = _getMulticallAddress(rootSafe, payload.safes);
        address childMulticallTarget =
            payload.safes.length > 1 ? _getMulticallAddress(payload.safes[0], payload.safes) : address(0);
        MultisigTaskPrinter.printOPTxVerifyLink(block.chainid, payload, rootMulticallTarget, childMulticallTarget);
    }

    /// @notice Print the Tenderly simulation payload with the state overrides.
    function _printTenderlySimulationData(TaskPayload memory payload) internal view {
        address targetAddress;
        bytes memory finalExec;
        address rootSafe = payload.safes[payload.safes.length - 1];
        address childSafe;
        if (payload.safes.length > 1) {
            // Transaction involves multiple safes.
            targetAddress = MULTICALL3_ADDRESS;
            finalExec = _getNestedSimulationMulticall3Calldata(payload.safes, payload.calldatas);
            childSafe = payload.safes[0];
        } else {
            // Transaction involves a single safe.
            targetAddress = rootSafe;
            finalExec = GnosisSafeHashes.encodeExecTransactionCalldata(
                targetAddress,
                payload.calldatas[payload.calldatas.length - 1],
                Signatures.genPrevalidatedSignature(msg.sender),
                _getMulticallAddress(rootSafe, payload.safes)
            );
        }

        MultisigTaskPrinter.printTenderlySimulationData(
            targetAddress, finalExec, msg.sender, getStateOverrides(rootSafe, childSafe)
        );
    }

    /// ==================================================
    /// ============ Functions To Implement ==============
    /// ==================================================

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
    function _getCodeExceptions() internal view virtual returns (address[] memory);

    /// @notice Different tasks have different inputs. A task template will create the appropriate
    /// storage structures for storing and accessing these inputs. In this method, you read in the
    /// task config file, parse the inputs from the TOML as needed, and save them off.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal virtual;

    /// @notice This method is responsible for deploying the required address registry, defining
    /// the root safe address, and setting the multicall target address.
    /// This method may also set any allowed and expected storage accesses that are expected in all
    /// use cases of the template.
    function _configureTask(string memory configPath)
        internal
        virtual
        returns (AddressRegistry, IGnosisSafe, address);

    /// @notice This is a solidity script of the calls you want to make, and its
    /// contents are extracted into calldata for the task. WARNING: Any state written to in this function will be reverted
    /// after the build function has been run.
    function _build(address rootSafe) internal virtual;

    /// @notice Called after the build function has been run, to execute assertions on the calls and
    /// state diffs. This function is how you obtain confidence the transaction does what it's supposed to do.
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions, address rootSafe)
        internal
        view
        virtual;
}
