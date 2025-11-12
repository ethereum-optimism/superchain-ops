// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {FeeVaultUpgrader} from "src/libraries/FeeVaultUpgrader.sol";
import {FeeSplitterSetup} from "src/libraries/FeeSplitterSetup.sol";
import {Utils} from "src/libraries/Utils.sol";
import {RevShareCommon} from "src/libraries/RevShareCommon.sol";

// Interfaces
import {IOptimismPortal2} from "@eth-optimism-bedrock/interfaces/L1/IOptimismPortal2.sol";
import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {ICreate2Deployer} from "src/interfaces/ICreate2Deployer.sol";
import {IFeeSplitter} from "src/interfaces/IFeeSplitter.sol";
import {IFeeVault} from "src/interfaces/IFeeVault.sol";

/// @title RevShareContractsUpgrader
/// @notice Upgrader contract that manages RevShare deployments and configuration via delegatecall.
/// @dev    Supports two operations:
///         1. setupRevShare() - Setup revenue sharing on already-upgraded contracts
///         2. upgradeAndSetupRevShare() - Combined upgrade + setup (most efficient)
///         All operations use the default calculator (L1Withdrawer + SuperchainRevenueShareCalculator).
contract RevShareContractsUpgrader {
    /// @notice Thrown when portal address is zero
    error PortalCannotBeZeroAddress();

    /// @notice Thrown when L1Withdrawer recipient is zero address
    error L1WithdrawerRecipientCannotBeZeroAddress();

    /// @notice Thrown when chain fees recipient is zero address
    error ChainFeesRecipientCannotBeZeroAddress();

    /// @notice Thrown when gas limit is zero
    error GasLimitCannotBeZero();

    /// @notice Thrown when array is empty
    error EmptyArray();

    /// @notice Emitted when a chain's RevShare setup  deposits are completed
    /// @param portal The portal address for the chain
    /// @param chainIndex The index of the chain in the configs array
    event ChainProcessed(address portal, uint256 chainIndex);

    /// @notice Struct for RevShare setup configuration per chain.
    /// @param portal OptimismPortal2 address for the target L2
    /// @param l1WithdrawerConfig L1Withdrawer configuration
    /// @param chainFeesRecipient Chain fees recipient address for the calculator
    struct RevShareConfig {
        address portal;
        FeeSplitterSetup.L1WithdrawerConfig l1WithdrawerConfig;
        address chainFeesRecipient;
    }

    /// @notice Upgrades vault and splitter contracts and sets up revenue sharing in one transaction for multiple chains.
    ///         This is the most efficient path as vaults are initialized with RevShare config from the start.
    /// @param _configs Array of RevShare configuration structs, one per chain.
    function upgradeAndSetupRevShare(RevShareConfig[] calldata _configs) external {
        if (_configs.length == 0) revert EmptyArray();

        for (uint256 i; i < _configs.length; i++) {
            RevShareConfig calldata config = _configs[i];
            if (config.portal == address(0)) revert PortalCannotBeZeroAddress();
            if (config.l1WithdrawerConfig.recipient == address(0)) revert L1WithdrawerRecipientCannotBeZeroAddress();
            if (config.chainFeesRecipient == address(0)) revert ChainFeesRecipientCannotBeZeroAddress();
            if (config.l1WithdrawerConfig.gasLimit == 0) revert GasLimitCannotBeZero();

            // Deploy L1Withdrawer and SuperchainRevenueShareCalculator
            address precalculatedCalculator = FeeSplitterSetup.deployRevSharePeriphery(
                config.portal, config.l1WithdrawerConfig, config.chainFeesRecipient
            );

            // Deploy and setup FeeSplitter
            FeeSplitterSetup.deployAndSetupFeeSplitter(config.portal, precalculatedCalculator);

            // Upgrade all 4 vaults with RevShare configuration (recipient=FeeSplitter, minWithdrawal=0, network=L2)
            FeeVaultUpgrader.upgradeVaultsWithRevShareConfig(config.portal);

            emit ChainProcessed(config.portal, i);
        }
    }

    /// @notice Enables revenue sharing after vaults have been upgraded and `FeeSplitter` initialized.
    ///         Deploys L1Withdrawer and calculator, then configures vaults and splitter for multiple chains.
    /// @param _configs Array of RevShare configuration structs, one per chain.
    function setupRevShare(RevShareConfig[] calldata _configs) external {
        if (_configs.length == 0) revert EmptyArray();

        for (uint256 i; i < _configs.length; i++) {
            RevShareConfig calldata config = _configs[i];
            if (config.portal == address(0)) revert PortalCannotBeZeroAddress();
            if (config.l1WithdrawerConfig.recipient == address(0)) revert L1WithdrawerRecipientCannotBeZeroAddress();
            if (config.chainFeesRecipient == address(0)) revert ChainFeesRecipientCannotBeZeroAddress();
            if (config.l1WithdrawerConfig.gasLimit == 0) revert GasLimitCannotBeZero();

            // Deploy L1Withdrawer and SuperchainRevenueShareCalculator
            address calculator = FeeSplitterSetup.deployRevSharePeriphery(
                config.portal, config.l1WithdrawerConfig, config.chainFeesRecipient
            );

            // Set calculator on fee splitter
            RevShareCommon.depositCall(
                config.portal,
                RevShareCommon.FEE_SPLITTER,
                FeeVaultUpgrader.SETTERS_GAS_LIMIT,
                abi.encodeCall(IFeeSplitter.setSharesCalculator, (calculator))
            );

            // Configure all 4 vaults for revenue sharing
            FeeVaultUpgrader.configureVaultsForRevShare(config.portal);

            emit ChainProcessed(config.portal, i);
        }
    }
}
