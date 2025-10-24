// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @notice Library for storing the gas limits for the calls done in the Revenue Share templates
library RevShareGasLimits {
    /// @notice Based on Tenderly simulations, these are the actual gas costs for each of the L2 operations:
    /// - L1Withdrawer deployment: 558,056
    /// - SC Rev Share Calculator deployment: 579,688
    /// - Fee Vaults deployment: ~831,000
    /// - Fee Splitter deployment: 1,121,747
    /// - upgrade: ~48,000
    /// - setters: ~50,000
    /// The gas limits below include a buffer to ensure successful execution.

    /// @notice The gas limit for the SC Rev Share Calculator deployment.
    uint64 internal constant SC_REV_SHARE_CALCULATOR_DEPLOYMENT_GAS_LIMIT = 681_986;

    /// @notice The gas limit for the L1 Withdrawer deployment.
    uint64 internal constant L1_WITHDRAWER_DEPLOYMENT_GAS_LIMIT = 656_536;

    /// @notice The gas limit for the Fee Vaults deployment.
    uint64 internal constant FEE_VAULTS_DEPLOYMENT_GAS_LIMIT = 1_200_000;

    /// @notice The gas limit for the Fee Splitter deployment.
    uint64 internal constant FEE_SPLITTER_DEPLOYMENT_GAS_LIMIT = 1_319_702;

    /// @notice The gas limit for the upgrade calls on L2.
    uint64 internal constant UPGRADE_GAS_LIMIT = 150_000;

    /// @notice The gas limit for the Fee Vaults deployment.
    uint64 internal constant SETTERS_GAS_LIMIT = 50_000;
}
