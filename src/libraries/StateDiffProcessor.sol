// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Processes account accesses and returns transfers and state diffs.
/// The `process` function is the interface to be used by callers, and other
/// functions are internal helpers.
library StateDiffProcessor {
    /// @notice Special constant representing ETH transfers.
    address internal constant ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice The zero address.
    address internal constant ZERO = address(0);

    /// @notice Struct to represent a token/ETH transfer.
    struct TransferInfo {
        address from;
        address to;
        uint256 value;
        address tokenAddress;
    }

    /// @notice Struct to represent a storage state change.
    struct StateDiff {
        address who;
        bytes32 slot;
        bytes32 oldValue;
        bytes32 newValue;
    }

    /// @notice Processes an array of VmSafe.AccountAccess records and return all transfers and
    /// state diffs.
    function process(VmSafe.AccountAccess[] memory accountAccesses)
        internal
        pure
        returns (TransferInfo[] memory transfers, StateDiff[] memory stateDiffs)
    {
        uint256 totalTransfers = 0;
        uint256 totalStateChanges = 0;
        for (uint256 i = 0; i < accountAccesses.length; i++) {
            TransferInfo memory ethTransfer = processEthTransfer(accountAccesses[i]);
            if (ethTransfer.value != 0) {
                totalTransfers++;
            }
            TransferInfo memory erc20Transfer = processERC20Transfer(accountAccesses[i]);
            if (erc20Transfer.value != 0) {
                totalTransfers++;
            }
            StateDiff[] memory states = processStateDiffs(accountAccesses[i].storageAccesses);
            totalStateChanges += states.length;
        }

        transfers = new TransferInfo[](totalTransfers);
        stateDiffs = new StateDiff[](totalStateChanges);
        uint256 transferIndex = 0;
        uint256 stateIndex = 0;
        for (uint256 i = 0; i < accountAccesses.length; i++) {
            TransferInfo memory ethTransfer = processEthTransfer(accountAccesses[i]);
            if (ethTransfer.value != 0) {
                transfers[transferIndex] = ethTransfer;
                transferIndex++;
            }
            TransferInfo memory erc20Transfer = processERC20Transfer(accountAccesses[i]);
            if (erc20Transfer.value != 0) {
                transfers[transferIndex] = erc20Transfer;
                transferIndex++;
            }
            StateDiff[] memory states = processStateDiffs(accountAccesses[i].storageAccesses);
            for (uint256 j = 0; j < states.length; j++) {
                stateDiffs[stateIndex] = states[j];
                stateIndex++;
            }
        }
    }

    /// @notice Processes an ETH transfer from an account access record.
    /// Returns a TransferInfo struct containing transfer details. If no transfer
    /// occurred, all fields are zero.
    function processEthTransfer(VmSafe.AccountAccess memory access) internal pure returns (TransferInfo memory) {
        return access.value != 0
            ? TransferInfo({from: access.accessor, to: access.account, value: access.value, tokenAddress: ETH_TOKEN})
            : TransferInfo({from: ZERO, to: ZERO, value: 0, tokenAddress: ZERO});
    }

    /// @notice Processes an ERC20 transfer from an account access record.
    /// Returns a TransferInfo struct containing transfer details. If no valid
    /// ERC20 transfer is detected, all fields are zero.
    function processERC20Transfer(VmSafe.AccountAccess memory access) internal pure returns (TransferInfo memory) {
        bytes memory data = access.data;
        if (data.length <= 4) {
            return TransferInfo({from: ZERO, to: ZERO, value: 0, tokenAddress: ZERO});
        }

        bytes4 selector = bytes4(data);
        bytes memory params = new bytes(data.length - 4);
        for (uint256 j = 0; j < data.length - 4; j++) {
            params[j] = data[j + 4];
        }

        if (selector == IERC20.transfer.selector) {
            (address to, uint256 value) = abi.decode(params, (address, uint256));
            return TransferInfo({from: access.accessor, to: to, value: value, tokenAddress: access.account});
        } else if (selector == IERC20.transferFrom.selector) {
            (address from, address to, uint256 value) = abi.decode(params, (address, address, uint256));
            return TransferInfo({from: from, to: to, value: value, tokenAddress: access.account});
        } else {
            return TransferInfo({from: ZERO, to: ZERO, value: 0, tokenAddress: ZERO});
        }
    }

    /// @notice Processes storage changes from an array of storage access records.
    function processStateDiffs(VmSafe.StorageAccess[] memory accesses)
        internal
        pure
        returns (StateDiff[] memory diffs)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < accesses.length; i++) {
            if (accesses[i].isWrite) {
                count++;
            }
        }

        diffs = new StateDiff[](count);
        uint256 diffCount = 0;
        for (uint256 i = 0; i < accesses.length; i++) {
            if (accesses[i].isWrite) {
                diffs[diffCount] = StateDiff({
                    who: accesses[i].account,
                    slot: accesses[i].slot,
                    oldValue: accesses[i].previousValue,
                    newValue: accesses[i].newValue
                });
                diffCount++;
            }
        }
    }
}
