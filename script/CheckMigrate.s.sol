// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script} from "forge-std/Script.sol";
import {IOPContractsManager} from "@op/interfaces/L1/IOPContractsManager.sol";

interface ISystemConfig {
    function superchainConfig() external view returns (address);
}

interface IOptimismPortal {
    function ethLockbox() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function anchorStateRegistry() external view returns (address);
    function systemConfig() external view returns (ISystemConfig);
    function guardian() external view returns (address);
}

/// @title CheckMigrate
/// @notice Checks that the interop migration correctly performed basic migration steps.
///         This script is used to verify that the migration was successful and that the
///         contracts were correctly updated.
contract CheckMigrate is Script {
    /// @notice Thrown when the ETHLockbox of one or more of the provided OP Stack chains
    ///         being migrated does not match the ETHLockbox of the first provided chain.
    error CheckMigrate_ETHLockboxMismatch();

    /// @notice Thrown when the DisputeGameFactory of one or more of the provided OP Stack chains
    ///         being migrated does not match the DisputeGameFactory of the first provided chain.
    error CheckMigrate_DisputeGameFactoryMismatch();

    /// @notice Thrown when the AnchorStateRegistry of one or more of the provided OP Stack chains
    ///         being migrated does not match the AnchorStateRegistry of the first provided chain.
    error CheckMigrate_AnchorStateRegistryMismatch();

    /// @notice Thrown when the SuperchainConfig of one or more of the provided OP Stack chains
    ///         being migrated does not match the SuperchainConfig of the first provided chain.
    ///         Different than the other similar error, this error specifically checks for the
    ///         result of the migration, not the input.
    error CheckMigrate_SuperchainConfigOutputMismatch();

    /// @notice Thrown when the Guardian of one or more of the provided OP Stack chains
    ///         being migrated does not match the Guardian of the first provided chain.
    error CheckMigrate_GuardianMismatch();

    /// @notice Checks that the interop migration correctly performed basic migration steps.
    /// @param _opChainConfigs The OP Stack chains being migrated.
    function run(IOPContractsManager.OpChainConfig[] memory _opChainConfigs) public view {
        // Grab an array of portals from the configs.
        IOptimismPortal[] memory portals = new IOptimismPortal[](_opChainConfigs.length);
        for (uint256 i = 0; i < _opChainConfigs.length; i++) {
            portals[i] = IOptimismPortal(payable(_opChainConfigs[i].systemConfigProxy.optimismPortal()));
        }

        // Safety assertions. We want to perform some checks at the end of the migration to ensure
        // that the various operations had the intended effect. Lots of different ways to do
        // something like this, but adding assertions here is simple and effective.
        for (uint256 i = 0; i < _opChainConfigs.length; i++) {
            // Check that the ETHLockbox is the same.
            if (portals[i].ethLockbox() != portals[0].ethLockbox()) {
                revert CheckMigrate_ETHLockboxMismatch();
            }

            // Check that the DisputeGameFactory is the same.
            if (portals[i].disputeGameFactory() != portals[0].disputeGameFactory()) {
                revert CheckMigrate_DisputeGameFactoryMismatch();
            }

            // Check that the AnchorStateRegistry is the same.
            if (portals[i].anchorStateRegistry() != portals[0].anchorStateRegistry()) {
                revert CheckMigrate_AnchorStateRegistryMismatch();
            }

            // Check that the SuperchainConfig is the same.
            if (portals[i].systemConfig().superchainConfig() != portals[0].systemConfig().superchainConfig()) {
                revert CheckMigrate_SuperchainConfigOutputMismatch();
            }

            // Check that the Guardian is the same.
            if (portals[i].guardian() != portals[0].guardian()) {
                revert CheckMigrate_GuardianMismatch();
            }
        }
    }
}
