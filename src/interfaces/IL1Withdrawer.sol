// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IL1Withdrawer {
    function minWithdrawalAmount() external view returns (uint256);
    function recipient() external view returns (address);
    function withdrawalGasLimit() external view returns (uint32);
}