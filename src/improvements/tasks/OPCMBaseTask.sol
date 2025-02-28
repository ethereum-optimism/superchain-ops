// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {AddressRegistry} from "src/improvements/AddressRegistry.sol";
import {L2TaskBase, MultisigTask} from "src/improvements/tasks/MultisigTask.sol";

/// @notice base task for making calls to the Optimism Contracts Manager
abstract contract OPCMBaseTask is L2TaskBase {
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

    /// @notice Call3 struct used in the Multicall3DelegateCall contract
    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
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
    function getMulticall3Calldata(MultisigTask.Action[] memory actions)
        public
        pure
        override
        returns (bytes memory data)
    {
        // get task actions
        (address[] memory targets,, bytes[] memory arguments) = processTaskActions(actions);

        // create calls array with targets and arguments
        Call3[] memory calls = new Call3[](targets.length);

        for (uint256 i; i < calls.length; i++) {
            require(targets[i] != address(0), "Invalid target for multisig");
            calls[i] = Call3({target: targets[i], allowFailure: false, callData: arguments[i]});
        }

        // generate calldata
        data = abi.encodeWithSignature("aggregate3((address,bool,bytes)[])", calls);
    }

    function validate(VmSafe.AccountAccess[] memory accesses, MultisigTask.Action[] memory actions) public override {
        (address[] memory targets,,) = processTaskActions(actions);
        require(targets.length == 1 && targets[0] == opcm(), "OPCMBaseTask: only OPCM is allowed as target");
        super.validate(accesses, actions);
        require(
            _stateInfos[parentMultisig].length == 1,
            "OPCMBaseTask: only nonce should be updated on upgrade controller multisig"
        );
        require(_stateInfos[opcm()].length == 0, "OPCMBaseTask: Storage writes are not allowed on OPCM");
    }

    /// @notice get the OPCM address
    /// @dev override in the opcm template to return the correct OPCM address based
    /// on the network chain id of the task. This function MUST BE OVERRIDDEN in the
    /// inheriting contract to return the correct OPCM address
    /// @return The address of the OPCM
    function opcm() public view virtual returns (address);

    /// @notice get the multicall address for the given safe
    /// if the safe is the parent multisig, return the delegatecall multicall address
    /// otherwise if the safe is a child multisig, return the regular multicall address
    /// @param safe The address of the safe
    /// @return The address of the multicall
    function _getMulticallAddress(address safe) internal view override returns (address) {
        require(safe != address(0), "Safe address cannot be zero address");
        return (safe == parentMultisig) ? MULTICALL3_DELEGATECALL_ADDRESS : MULTICALL3_ADDRESS;
    }

    /// @notice prank the multisig
    /// overrides MultisigTask to prank with delegatecall flag set to true
    function _prankMultisig() internal override {
        vm.startPrank(parentMultisig, true);
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

    // @notice this function must be overridden in the inheriting contract
    function _validate(uint256, VmSafe.AccountAccess[] memory) internal view virtual override {
        require(false, "You must implement the _validate function");
    }

    /// @notice overrides to do nothing per chain
    /// all the chains are handled in a single call to OPCM contract
    function _buildPerChain(uint256) internal pure override {
        // We must override this function but OPCM template do not support per chain builds.
        // We cannot revert here because this build function is called by the parent MultisigTask.
    }
}
