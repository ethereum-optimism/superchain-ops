// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ISuperchainRevSharesCalculator {
    function shareRecipient() external view returns (address payable);
    function remainderRecipient() external view returns (address payable);
}