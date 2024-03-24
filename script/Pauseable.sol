// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface Pausable {
    function pause(string memory _identifier) external;
    function unpause() external;
}
