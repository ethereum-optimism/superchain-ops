// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {IOPContractsManager} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOPContractsManager.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MultisigTask, AddressRegistry} from "src/improvements/tasks/MultisigTask.sol";
import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";

/// @notice This contract is used for all OPCM task types. It overrides various functions in the L2TaskBase contract.
abstract contract OPCMTaskBase is L2TaskBase {
    using stdStorage for StdStorage;
    using AccountAccessParser for VmSafe.AccountAccess[];

    /// @notice The OPContractsManager address
    address public OPCM;

    /// @notice Optimism Contracts Manager Multicall3DelegateCall contract reference
    address public constant MULTICALL3_DELEGATECALL_ADDRESS = 0x93dc480940585D9961bfcEab58124fFD3d60f76a;

    /// @notice OpChainConfig struct found in the OpContractsManager contract
    struct OpChainConfig {
        // normally typed as an ISystemConfig, however ISystemConfig is an interface,
        // which is unused here, so we just store the address
        address systemConfigProxy;
        // normally typed as an IProxyAdmin, however IProxyAdmin is an interface,
        // which is unused here, so we just store the address
        address proxyAdmin;
        // normally typed as type `Claim`, however Claim is of bytes32 type
        // and we don't have to worry about the Claim type as we are not
        // calling the interface with that type
        bytes32 absolutePrestate;
    }

    /// @notice Returns the parent multisig address string identifier
    /// the parent multisig address should be same for all the l2chains in the task
    /// @return The string "ProxyAdminOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice get the calldata to be executed by safe
    /// @dev callable only after the build function has been run and the
    /// calldata has been loaded up to storage. This function uses aggregate3
    /// instead of aggregate3Value because OPCM tasks use Multicall3DelegateCall.
    /// @return data The calldata to be executed
    function getMulticall3Calldata(Action[] memory actions) public pure override returns (bytes memory data) {
        (address[] memory targets,, bytes[] memory arguments) = processTaskActions(actions);

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](targets.length);

        for (uint256 i; i < calls.length; i++) {
            require(targets[i] != address(0), "Invalid target for multisig");
            calls[i] = IMulticall3.Call3({target: targets[i], allowFailure: false, callData: arguments[i]});
        }

        data = abi.encodeWithSignature("aggregate3((address,bool,bytes)[])", calls);
    }

    function validate(VmSafe.AccountAccess[] memory accesses, Action[] memory actions) public override {
        (address[] memory targets,,) = processTaskActions(actions);
        require(targets.length == 1 && targets[0] == OPCM, "OPCMTaskBase: only OPCM is allowed as target");
        super.validate(accesses, actions);
        AccountAccessParser.StateDiff[] memory parentMultisigDiffs = accesses.getStateDiffFor(parentMultisig, false);
        require(
            parentMultisigDiffs.length == 1, "OPCMTaskBase: only nonce should be updated on upgrade controller multisig"
        );

        AccountAccessParser.StateDiff[] memory opcmDiffs = accesses.getStateDiffFor(OPCM, false);
        bytes32 opcmStateSlot = bytes32(uint256(stdstore.target(OPCM).sig(IOPContractsManager.isRC.selector).find()));
        require(opcmDiffs.length <= 1, "OPCMTaskBase: OPCM must have at most 1 state change");
        // Not all invocations of OPCM upgrade will have the isRC state change. This is because it only happens when
        // address(this) is equal to the OPCMs 'upgradeController' address (which is an immutable).
        if (opcmDiffs.length == 1) {
            AccountAccessParser.StateDiff memory opcmDiff = opcmDiffs[0];
            require(opcmDiff.slot == opcmStateSlot, "OPCMTaskBase: Incorrect OPCM isRc slot");
            require(opcmDiff.oldValue == bytes32(uint256(1)), "OPCMTaskBase: Incorrect OPCM isRc old value");
            require(opcmDiff.newValue == bytes32(uint256(0)), "OPCMTaskBase: Incorrect OPCM isRc new value");
        }
    }

    /// @notice get the multicall address for the given safe
    /// if the safe is the parent multisig, return the delegatecall multicall address
    /// otherwise if the safe is a child multisig, return the regular multicall address
    /// @param safe The address of the safe
    /// @return The address of the multicall
    function _getMulticallAddress(address safe) internal view override returns (address) {
        require(safe != address(0), "Safe address cannot be zero address");
        return (safe == parentMultisig) ? MULTICALL3_DELEGATECALL_ADDRESS : MULTICALL3_ADDRESS;
    }

    function _configureTask(string memory taskConfigFilePath)
        internal
        override
        returns (AddressRegistry addrRegistry_, IGnosisSafe parentMultisig_, address multicallTarget_)
    {
        // The only thing we change is overriding the multicall target.
        (addrRegistry_, parentMultisig_, multicallTarget_) = super._configureTask(taskConfigFilePath);
        multicallTarget_ = MULTICALL3_DELEGATECALL_ADDRESS;
    }

    /// @notice Prank as the multisig.
    function _prankMultisig() internal override {
        // If delegateCall value is true then sets msg.sender for all subsequent delegate calls.
        // We want this functionality for OPCM tasks.
        vm.startPrank(parentMultisig, true);
    }

    /// @notice this function must be overridden in the inheriting contract to run assertions on the state changes.
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions)
        internal
        view
        virtual
        override
    {
        accountAccesses; // No-ops to silence unused variable compiler warnings.
        actions;
        require(false, "You must implement the _validate function");
    }

    /// @notice Returns the type of task.
    function taskType() public pure override returns (TaskType) {
        return TaskType.OPCMTaskBase;
    }
}
