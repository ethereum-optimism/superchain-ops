// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script} from "forge-std/Script.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {console} from "forge-std/console.sol";

/// @notice Prints the expected transaction hash and data to sign for a single Safe owner swap.
/// Usage:
///  forge script script/ComputeSafeOwnerSwapHash.s.sol \
///    --sig "run(address,address,address)"\
///    $SAFE_ADDRESS $OLD_OWNER_ADDRESS $NEW_OWNER_ADDRESS \
///    --fork-url $MAINNET_RPC_URL
contract ComputeSafeOwnerSwapHash is Script {
    address internal constant SENTINEL_OWNERS = address(0x1);

    /// @notice Prints the expected transaction hash and data to sign for a single Safe owner swap.
    /// @param _safe The address of the Safe.
    /// @param _oldOwner The address of the current owner to be replaced by `_newOwner`.
    /// @param _newOwner The address of the new owner to replace `_oldOwner`.
    function run(address _safe, address _oldOwner, address _newOwner) public view {
        (bytes memory txData, bytes32 txHash) = getTxDataAndHash(_safe, _oldOwner, _newOwner);

        // Print the data for signers to verify against.
        console.log("---\nIf submitting onchain, call Safe.approveHash on %s with the following hash:", _safe);
        console.logBytes32(txHash);

        console.log("---\nData to sign:");
        console.log("vvvvvvvv");
        console.logBytes(txData);
        console.log("^^^^^^^^\n");

        console.log("########## IMPORTANT ##########");
        console.log(
            "Please make sure that the 'Data to sign' displayed above matches what you see in the simulation and on your hardware wallet."
        );
        console.log("This is a critical step that must not be skipped.");
        console.log("###############################");
    }

    /// @notice Computes the transaction data and data hash for a Safe owner swap.
    /// @param _safe The address of the Safe.
    /// @param _oldOwner The address of the current owner to be replaced by `_newOwner`.
    /// @param _newOwner The address of the new owner to replace `_oldOwner`.
    /// @return txData_ The transaction data.
    /// @return txHash_ The data hash.
    function getTxDataAndHash(address _safe, address _oldOwner, address _newOwner)
        internal
        view
        returns (bytes memory txData_, bytes32 txHash_)
    {
        address[] memory owners = IGnosisSafe(_safe).getOwners();
        (address prevOwner,) = findPreviousOwner(owners, _oldOwner);

        uint256 nonce = IGnosisSafe(_safe).nonce();
        txData_ = IGnosisSafe(_safe).encodeTransactionData({
            to: _safe,
            value: 0,
            data: abi.encodeCall(IGnosisSafe(_safe).swapOwner, (prevOwner, _oldOwner, _newOwner)),
            operation: Enum.Operation.Call,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: address(0),
            _nonce: nonce
        });

        txHash_ = keccak256(txData_);
    }

    /// @notice Finds the previous owner in the linked list given an owner.
    /// @param _owners The array of owner addresses in linked list order.
    /// @param _owner The owner address for which to find the previous owner.
    /// @return prevOwner_ The previous owner address. If _owner is the first owner in the array,
    /// the sentinel address is returned.
    /// @return prevOwnerIndex_ The index of the previous owner in the array (or zero if the sentinel is returned).
    function findPreviousOwner(address[] memory _owners, address _owner)
        internal
        pure
        returns (address prevOwner_, uint256 prevOwnerIndex_)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            if (_owners[i] == _owner) {
                // If _owner is the first element, then its previous owner is the sentinel owner.
                // Otherwise, return the owner immediately before _owner in the array.
                if (i == 0) return (SENTINEL_OWNERS, i);
                else return (_owners[i - 1], i - 1);
            }
        }
        // Revert if _owner is not found in the provided list.
        revert(string.concat("Owner not found: ", vm.toString(_owner)));
    }
}
