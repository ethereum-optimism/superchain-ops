pragma solidity 0.8.15;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IProposal} from "src/fps/proposal/IProposal.sol";
import {BytesHelper} from "src/fps/utils/BytesHelper.sol";
import {IGnosisSafe, Enum} from "src/fps/proposal/IGnosisSafe.sol";
import {NetworkTranslator} from "src/fps/utils/NetworkTranslator.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";
import {
    NONCE_OFFSET,
    SAFE_NONCE_SLOT,
    MODULES_FETCH_AMOUNT,
    FALLBACK_HANDLER_STORAGE_SLOT,
    MULTICALL3_ADDRESS,
    ETHEREUM_CHAIN_ID,
    SEPOLIA_CHAIN_ID
} from "src/fps/utils/Constants.sol";

abstract contract MultisigProposal is Test, Script, IProposal {
    using BytesHelper for bytes;
    using NetworkTranslator for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice nonce used for generating the safe transaction
    /// will be set to the value specified in the config file
    uint256 public nonce;

    /// @notice flag to determine if the safe is nested multisig
    bool public isNestedSafe;

    /// @notice flag to determine if the proposal has been initialized
    bool public initialized;

    /// @notice owners the safe started with
    address[] public startingOwners;

    /// @notice starting safe threshold
    uint256 public startingThreshold;

    /// @notice starting modules
    address[] public startingModules;

    /// @notice starting fallback handler
    address public startingFallbackHandler;

    /// @notice starting logic contract
    string public startingImplementationVersion;

    /// @notice whether or not storage besides owners and nonce is allowed to
    /// be modified with this proposal
    bool public safeConfigChangeAllowed;

    /// @notice whether or not owners are allowed to be modified with this proposal
    bool public safeOwnersChangeAllowed;

    /// @notice array of L2 ChainIds this proposal will interface with
    /// TODO populate this in constructor, reading in toml config file
    uint256[] public l2ChainIds;

    /// @notice configured chain id
    uint256 public configChainId;

    /// @notice flag to initiate pre-build mocking processes, default is true
    bool internal DO_MOCK;

    /// @notice flag to transform plain solidity code into calldata encoded for the
    /// user's governance model, default is true
    bool internal DO_BUILD;

    /// @notice flag to simulate saved actions during the `build` step, default is true
    bool internal DO_SIMULATE;

    /// @notice flag to validate the system state post-proposal simulation, default is true
    bool internal DO_VALIDATE;

    /// @notice flag to print proposal description, actions, and calldata, default is true
    bool internal DO_PRINT;

    /// @notice Addresses contract
    Addresses public addresses;

    /// @notice primary fork id
    uint256 public primaryForkId;

    /// @notice The address of the caller for the proposal
    /// is set in the multisig proposal constructor
    address public caller;

    /// @notice struct to store allowed storage accesses
    /// uses OpenZeppelin EnumerableSet for allowed storage accesses
    EnumerableSet.AddressSet private _allowedStorageAccesses;

    /// addresses that are allowed to be the receivers of delegate calls
    mapping(address => bool) private _allowedDelegateCalls;

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

    /// @notice Struct to store information about run flags
    /// @param doMock Flag to determine if the proposal should be mocked
    /// @param doBuild Flag to determine if the proposal should be built
    /// @param doSimulate Flag to determine if the proposal should be simulated
    /// @param doValidate Flag to determine if the proposal should be validated
    /// @param doPrint Flag to determine if the proposal should be printed
    struct RunFlags {
        bool doMock;
        bool doBuild;
        bool doSimulate;
        bool doValidate;
        bool doPrint;
    }

    /// @notice transfers during proposal execution
    mapping(address => TransferInfo[]) private _proposalTransfers;

    /// @notice state changes during proposal execution
    mapping(address => StateInfo[]) private _stateInfos;

    /// @notice addresses involved in state changes or token transfers
    EnumerableSet.AddressSet private _proposalTransferFromAddresses;

    /// @notice addresses whose state is updated in proposal execution
    EnumerableSet.AddressSet internal _proposalStateChangeAddresses;

    /// @notice stores the gnosis safe accesses for the proposal
    VmSafe.StorageAccess[] internal _accountAccesses;

    /// @notice starting snapshot of the contract state before the calls are made
    uint256 private _startSnapshot;

    /// @notice list of actions to be executed, regardless of proposal type
    /// they all follow the same structure
    Action[] public actions;

    /// @notice proposal name, e.g. "OIP15".
    /// @dev set in the proposal config file
    string public override name;

    /// @notice proposal description.
    /// @dev set in the proposal config file
    string public override description;

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
        string[] authorizedDelegateCalls;
        string description;
        string name;
        string safeAddressString;
        bool safeConfigChange;
        bool safeOwnersChange;
    }

    /// @notice configuration set at initialization
    TaskConfig public config;

    /// @notice flag to determine if the proposal is being simulated
    bool private _buildStarted;

    /// @notice buildModifier to be used by the build function to populate the
    /// actions array
    modifier buildModifier() {
        require(caller != address(0), "Must set addresses object for multisig address to be set");

        if (DO_SIMULATE || DO_PRINT) {
            require(DO_BUILD, "Cannot simulate/print without first building");
        }

        require(!_buildStarted, "Build already started");
        _buildStarted = true;

        _startBuild();
        _;
        _endBuild();

        _buildStarted = false;
    }

    /// @notice Initialize the proposal with task and network configuration
    /// @param taskConfigFilePath Path to the task configuration file
    /// @param networkConfigFilePath Path to the network configuration file
    /// @param _addresses Address registry contract
    function _init(string memory taskConfigFilePath, string memory networkConfigFilePath, Addresses _addresses)
        internal
    {
        require(
            !initialized && bytes(config.safeAddressString).length == 0 && address(addresses) == address(0x0),
            "MultisigProposal: already initialized"
        );
        setTaskConfig(taskConfigFilePath);
        setL2NetworksConfig(networkConfigFilePath, _addresses);
        initialized = true;
    }

    /// @notice Set the task configuration
    /// @param taskConfigFilePath Path to the task configuration file
    function setTaskConfig(string memory taskConfigFilePath) public override {
        require(
            block.chainid == ETHEREUM_CHAIN_ID || block.chainid == SEPOLIA_CHAIN_ID,
            string.concat("Unsupported network: ", vm.toString(block.chainid))
        );

        string memory taskConfigFileContents = vm.readFile(taskConfigFilePath);
        RunFlags memory runFlags = abi.decode(vm.parseToml(taskConfigFileContents, ".runFlags"), (RunFlags));
        DO_MOCK = runFlags.doMock;
        DO_BUILD = runFlags.doBuild;
        DO_SIMULATE = runFlags.doSimulate;
        DO_VALIDATE = runFlags.doValidate;
        DO_PRINT = runFlags.doPrint;

        bytes memory fileContents = vm.parseToml(taskConfigFileContents, ".task");
        config = abi.decode(fileContents, (TaskConfig));

        safeConfigChangeAllowed = config.safeConfigChange;
        safeOwnersChangeAllowed = config.safeOwnersChange;

        name = config.name;
        description = config.description;
    }

    /// @notice Sets the L2 networks configuration
    /// @param networkConfigFilePath Path to the network configuration file
    /// @param _addresses Address registry contract
    function setL2NetworksConfig(string memory networkConfigFilePath, Addresses _addresses) public override {
        addresses = _addresses;
        string memory networkConfigFileContents = vm.readFile(networkConfigFilePath);

        nonce = abi.decode(vm.parseToml(networkConfigFileContents, ".safeNonce"), (uint256));
        isNestedSafe = abi.decode(vm.parseToml(networkConfigFileContents, ".isNestedSafe"), (bool));

        /// get superchains
        Addresses.Superchain[] memory superchains = addresses.getSuperchains();
        require(superchains.length > 0, "MultisigProposal: no superchains found");

        /// check that the safe address is the same for all superchains and then set safe in storage
        caller = addresses.getAddress(config.safeAddressString, superchains[0].chainId);

        for (uint256 i = 1; i < superchains.length; i++) {
            require(
                caller == addresses.getAddress(config.safeAddressString, superchains[i].chainId),
                string.concat(
                    "MultisigProposal: safe address mismatch. Caller: ",
                    vm.getLabel(caller),
                    ". Actual address: ",
                    vm.getLabel(addresses.getAddress(config.safeAddressString, superchains[i].chainId))
                )
            );
        }

        /// Fetch starting owners, threshold, modules, fallback handler, and logic contract from the Gnosis Safe
        IGnosisSafe safe = IGnosisSafe(caller);
        startingOwners = safe.getOwners();
        startingThreshold = safe.getThreshold();
        (startingModules,) = safe.getModulesPaginated(address(0x1), MODULES_FETCH_AMOUNT);
        startingFallbackHandler = address(uint160(uint256(vm.load(caller, FALLBACK_HANDLER_STORAGE_SLOT))));
        startingImplementationVersion = safe.VERSION();

        for (uint256 i = 0; i < config.allowedStorageWriteAccesses.length; i++) {
            for (uint256 j = 0; j < superchains.length; j++) {
                _allowedStorageAccesses.add(
                    addresses.getAddress(config.allowedStorageWriteAccesses[i], superchains[j].chainId)
                );
            }
        }

        for (uint256 i = 0; i < config.authorizedDelegateCalls.length; i++) {
            for (uint256 j = 0; j < superchains.length; j++) {
                _allowedDelegateCalls[addresses.getAddress(config.authorizedDelegateCalls[i], superchains[j].chainId)] =
                    true;
            }
        }
    }

    /// @notice function to be used by forge script.
    /// @dev use flags to determine which actions to take
    ///      this function shoudn't be overriden.
    function processProposal() internal override {
        if (DO_MOCK) mock();
        if (DO_BUILD) build();
        if (DO_SIMULATE) simulate();
        if (DO_VALIDATE) validate();
        if (DO_PRINT) print();
    }

    /// @notice get the calldata to be executed by safe
    /// @return data The calldata to be executed
    function getCalldata() public view override returns (bytes memory data) {
        /// get proposal actions
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
        console.logBytes(_getDataToSign(caller, getCalldata()));
    }

    /// @notice print the hash to approve by EOA for single multisig
    function printHashToApprove() public view {
        bytes32 hash = keccak256(_getDataToSign(caller, getCalldata()));
        console.logBytes32(hash);
    }

    /// @notice get the data to sign by EOA for single multisig
    /// @param safe The address of the safe
    /// @param data The calldata to be executed
    /// @return The data to sign
    function _getDataToSign(address safe, bytes memory data) internal view returns (bytes memory) {
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
            _nonce: nonce
        });
    }

    /// @notice simulate the proposal by approving from owners and then executing
    function simulate() public override {
        address multisig = caller;

        bytes memory data = getCalldata();
        bytes32 hash = keccak256(_getDataToSign(multisig, data));

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

        require(hash == txHash, "MultisigProposal: hash mismatch");

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

        require(success, "MultisigProposal: simulateActions failed");
    }

    /// @notice returns the allowed storage accesses
    /// @return _allowedStorageAccesses The allowed storage accesses
    function getAllowedStorageAccess() public view override returns (address[] memory) {
        return _allowedStorageAccesses.values();
    }

    /// @notice execute post-proposal checks.
    ///          e.g. read state variables of the deployed contracts to make
    ///          sure they are deployed and initialized correctly, or read
    ///          states that are expected to have changed during the simulate step.
    function validate() public view override {
        /// check that all state change addresses are in allowed storage accesses
        for (uint256 i; i < _proposalStateChangeAddresses.length(); i++) {
            address addr = _proposalStateChangeAddresses.at(i);
            require(
                _allowedStorageAccesses.contains(addr),
                string(
                    abi.encodePacked(
                        "MultisigProposal: address ", _getAddressLabel(addr), " not in allowed storage accesses"
                    )
                )
            );
        }

        /// check that all allowed storage accesses are in proposal state change addresses
        for (uint256 i; i < _allowedStorageAccesses.length(); i++) {
            address addr = _allowedStorageAccesses.at(i);
            require(
                _proposalStateChangeAddresses.contains(addr),
                string(
                    abi.encodePacked(
                        "MultisigProposal: address ", _getAddressLabel(addr), " not in proposal state change addresses"
                    )
                )
            );
        }

        if (!safeOwnersChangeAllowed) {
            address[] memory owners = IGnosisSafe(caller).getOwners();
            for (uint256 i = 0; i < owners.length; i++) {
                require(owners[i] == startingOwners[i], "MultisigProposal: owner mismatch");
            }
        }

        if (!safeConfigChangeAllowed) {
            uint256 threshold = IGnosisSafe(caller).getThreshold();
            (address[] memory modules,) = IGnosisSafe(caller).getModulesPaginated(address(0x1), MODULES_FETCH_AMOUNT);
            address fallbackHandler = address(uint160(uint256(vm.load(caller, FALLBACK_HANDLER_STORAGE_SLOT))));
            string memory version = IGnosisSafe(caller).VERSION();

            require(
                keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked(startingImplementationVersion)),
                "MultisigProposal: multisig contract upgraded"
            );
            require(threshold == startingThreshold, "MultisigProposal: threshold changed");
            require(fallbackHandler == startingFallbackHandler, "MultisigProposal: fallback handler changed");

            for (uint256 i = 0; i < modules.length; i++) {
                require(modules[i] == startingModules[i], "MultisigProposal: module changed");
            }
        }

        require(IGnosisSafe(caller).nonce() == nonce + 1, "MultisigProposal: nonce not incremented");

        Addresses.Superchain[] memory superchains = addresses.getSuperchains();

        for (uint256 i = 0; i < superchains.length; i++) {
            _validate(superchains[i].chainId);
        }
    }

    /// @notice proposal specific validations
    /// @dev override to add additional proposal specific validations
    /// @param chainId The l2chainId
    function _validate(uint256 chainId) internal view virtual;

    /// @notice get proposal actions
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
            require(actions[i].target != address(0), "Invalid target for proposal");
            /// if there are no args and no eth, the action is not valid
            require(
                (actions[i].arguments.length == 0 && actions[i].value > 0) || actions[i].arguments.length > 0,
                "Invalid arguments for proposal"
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

    /// @notice helper function to mock on-chain data
    ///         e.g. pranking, etching, etc. Sets nonce to the task nonce by default
    /// @dev override to add additional mock logic
    function mock() public virtual override {
        vm.store(caller, SAFE_NONCE_SLOT, bytes32(nonce));

        Addresses.Superchain[] memory superchains = addresses.getSuperchains();

        for (uint256 i = 0; i < superchains.length; i++) {
            _mock(superchains[i].chainId);
        }
    }

    /// @notice mock state to help build the proposal actions for a given l2chain
    /// @dev override to add additional proposal specific mocks
    function _mock(uint256 chainId) internal virtual {}

    /// @notice build the proposal actions for all l2chains in the task
    /// @dev contract calls must be perfomed in plain solidity.
    ///      overriden requires using buildModifier modifier to leverage
    ///      foundry snapshot and state diff recording to populate the actions array.
    function build() public override buildModifier {
        Addresses.Superchain[] memory superchains = addresses.getSuperchains();

        for (uint256 i = 0; i < superchains.length; i++) {
            _build(superchains[i].chainId);
        }
    }

    /// @notice build the proposal actions for a given l2chain
    /// @dev override to add additional proposal specific build logic
    function _build(uint256 chainId) internal virtual;

    /// @notice print proposal description, actions, transfers, state changes and EOAs datas to sign
    function print() public virtual override {
        console.log("\n---------------- Proposal Description ----------------");
        console.log(description);

        console.log("\n------------------ Proposal Actions ------------------");
        for (uint256 i; i < actions.length; i++) {
            console.log("%d). %s", i + 1, actions[i].description);
            console.log("target: %s\npayload", _getAddressLabel(actions[i].target));
            console.logBytes(actions[i].arguments);
            console.log("\n");
        }

        console.log("\n----------------- Proposal Transfers -------------------");
        if (_proposalTransferFromAddresses.length() == 0) {
            console.log("\nNo Transfers\n");
        }
        for (uint256 i; i < _proposalTransferFromAddresses.length(); i++) {
            address account = _proposalTransferFromAddresses.at(i);

            console.log("\n\n", string(abi.encodePacked(_getAddressLabel(account), ":")));

            // print token transfers
            TransferInfo[] memory transfers = _proposalTransfers[account];
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
        for (uint256 k; k < _proposalStateChangeAddresses.length(); k++) {
            address account = _proposalStateChangeAddresses.at(k);
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

    /// @notice validate actions inclusion
    /// default implementation check for duplicate actions
    function _validateAction(address target, uint256 value, bytes memory data) internal virtual {
        uint256 actionsLength = actions.length;
        for (uint256 i = 0; i < actionsLength; i++) {
            // Check if the target, arguments and value matches with other exciting actions.
            bool isDuplicateTarget = actions[i].target == target;
            bool isDuplicateArguments = keccak256(actions[i].arguments) == keccak256(data);
            bool isDuplicateValue = actions[i].value == value;

            require(!(isDuplicateTarget && isDuplicateArguments && isDuplicateValue), "Duplicated action found");
        }
    }

    /// @notice validate actions
    function _validateActions() internal virtual {
        /// TODO implement checks for order of calls to validate different templatized operations
    }

    /// @notice print the calldata to be executed by safe
    function _printProposalCalldata() internal virtual {
        console.log("\n\n------------------ Proposal Calldata ------------------");
        console.logBytes(getCalldata());
    }

    /// @notice helper function to generate the approveHash calldata to be executed by child multisig owner on parent multisig
    function _generateApproveMulticallData() internal view returns (bytes memory) {
        bytes32 hash = keccak256(_getDataToSign(caller, getCalldata()));
        Call3Value memory call = Call3Value({
            target: caller,
            allowFailure: false,
            value: 0,
            callData: abi.encodeCall(IGnosisSafe(caller).approveHash, (hash))
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
        address[] memory approvers = getApprovers(_safe, hash);
        return genPrevalidatedSignatures(approvers);
    }

    /// @notice helper function to generate the prevalidated signatures for a given list of addresses
    function genPrevalidatedSignatures(address[] memory _addresses) internal pure returns (bytes memory) {
        LibSort.sort(_addresses);
        bytes memory signatures;
        for (uint256 i; i < _addresses.length; i++) {
            signatures = bytes.concat(signatures, genPrevalidatedSignature(_addresses[i]));
        }
        return signatures;
    }

    /// @notice helper function to generate the prevalidated signature for a given address
    function genPrevalidatedSignature(address _address) internal pure returns (bytes memory) {
        uint8 v = 1;
        bytes32 s = bytes32(0);
        bytes32 r = bytes32(uint256(uint160(_address)));
        return abi.encodePacked(r, s, v);
    }

    /// @notice helper function to get the approvers for a given hash
    function getApprovers(address _safe, bytes32 hash) internal view returns (address[] memory) {
        // get a list of owners that have approved this transaction
        IGnosisSafe safe = IGnosisSafe(_safe);
        uint256 threshold = safe.getThreshold();
        address[] memory owners = safe.getOwners();
        address[] memory approvers = new address[](threshold);
        uint256 approverIndex;
        for (uint256 i; i < owners.length; i++) {
            address owner = owners[i];
            uint256 approved = safe.approvedHashes(owner, hash);
            if (approved == 1) {
                approvers[approverIndex] = owner;
                approverIndex++;
                if (approverIndex == threshold) {
                    return approvers;
                }
            }
        }
        address[] memory subset = new address[](approverIndex);
        for (uint256 i; i < approverIndex; i++) {
            subset[i] = approvers[i];
        }
        return subset;
    }

    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------
    /// ------------------------- Private functions ------------------------
    /// --------------------------------------------------------------------
    /// --------------------------------------------------------------------

    /// @notice to be used by the build function to create a governance proposal
    /// kick off the process of creating a governance proposal by:
    ///  1). taking a snapshot of the current state of the contract
    ///  2). starting prank as the caller
    ///  3). starting a $recording of all calls created during the proposal
    function _startBuild() private {
        vm.startPrank(caller);

        _startSnapshot = vm.snapshot();

        vm.startStateDiffRecording();
    }

    /// @notice to be used at the end of the build function to snapshot
    /// the actions performed by the proposal and revert these changes
    /// then, stop the prank and record the state diffs and actions that
    /// were taken by the proposal.
    function _endBuild() private {
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();

        vm.stopPrank();

        /// roll back all state changes made during the governance proposal
        require(vm.revertTo(_startSnapshot), "failed to revert back to snapshot, unsafe state to run proposal");

        _processStateDiffChanges(accountAccesses);

        for (uint256 i = 0; i < accountAccesses.length; i++) {
            /// store all gnosis safe storage accesses that are writes
            for (uint256 j = 0; j < accountAccesses[i].storageAccesses.length; j++) {
                if (accountAccesses[i].account == caller && accountAccesses[i].storageAccesses[j].isWrite) {
                    _accountAccesses.push(accountAccesses[i].storageAccesses[j]);
                }
            }

            if (accountAccesses[i].kind == VmSafe.AccountAccessKind.DelegateCall) {
                require(
                    _allowedDelegateCalls[accountAccesses[i].account],
                    string.concat("Unauthorized DelegateCall to address ", vm.getLabel(accountAccesses[i].account))
                );
            }

            /// only care about calls from the original caller,
            /// static calls are ignored,
            /// calls to and from Addresses and the vm contract are ignored
            /// ignore calls to vm in the build function
            /// TODO should we remove this condition? it may filter out calls that we need
            if (
                accountAccesses[i].account != address(addresses) && accountAccesses[i].account != address(vm)
                    && accountAccesses[i].accessor != address(addresses)
                    && accountAccesses[i].kind == VmSafe.AccountAccessKind.Call && accountAccesses[i].accessor == caller
            ) {
                /// caller is correct, not a subcall
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

        _validateActions();
    }

    /// @notice helper method to get transfers and state changes of proposal affected addresses
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

    /// @notice helper method to get eth transfers of proposal affected addresses
    function _processETHTransferChanges(VmSafe.AccountAccess memory accountAccess) internal {
        address account = accountAccess.account;
        // get eth transfers
        if (accountAccess.value != 0) {
            // add address to proposal transfer from addresses array only if not already added
            if (!_proposalTransferFromAddresses.contains(accountAccess.accessor)) {
                _proposalTransferFromAddresses.add(accountAccess.accessor);
            }
            _proposalTransfers[accountAccess.accessor].push(
                TransferInfo({to: account, value: accountAccess.value, tokenAddress: address(0)})
            );
        }
    }

    /// @notice helper method to get ERC20 token transfers of proposal affected addresses
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

        // add address to proposal transfer from addresses array only if not already added
        if (!_proposalTransferFromAddresses.contains(from)) {
            _proposalTransferFromAddresses.add(from);
        }

        _proposalTransfers[from].push(TransferInfo({to: to, value: value, tokenAddress: accountAccess.account}));
    }

    /// @notice helper method to get state changes of proposal affected addresses
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

            // add address to proposal state change addresses array only if not already added
            if (!_proposalStateChangeAddresses.contains(account) && _stateInfos[account].length != 0) {
                _proposalStateChangeAddresses.add(account);
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
