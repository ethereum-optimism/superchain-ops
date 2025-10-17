// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice Library for storing the gas limits for the calls done in the Revenue Share templates
library RevShareGasLimits {
    /// @notice Based on deployment tests, these are the average gas costs for each of the L2 operations:
    /// - L1Withdrawer deployment: 497,812
    /// - SC Rev Share Calculator deployment: 518,168
    /// - Fee Vaults deployment: 757,214
    /// - Fee Splitter deployment: 1,027,359
    /// - upgradeAndCall: 73,015
    /// - upgrade: 6,202
    /// - setters: TODO: add this after simulating in tenderly
    /// A buffer of ~20% is applied to each value to have enough margin. While leaving the upgrade call
    /// to a fixed 150,000 gas limit.

    /// @notice The gas limit for the SC Rev Share Calculator deployment.
    uint64 internal constant SC_REV_SHARE_CALCULATOR_DEPLOYMENT_GAS_LIMIT = 625_000;

    /// @notice The gas limit for the L1 Withdrawer deployment.
    uint64 internal constant L1_WITHDRAWER_DEPLOYMENT_GAS_LIMIT = 625_000;

    /// @notice The gas limit for the Fee Vaults deployment.
    uint64 internal constant FEE_VAULTS_DEPLOYMENT_GAS_LIMIT = 910_000;

    /// @notice The gas limit for the Fee Splitter deployment.
    uint64 internal constant FEE_SPLITTER_DEPLOYMENT_GAS_LIMIT = 1_235_000;

    /// @notice The gas limit for the upgrade calls on L2.
    uint64 internal constant UPGRADE_GAS_LIMIT = 150_000;

    /// @notice The gas limit for the Fee Vaults deployment.
    uint64 internal constant SETTERS_GAS_LIMIT = 50_000;
}
