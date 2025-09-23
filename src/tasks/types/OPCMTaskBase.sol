// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {MultisigTask} from "src/tasks/MultisigTask.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";
import {IOPContractsManager} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOPContractsManager.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Action, TaskType, TaskPayload} from "src/libraries/MultisigTypes.sol";
import {MultisigTask, AddressRegistry} from "src/tasks/MultisigTask.sol";
import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {Utils} from "src/libraries/Utils.sol";

/// @notice This contract is used for all OPCM task types. It overrides various functions in the L2TaskBase contract.
abstract contract OPCMTaskBase is L2TaskBase {
    using stdStorage for StdStorage;
    using AccountAccessParser for VmSafe.AccountAccess[];

    /// @notice The allowed targets for the OPCM task. Some OPCM templates invoked multiple OPCMs so
    /// we use an array to capture all the OPCMs that are allowed to be targeted.
    address[] public OPCM_TARGETS;

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

    /// @notice Get the calldata to be executed by the root safe.
    /// This function uses aggregate3 instead of aggregate3Value because OPCM tasks use Multicall3DelegateCall.
    function _getMulticall3Calldata(Action[] memory actions) internal pure override returns (bytes memory data) {
        (address[] memory targets,, bytes[] memory arguments) = processTaskActions(actions);
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](targets.length);

        for (uint256 i; i < calls.length; i++) {
            require(targets[i] != address(0), "Invalid target for multisig");
            calls[i] = IMulticall3.Call3({target: targets[i], allowFailure: false, callData: arguments[i]});
        }

        data = abi.encodeCall(IMulticall3.aggregate3, (calls));
    }

    /// @notice Performs base validations for the OPCM task.
    function validate(VmSafe.AccountAccess[] memory accesses, Action[] memory actions, TaskPayload memory payload)
        public
        override
    {
        (address[] memory targets,,) = processTaskActions(actions);
        requireAllowedTarget(targets, OPCM_TARGETS);
        super.validate(accesses, actions, payload);
        address rootSafe = payload.safes[payload.safes.length - 1];
        AccountAccessParser.StateDiff[] memory rootSafeDiffs = accesses.getStateDiffFor(rootSafe, false);
        require(rootSafeDiffs.length == 1, "OPCMTaskBase: only nonce should be updated on upgrade controller multisig");

        for (uint256 i = 0; i < OPCM_TARGETS.length; i++) {
            address OPCM = OPCM_TARGETS[i];
            AccountAccessParser.StateDiff[] memory opcmDiffs = accesses.getStateDiffFor(OPCM, false);
            require(opcmDiffs.length <= 1, "OPCMTaskBase: OPCM must have at most 1 state change");
            // Not all invocations of OPCM upgrade will have the isRC state change. This is because it only happens when
            // address(this) is equal to the OPCMs 'upgradeController' address (which is an immutable).
            if (opcmDiffs.length == 1) {
                AccountAccessParser.StateDiff memory opcmDiff = opcmDiffs[0];
                bytes32 opcmStateSlot =
                    bytes32(uint256(stdstore.target(OPCM).sig(IOPContractsManager.isRC.selector).find()));
                require(opcmDiff.slot == opcmStateSlot, "OPCMTaskBase: Incorrect OPCM isRc slot");
                require(opcmDiff.oldValue == bytes32(uint256(1)), "OPCMTaskBase: Incorrect OPCM isRc old value");
                require(opcmDiff.newValue == bytes32(uint256(0)), "OPCMTaskBase: Incorrect OPCM isRc new value");
            }
        }
    }

    /// @notice Get the multicall address for the given safe if the safe is the parent multisig, return the delegatecall multicall address
    /// otherwise if the safe is a child multisig, return the regular multicall address.
    function _getMulticallAddress(address safe, address[] memory allSafes) internal pure override returns (address) {
        require(safe != address(0), "Safe address cannot be zero address");
        address rootSafe = allSafes[allSafes.length - 1];
        return (safe == rootSafe) ? MULTICALL3_DELEGATECALL_ADDRESS : MULTICALL3_ADDRESS;
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
    function _prankMultisig(address rootSafe) internal override {
        // If delegateCall value is true then sets msg.sender for all subsequent delegate calls.
        // We want this functionality for OPCM tasks.
        vm.startPrank(rootSafe, true);
    }

    /// @notice this function must be overridden in the inheriting contract to run assertions on the state changes.
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions, address rootSafe)
        internal
        view
        virtual
        override
    {
        accountAccesses; // No-ops to silence unused variable compiler warnings.
        actions;
        rootSafe;
        require(false, "You must implement the _validate function");
    }

    /// @notice Returns the type of task.
    function taskType() public pure override returns (TaskType) {
        return TaskType.OPCMTaskBase;
    }

    /// @notice Checks if the targets are allowed based on the preconfigured allowed targets.
    function requireAllowedTarget(address[] memory _targets, address[] memory _allowedTargets) internal pure {
        for (uint256 i = 0; i < _targets.length; i++) {
            require(Utils.contains(_allowedTargets, _targets[i]), "OPCMTaskBase: target is not allowed.");
        }
    }
}
