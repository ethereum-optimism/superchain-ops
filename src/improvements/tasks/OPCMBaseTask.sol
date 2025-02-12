// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/improvements/AddressRegistry.sol";

/// @notice base task for making calls to the Optimism Contracts Manager
abstract contract OPCMBaseTask is MultisigTask {
    /// @notice Optimism Contracts Manager Multicall3DelegateCall contract reference
    /// TODO can we just use the OPCM contract address here directly?
    ///  it seems like that would be easier to reason about
    address public constant MULTICALL3_DELEGATECALL_ADDRESS = 0x95b259eae68ba96edB128eF853fFbDffe47D2Db0;

    /// @notice OpChainConfig struct found in the OpContractsManager contract
    struct OpChainConfig {
        /// normally typed as an ISystemConfig, however ISystemConfig is an interface,
        /// which is unused here, so we just store the address
        address systemConfigProxy;
        /// normally typed as an IProxyAdmin, however IProxyAdmin is an interface,
        /// which is unused here, so we just store the address
        address proxyAdmin;
        /// normally typed as type `Claim`, however Claim is of bytes32 type
        /// and we don't have to worry about the Claim type as we are not
        /// calling the interface with that type
        bytes32 absolutePrestate;
    }

    /// @notice get the calldata to be executed by safe
    /// @dev callable only after the build function has been run and the
    /// calldata has been loaded up to storage
    /// @return data The calldata to be executed
    function getCalldata() public view override returns (bytes memory data) {
        /// get task actions
        (,, bytes[] memory arguments) = getTaskActions();

        return arguments[0];
    }

    /// @notice get the data to sign by EOA for single multisig
    /// @param data The calldata to be executed
    /// @return The data to sign
    function getDataToSign(address safe, bytes memory data) public view override returns (bytes memory) {
        address target;
        if (safe == multisig) {
            target = MULTICALL3_DELEGATECALL_ADDRESS;
        } else {
            target = MULTICALL3_ADDRESS;
        }
        return IGnosisSafe(safe).encodeTransactionData({
            to: target,
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

    function _build(uint256 chainId) internal override {}

    function _validate(uint256 chainId) internal view override {}
}
