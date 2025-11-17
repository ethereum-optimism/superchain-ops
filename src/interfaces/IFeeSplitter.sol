// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice Interface for the FeeSplitter in L2.
interface IFeeSplitter {
    function initialize(address _sharesCalculator) external;
    function sharesCalculator() external view returns (address);
    function setSharesCalculator(address _calculator) external;
}
