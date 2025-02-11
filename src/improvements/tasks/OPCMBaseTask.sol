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
    address public constant OPCM = 0x95b259eae68ba96edB128eF853fFbDffe47D2Db0;

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
        (address[] memory targets,,) = getTaskActions();

        /// TODO create OPCM calls array with arguments
        OpChainConfig[] memory upgradeCalls = new OpChainConfig[](targets.length);

        for (uint256 i; i < targets.length; i++) {
            /// TODO fill this in with the real thing
            // upgradeCalls[i] = OPCMUpgrade({callData: arguments[i]});
        }

        /// generate calldata
        /// TODO change to actual function signature
        data = abi.encodeWithSignature("upgrade((address,address,bytes32)[])", upgradeCalls);
    }

    /// @notice get the data to sign by EOA for single multisig
    /// @param data The calldata to be executed
    /// @return The data to sign
    function getDataToSign(address safe, bytes memory data) public view override returns (bytes memory) {
        return IGnosisSafe(safe).encodeTransactionData({
            /// TODO: replance to with actual OPCM contract address
            to: OPCM,
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

    /// @notice helper function to generate the approveHash calldata to be executed by child multisig owner on parent multisig
    /// TODO fix this so that it calls the OPCM upgrade function instead of the multicall3 contract
    function generateApproveMulticallData() public view override returns (bytes memory) {
        // bytes32 hash = getHash();

        /// TODO create OPCM calls array with arguments
        // OPCMUpgrade[] memory upgradeCalls = new OPCMUpgrade[](targets.length);

        // Call3Value memory call = Call3Value({
        //     target: multisig,
        //     allowFailure: false,
        //     value: 0,
        //     callData: abi.encodeCall(IGnosisSafe(multisig).approveHash, (hash))
        // });

        // Call3Value[] memory calls = new Call3Value[](1);
        // calls[0] = call;

        /// generate calldata
        /// TODO change to actual function signature
        return abi.encodeWithSignature("upgrade((address,address,bytes32)[])", "" /*calls*/ );
    }

    /// @notice build the task actions for all l2chains in the task
    /// @dev contract calls must be perfomed in plain solidity.
    ///      overriden requires using buildModifier modifier to leverage
    ///      foundry snapshot and state diff recording to populate the actions array.
    function build() public override buildModifier {
        Addresses.ChainInfo[] memory chains = addresses.getChains();

        bytes memory data = getCalldata();
        (bool success, ) = OPCM.call{value: 0}(data);
        require(success, "OPCMBaseTask: failed to build task");
    }
}
