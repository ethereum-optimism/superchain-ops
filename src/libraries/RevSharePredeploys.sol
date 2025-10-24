// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// TODO: Import `FeeSplitter` and `OperatorFeeVault` from the Optimism contracts library once they are included.
/// @notice Library for storing the predeploys for the Revenue Share templates
abstract contract RevSharePredeploys {
    /// @notice Address of the Create2Deployer Preinstall on L2.
    address internal constant CREATE2_DEPLOYER = 0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2;
    /// @notice Address of the Operator Fee Vault Predeploy on L2.
    address internal constant OPERATOR_FEE_VAULT = 0x420000000000000000000000000000000000001b;
    /// @notice Address of the FeeSplitter Predeploy on L2.
    address internal constant FEE_SPLITTER = 0x420000000000000000000000000000000000002B;
    /// @notice Address of the Sequencer Fee Vault Predeploy on L2.
    address internal constant SEQUENCER_FEE_WALLET = 0x4200000000000000000000000000000000000011;
    /// @notice Address of the L1 Fee Vault Predeploy on L2.
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;
    /// @notice Address of the Base Fee Vault Predeploy on L2.
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    /// @notice The default recipient for the FeeVault once part of the Revenue Share system.
    address public constant FEE_VAULT_RECIPIENT = FEE_SPLITTER;
    /// @notice Address of the ProxyAdmin predeploy on L2.
    address internal constant PROXY_ADMIN = 0x4200000000000000000000000000000000000018;
}
