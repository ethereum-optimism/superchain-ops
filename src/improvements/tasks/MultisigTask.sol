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
import {Action, TemplateConfig, TaskType} from "src/libraries/MultisigTypes.sol";
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
    address public root;

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

    /// @notice Runs the task with the given configuration file path.
    function simulateRun(string memory taskConfigFilePath, bytes memory signatures)
        public
        returns (VmSafe.AccountAccess[] memory, Action[] memory, bytes32, bytes memory)
    {
        return simulateRun(taskConfigFilePath, signatures, address(0));
    }

    /// @notice Runs the task with the given configuration file path.
    function simulateRun(string memory taskConfigFilePath)
        public
        returns (VmSafe.AccountAccess[] memory, Action[] memory, bytes32, bytes memory)
    {
        return simulateRun(taskConfigFilePath, "", address(0));
    }

    /// @notice Executes the task with the given configuration file path and signatures.
    function executeRun(string memory taskConfigFilePath, bytes memory signatures)
        public
        returns (VmSafe.AccountAccess[] memory)
    {
        (address[] memory allSafes, uint256[] memory allOriginalNonces) =
            _taskSetup(taskConfigFilePath, new address[](0));
        address rootSafe = allSafes[allSafes.length - 1];
        uint256 rootSafeNonce = allOriginalNonces[allOriginalNonces.length - 1];
        Action[] memory actions = build(rootSafe);
        bytes[] memory allCalldatas = calldatas(actions, allSafes, allOriginalNonces);

        (VmSafe.AccountAccess[] memory accountAccesses, bytes32 txHash) =
            execute(signatures, allSafes, allCalldatas, allOriginalNonces);

        validate(accountAccesses, actions, rootSafe, rootSafeNonce);

        print(accountAccesses, false, txHash, allSafes, allCalldatas, allOriginalNonces);
        return accountAccesses;
    }

    /// @notice Child multisig of a nested multisig approves the task to be executed with the given
    /// configuration file path and signatures.
    function approveFromChildMultisig(string memory taskConfigFilePath, address _childMultisig, bytes memory signatures)
        public
    {
        // TODO: Remove this when the interface tasks an array of safes.
        address[] memory childSafes = Solarray.addresses(_childMultisig);
        (address[] memory allSafes, uint256[] memory allOriginalNonces) = _taskSetup(taskConfigFilePath, childSafes);
        address rootSafe = allSafes[allSafes.length - 1];
        Action[] memory actions = build(rootSafe);
        bytes[] memory allCalldatas = calldatas(actions, allSafes, allOriginalNonces);
        validateCalldatas(allCalldatas, allSafes, allOriginalNonces);

        approve(signatures, allSafes, allCalldatas, allOriginalNonces);
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
        returns (VmSafe.AccountAccess[] memory, Action[] memory, bytes32, bytes memory)
    {
        return simulateRun(taskConfigFilePath, "", _childMultisig);
    }

    /// @notice This function performs the same functionality as signFromChildMultisig but
    /// to keep the terminal output clean, we don't return the account accesses and actions.
    function simulateAsSigner(string memory taskConfigFilePath, address _childMultisig) public {
        simulateRun(taskConfigFilePath, "", _childMultisig);
    }

    /// @notice Child multisig approves the task to be executed.
    function approve(
        bytes memory signatures,
        address[] memory allSafes,
        bytes[] memory allCalldatas,
        uint256[] memory allOriginalNonces
    ) public {
        address childSafe = allSafes[0];
        bytes memory childSafeCalldata = allCalldatas[0];
        uint256 childSafeNonce = allOriginalNonces[0];
        bytes32 hash = keccak256(getEncodedTransactionData(childSafe, childSafeCalldata, 0, childSafeNonce, allSafes));
        signatures = Signatures.prepareSignatures(childSafe, hash, signatures);
        execTransaction(childSafe, MULTICALL3_ADDRESS, 0, childSafeCalldata, Enum.Operation.DelegateCall, signatures);
    }

    /// @notice Executes the task with the given signatures.
    function execute(
        bytes memory signatures,
        address[] memory allSafes,
        bytes[] memory allCalldatas,
        uint256[] memory allOriginalNonces
    ) public returns (VmSafe.AccountAccess[] memory, bytes32 txHash_) {
        address rootSafe = allSafes[allSafes.length - 1];
        bytes memory rootSafeCalldata = allCalldatas[allCalldatas.length - 1];
        uint256 rootSafeNonce = allOriginalNonces[allOriginalNonces.length - 1];
        txHash_ = getHash(rootSafeCalldata, rootSafe, 0, rootSafeNonce, allSafes);

        if (signatures.length == 0) {
            // if no signatures are attached, this means we are dealing with a
            // nested safe that should already have all of its approve hashes in
            // child multisigs signed already.
            signatures = prepareSignatures(rootSafe, txHash_);
        } else {
            // otherwise, if signatures are attached, this means EOA's have
            // signed, so we order the signatures based on how Gnosis Safe
            // expects signatures to be ordered by address cast to a number
            signatures = Signatures.sortUniqueSignatures(
                rootSafe, signatures, txHash_, IGnosisSafe(rootSafe).getThreshold(), signatures.length
            );
        }

        vm.startStateDiffRecording();

        execTransaction(rootSafe, multicallTarget, 0, rootSafeCalldata, Enum.Operation.DelegateCall, signatures);

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
        return keccak256(getEncodedTransactionData(safe, callData, value, originalNonce, allSafes));
    }

    /// @notice Creates calldata for a safe to pre-approve a transaction that will be
    /// executed by a safe higher in the hierarchy chain.
    function _generateApproveCall(
        address _safe,
        bytes memory _data,
        uint256 _value,
        uint256 _originalNonce,
        address[] memory allSafes
    ) internal view returns (IMulticall3.Call3Value memory) {
        bytes32 hash = getHash(_data, _safe, _value, _originalNonce, allSafes);
        return IMulticall3.Call3Value({
            target: _safe,
            allowFailure: false,
            value: _value,
            callData: abi.encodeCall(IGnosisSafe(_safe).approveHash, (hash))
        });
    }

    /// @notice Get the data to sign by EOA.
    function getEncodedTransactionData(
        address safe,
        bytes memory data,
        uint256 value,
        uint256 originalNonce,
        address[] memory allSafes
    ) public view returns (bytes memory encodedTxData) {
        encodedTxData = IGnosisSafe(safe).encodeTransactionData({
            to: _getMulticallAddress(safe, allSafes),
            value: value,
            data: data,
            operation: Enum.Operation.DelegateCall,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: originalNonce
        });
        require(encodedTxData.length == 66, "MultisigTask: encodedTxData length is not 66 bytes.");
    }

    /// @notice Get the build started flag. Useful for finding slot number of state variable using StdStorage.
    function getBuildStarted() public view returns (uint256) {
        return _buildStarted;
    }

    /// @notice Get the start snapshot. Useful for finding slot number of state variable using StdStorage.
    function getStartSnapshot() public view returns (uint256) {
        return _startSnapshot;
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
        address rootSafe,
        uint256 originalRootSafeNonce
    ) public virtual {
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

        checkStateDiff(accountAccesses);
    }

    /// @notice Get the multicall address for the given safe. Override to return required multicall address.
    function _getMulticallAddress(address safe, address[] memory) internal view virtual returns (address) {
        require(safe != address(0), "Safe address cannot be zero address");
        return multicallTarget;
    }

    /// ==================================================
    /// =============== Internal Functions ===============
    /// ==================================================

    /// @notice Simulate the task by approving from owners and then executing.
    function simulate(
        bytes memory _signatures,
        address[] memory _allSafes,
        bytes[] memory _datas,
        uint256[] memory _originalNonces
    ) internal returns (VmSafe.AccountAccess[] memory, bytes32 txHash_) {
        address rootSafe = _allSafes[_allSafes.length - 1];
        bytes memory callData = _datas[_allSafes.length - 1];
        uint256 rootSafeNonce = _originalNonces[_allSafes.length - 1];
        bytes32 hash = getHash(callData, rootSafe, 0, rootSafeNonce, _allSafes);
        bytes memory signatures;

        // Approve the hash from each owner
        address[] memory owners = IGnosisSafe(rootSafe).getOwners();
        if (_signatures.length == 0) {
            for (uint256 i = 0; i < owners.length; i++) {
                vm.prank(owners[i]);
                IGnosisSafe(rootSafe).approveHash(hash);
                // Manually increment the nonce for each owner. If we executed the approveHash function from the owner directly (contract or EOA),
                // the nonce would be incremented by 1 and we wouldn't have to do this manually.
                _incrementOwnerNonce(owners[i]);
            }
            // Gather signatures after approval hashes have been made
            signatures = prepareSignatures(rootSafe, hash);
        } else {
            signatures = Signatures.prepareSignatures(rootSafe, hash, _signatures);
        }

        txHash_ = IGnosisSafe(rootSafe).getTransactionHash(
            multicallTarget,
            0,
            callData,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            rootSafeNonce
        );

        require(hash == txHash_, "MultisigTask: hash mismatch");

        vm.startStateDiffRecording();
        execTransaction(rootSafe, multicallTarget, 0, callData, Enum.Operation.DelegateCall, signatures);
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();

        return (accountAccesses, txHash_);
    }

    /// @notice Get the calldata to be executed by the root safe.
    function getMulticall3Calldata(Action[] memory actions) internal view virtual returns (bytes memory data) {
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
    function validateSafes(address[] memory _allSafes) internal view {
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

    /// @notice Validate that the calldatas are in the correct order.
    function validateCalldatas(bytes[] memory _datas, address[] memory _allSafes, uint256[] memory _originalNonces)
        internal
        view
    {
        require(_datas.length > 0, "MultisigTask: no calldatas provided");
        // TODO: remove this check once we support an arbitrary number of safes in the future.
        require(_datas.length <= 2, "MultisigTask: currently only supports 1 level of nesting.");
        require(_datas.length == _allSafes.length, "MultisigTask: datas and safes length mismatch");
        require(_datas.length == _originalNonces.length, "MultisigTask: datas and nonces length mismatch");

        // For nested calls, validate that each predecessor contains the hash of its successor
        if (_datas.length > 1) {
            for (uint256 i = 0; i < _datas.length - 1; i++) {
                bytes memory predecessorCalldata = _datas[i];
                bytes memory successorCalldata = _datas[i + 1];
                address successorSafe = _allSafes[i + 1];
                uint256 successorNonce = _originalNonces[i + 1];

                bytes32 hashFromPredecessor = GnosisSafeHashes.decodeMulticallApproveHash(predecessorCalldata);
                bytes32 expectedSuccessorHash = getHash(successorCalldata, successorSafe, 0, successorNonce, _allSafes);
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

    /// @notice Helper function to get the approve hash transaction Domain Separator and Message Hash.
    function computeNestedApproveHashInfo(
        address[] memory allSafes,
        bytes[] memory allCalldatas,
        uint256[] memory allOriginalNonces
    ) internal view returns (bytes memory encodedTxData, bytes32 domainSeparator, bytes32 messageHash) {
        require(allSafes.length == 2, "MultisigTask: only supports 1 level of nesting.");
        require(allSafes.length == allCalldatas.length, "MultisigTask: allSafes and calldatas length mismatch");
        address childSafe = allSafes[0];
        bytes memory childSafeCalldata = allCalldatas[0];
        uint256 childSafeNonce = allOriginalNonces[0];
        encodedTxData = getEncodedTransactionData(childSafe, childSafeCalldata, 0, childSafeNonce, allSafes);
        (domainSeparator, messageHash) =
            GnosisSafeHashes.getDomainAndMessageHashFromEncodedTransactionData(encodedTxData);
        return (encodedTxData, domainSeparator, messageHash);
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
                if (Utils.isLikelyAddressThatShouldHaveCode(value, getCodeExceptions())) {
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

    /// @notice To show the full transaction trace in Tenderly, we build custom calldata
    /// that shows both the child multisig approving the hash, as well as the parent multisig
    /// executing the task. This is only used when simulating a nested multisig.
    function getNestedSimulationMulticall3Calldata(address[] memory allSafes, bytes[] memory allCalldatas)
        internal
        view
        returns (bytes memory data)
    {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](2);

        address childSafe = allSafes[0];
        bytes memory childSafeCalldata = allCalldatas[0];
        bytes memory approveHashExec = _execTransactionCalldata(
            childSafe, childSafeCalldata, Signatures.genPrevalidatedSignature(MULTICALL3_ADDRESS), MULTICALL3_ADDRESS
        );
        calls[0] = IMulticall3.Call3Value({target: childSafe, allowFailure: false, value: 0, callData: approveHashExec});

        address rootSafe = allSafes[allSafes.length - 1];
        bytes memory rootSafeCalldata = allCalldatas[allCalldatas.length - 1];
        bytes memory customExec = _execTransactionCalldata(
            rootSafe,
            rootSafeCalldata,
            Signatures.genPrevalidatedSignature(childSafe),
            _getMulticallAddress(rootSafe, allSafes)
        );
        calls[1] = IMulticall3.Call3Value({target: rootSafe, allowFailure: false, value: 0, callData: customExec});

        return abi.encodeCall(IMulticall3.aggregate3Value, (calls));
    }

    /// @notice Runs the task with the given configuration file path.
    /// Sets the address registry, initializes and simulates the single multisig
    /// as well as the nested multisig. For single multisig,
    /// prints the data to sign and the hash to approve which is used to sign with the eip712sign binary.
    /// For nested multisig, prints the data to sign and the hash to approve for each of the child multisigs.
    function simulateRun(string memory _taskConfigFilePath, bytes memory _signatures, address _optionalChildMultisig)
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

        (address[] memory allSafes, uint256[] memory allOriginalNonces) = _taskSetup(_taskConfigFilePath, childSafes);
        address rootSafe = allSafes[allSafes.length - 1];
        uint256 rootSafeNonce = allOriginalNonces[allOriginalNonces.length - 1];
        Action[] memory actions = build(rootSafe);
        bytes[] memory allCalldatas = calldatas(actions, allSafes, allOriginalNonces);
        validateCalldatas(allCalldatas, allSafes, allOriginalNonces);

        (VmSafe.AccountAccess[] memory accountAccesses, bytes32 txHash) =
            simulate(_signatures, allSafes, allCalldatas, allOriginalNonces);

        validate(accountAccesses, actions, rootSafe, rootSafeNonce);
        (normalizedHash_, dataToSign_) = print(accountAccesses, true, txHash, allSafes, allCalldatas, allOriginalNonces);

        // Revert with meaningful error message if the user is trying to simulate with the wrong command.
        if (allSafes.length > 1) {
            require(isNestedSafe(rootSafe), "MultisigTask: multisig must be a nested safe.");
        } else {
            require(!isNestedSafe(allSafes[0]), "MultisigTask: multisig must be a single safe.");
        }

        return (accountAccesses, actions, normalizedHash_, dataToSign_);
    }

    /// @notice Using the tasks config.toml file, this function configures the task.
    function _taskSetup(string memory _taskConfigFilePath, address[] memory _childSafes)
        internal
        returns (address[] memory allSafes_, uint256[] memory allOriginalNonces_)
    {
        require(root == address(0), "MultisigTask: already initialized");
        templateConfig.safeAddressString = loadSafeAddressString(MultisigTask(address(this)), _taskConfigFilePath);
        IGnosisSafe _rootSafe; // TODO parentMultisig should be of type IGnosisSafe
        (addrRegistry, _rootSafe, multicallTarget) = _configureTask(_taskConfigFilePath);

        // Appends the root safe. The earlier a safe address appears in the array, the deeper its level of nesting.
        allSafes_ = Solarray.extend(_childSafes, Solarray.addresses(address(_rootSafe)));
        validateSafes(allSafes_);
        root = address(_rootSafe);

        templateConfig.allowedStorageKeys = _taskStorageWrites();
        templateConfig.allowedStorageKeys.push(templateConfig.safeAddressString);
        templateConfig.allowedBalanceChanges = _taskBalanceChanges();

        _templateSetup(_taskConfigFilePath, address(_rootSafe));
        (allOriginalNonces_) = _overrideState(_taskConfigFilePath, allSafes_); // Overrides only matter for simulation and signing.

        vm.label(AddressRegistry.unwrap(addrRegistry), "AddrRegistry");
        vm.label(address(this), "MultisigTask");
    }

    /// @notice This function builds a series of nested transactions where each safe in the chain
    /// must approve the transaction of the next safe, creating a left-to-right execution
    /// dependency. The rightmost safe executes the actual actions, while all preceding
    /// safes generate approval transactions for their successor.
    function calldatas(Action[] memory _actions, address[] memory _allSafes, uint256[] memory _originalNonces)
        public
        view
        returns (bytes[] memory calldatas_)
    {
        // The very last call is the actual (aggregated) call to execute
        calldatas_ = new bytes[](_allSafes.length);
        calldatas_[calldatas_.length - 1] = getMulticall3Calldata(_actions);

        // The first n-1 calls are the nested approval calls
        for (uint256 i = _allSafes.length - 1; i > 0; i--) {
            address targetSafe = _allSafes[i];
            bytes memory callToApprove = calldatas_[i];

            IMulticall3.Call3Value[] memory approvalCall = new IMulticall3.Call3Value[](1);
            approvalCall[0] = _generateApproveCall(targetSafe, callToApprove, 0, _originalNonces[i], _allSafes);
            calldatas_[i - 1] = abi.encodeCall(IMulticall3.aggregate3Value, (approvalCall));
        }
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
        address[] memory allSafes,
        bytes[] memory allCalldatas,
        uint256[] memory allOriginalNonces
    ) public view returns (bytes32 normalizedHash_, bytes memory dataToSign_) {
        console.log("");
        MultisigTaskPrinter.printWelcomeMessage();

        address rootSafe = allSafes[allSafes.length - 1];
        accountAccesses.decodeAndPrint(rootSafe, txHash);

        return printSafe(accountAccesses, isSimulate, txHash, allSafes, allCalldatas, allOriginalNonces);
    }

    /// @notice Print the Tenderly simulation payload with the state overrides.
    function printTenderlySimulationData(address[] memory allSafes, bytes[] memory allCalldatas) internal view {
        address targetAddress;
        bytes memory finalExec;
        address rootSafe = allSafes[allSafes.length - 1];
        bytes memory rootSafeCalldata = allCalldatas[allCalldatas.length - 1];
        address childSafe;
        if (allSafes.length > 1) {
            targetAddress = MULTICALL3_ADDRESS;
            finalExec = getNestedSimulationMulticall3Calldata(allSafes, allCalldatas);
            childSafe = allSafes[0];
        } else {
            targetAddress = rootSafe;
            finalExec = _execTransactionCalldata(
                targetAddress,
                rootSafeCalldata,
                Signatures.genPrevalidatedSignature(msg.sender),
                _getMulticallAddress(rootSafe, allSafes)
            );
        }

        MultisigTaskPrinter.printTenderlySimulationData(
            targetAddress, finalExec, msg.sender, getStateOverrides(rootSafe, childSafe)
        );
    }

    /// @notice Prints all relevant hashes to sign as well as the tenderly simulation link.
    function printSafe(
        VmSafe.AccountAccess[] memory accountAccesses,
        bool isSimulate,
        bytes32 txHash,
        address[] memory allSafes,
        bytes[] memory allCalldatas,
        uint256[] memory allOriginalNonces
    ) private view returns (bytes32 normalizedHash_, bytes memory dataToSign_) {
        (address rootSafe, bytes memory rootSafeCalldata,) =
            getSafeData(allSafes, allCalldatas, allOriginalNonces, allSafes.length - 1);
        MultisigTaskPrinter.printTaskCalldata(rootSafeCalldata);

        // Only print data if the task is being simulated.
        if (isSimulate) {
            if (allSafes.length > 1) {
                dataToSign_ = printNestedData(allSafes, allCalldatas, allOriginalNonces);
            } else {
                dataToSign_ = printSingleData(allSafes, allCalldatas, allOriginalNonces);
            }

            printTenderlySimulationData(allSafes, allCalldatas);
        }
        normalizedHash_ = AccountAccessParser.normalizedStateDiffHash(accountAccesses, rootSafe, txHash);
        MultisigTaskPrinter.printAuditReportInfo(normalizedHash_);
    }

    /// @notice Helper function to get the safe, call data, and original nonce for a given index.
    function getSafeData(
        address[] memory allSafes,
        bytes[] memory allCalldatas,
        uint256[] memory allOriginalNonces,
        uint256 index
    ) private pure returns (address safe, bytes memory callData, uint256 originalNonce) {
        safe = allSafes[index];
        callData = allCalldatas[index];
        originalNonce = allOriginalNonces[index];
    }

    /// @notice Helper function to print nested calldata.
    function printNestedData(address[] memory allSafes, bytes[] memory allCalldatas, uint256[] memory allOriginalNonces)
        private
        view
        returns (bytes memory dataToSign_)
    {
        // TODO: Update this when we support more than 1 level of nesting.
        require(
            allSafes.length == 2,
            "MultisigTask: Child multisig cannot be zero address when printing nested data to sign."
        );
        (address rootSafe, bytes memory rootSafeCalldata, uint256 rootSafeNonce) =
            getSafeData(allSafes, allCalldatas, allOriginalNonces, allSafes.length - 1);
        (address childSafe,,) = getSafeData(allSafes, allCalldatas, allOriginalNonces, 0);

        bytes32 rootSafeHashToApprove = getHash(rootSafeCalldata, rootSafe, 0, rootSafeNonce, allSafes);

        (bytes memory dataToSign, bytes32 domainSeparator, bytes32 messageHash) =
            computeNestedApproveHashInfo(allSafes, allCalldatas, allOriginalNonces);
        dataToSign_ = dataToSign;

        {
            string memory rootSafeLabel = MultisigTaskPrinter.getAddressLabel(rootSafe);
            string memory childSafeLabel = MultisigTaskPrinter.getAddressLabel(childSafe);
            MultisigTaskPrinter.printNestedDataInfo(
                rootSafeLabel, childSafeLabel, rootSafeHashToApprove, dataToSign, domainSeparator, messageHash
            );
        }

        _printNestedVerifyLink(allSafes, allCalldatas, allOriginalNonces);
    }

    /// @notice Helper function to print nested verify link.
    function _printNestedVerifyLink(
        address[] memory allSafes,
        bytes[] memory allCalldatas,
        uint256[] memory allOriginalNonces
    ) private view {
        (address rootSafe, bytes memory rootSafeCalldata, uint256 rootSafeNonce) =
            getSafeData(allSafes, allCalldatas, allOriginalNonces, allSafes.length - 1);
        (address childSafe, bytes memory childSafeCalldata, uint256 childSafeNonce) =
            getSafeData(allSafes, allCalldatas, allOriginalNonces, 0);
        address rootMulticallTarget = _getMulticallAddress(rootSafe, allSafes);
        address childMulticallTarget = _getMulticallAddress(childSafe, allSafes);
        MultisigTaskPrinter.printOPTxVerifyLink(
            rootSafe,
            block.chainid,
            childSafe,
            rootSafeCalldata,
            childSafeCalldata,
            rootSafeNonce,
            childSafeNonce,
            rootMulticallTarget,
            childMulticallTarget
        );
    }

    /// @notice Helper function to print non-nested safe calldata.
    function printSingleData(address[] memory allSafes, bytes[] memory allCalldatas, uint256[] memory allOriginalNonces)
        private
        view
        returns (bytes memory dataToSign_)
    {
        address rootSafe = allSafes[allSafes.length - 1];
        bytes memory rootSafeCalldata = allCalldatas[allCalldatas.length - 1];
        uint256 rootSafeNonce = allOriginalNonces[allOriginalNonces.length - 1];

        dataToSign_ = getEncodedTransactionData(rootSafe, rootSafeCalldata, 0, rootSafeNonce, allSafes);
        // eip712sign tool looks for the output of this command.
        MultisigTaskPrinter.printEncodedTransactionData(dataToSign_);
        MultisigTaskPrinter.printTitle("SINGLE MULTISIG EOA HASH TO APPROVE");

        // Inlined from _printParentHash
        console.log("Parent Multisig: ", MultisigTaskPrinter.getAddressLabel(rootSafe));
        bytes32 safeTxHash = getHash(rootSafeCalldata, rootSafe, 0, rootSafeNonce, allSafes);
        console.log("Safe Transaction Hash: ", vm.toString(safeTxHash));

        bytes32 computedDomainSeparator = GnosisSafeHashes.calculateDomainSeparator(block.chainid, rootSafe);
        (bytes32 domainSeparator, bytes32 messageHash) =
            GnosisSafeHashes.getDomainAndMessageHashFromEncodedTransactionData(dataToSign_);
        require(domainSeparator == computedDomainSeparator, "Domain separator mismatch");
        console.log("Domain Hash:    ", vm.toString(domainSeparator));
        console.log("Message Hash:   ", vm.toString(messageHash));

        address rootMulticallTarget = _getMulticallAddress(rootSafe, allSafes);
        MultisigTaskPrinter.printOPTxVerifyLink(
            rootSafe,
            block.chainid,
            address(0), // No child multisig for single parent hash context
            rootSafeCalldata,
            hex"", // No child calldata
            rootSafeNonce,
            0, // No child nonce
            rootMulticallTarget,
            address(0) // No child multicall target
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
    function getCodeExceptions() internal view virtual returns (address[] memory);

    /// @notice Different tasks have different inputs. A task template will create the appropriate
    /// storage structures for storing and accessing these inputs. In this method, you read in the
    /// task config file, parse the inputs from the TOML as needed, and save them off.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal virtual;

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
    function _build(address rootSafe) internal virtual;

    /// @notice Called after the build function has been run, to execute assertions on the calls and
    /// state diffs. This function is how you obtain confidence the transaction does what it's supposed to do.
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions, address rootSafe)
        internal
        view
        virtual;
}
