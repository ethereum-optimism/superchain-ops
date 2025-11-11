// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {RevShareLibrary} from "src/libraries/RevShareLibrary.sol";
import {Utils} from "src/libraries/Utils.sol";

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
    /// @notice Base salt seed for CREATE2 deployments
    string private constant SALT_SEED = "RevShare";

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

    /// @notice Struct for L1Withdrawer configuration.
    /// @param minWithdrawalAmount Minimum withdrawal amount
    /// @param recipient Recipient address for withdrawals
    /// @param gasLimit Gas limit for L1 withdrawals
    struct L1WithdrawerConfig {
        uint256 minWithdrawalAmount;
        address recipient;
        uint32 gasLimit;
    }

    /// @notice Struct for RevShare setup configuration per chain.
    /// @param portal OptimismPortal2 address for the target L2
    /// @param l1WithdrawerConfig L1Withdrawer configuration
    /// @param chainFeesRecipient Chain fees recipient address for the calculator
    struct RevShareConfig {
        address portal;
        L1WithdrawerConfig l1WithdrawerConfig;
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
            address precalculatedCalculator =
                _deployRevSharePeriphery(config.portal, config.l1WithdrawerConfig, config.chainFeesRecipient);

            // Upgrade fee splitter and initialize with calculator FIRST
            // This prevents the edge case where fees could be sent to an uninitialized FeeSplitter
            bytes32 feeSplitterSalt = _getSalt("FeeSplitter");
            address feeSplitterImpl = Utils.getCreate2Address(
                feeSplitterSalt, RevShareLibrary.feeSplitterCreationCode, RevShareLibrary.CREATE2_DEPLOYER
            );
            _depositCreate2(
                config.portal,
                RevShareLibrary.FEE_SPLITTER_DEPLOYMENT_GAS_LIMIT,
                feeSplitterSalt,
                RevShareLibrary.feeSplitterCreationCode
            );
            _depositCall(
                config.portal,
                address(RevShareLibrary.PROXY_ADMIN),
                RevShareLibrary.UPGRADE_GAS_LIMIT,
                abi.encodeCall(
                    IProxyAdmin.upgradeAndCall,
                    (
                        payable(RevShareLibrary.FEE_SPLITTER),
                        feeSplitterImpl,
                        abi.encodeCall(IFeeSplitter.initialize, (precalculatedCalculator))
                    )
                )
            );

            // Upgrade all 4 vaults with RevShare configuration (recipient=FeeSplitter, minWithdrawal=0, network=L2)
            _upgradeVaultsWithRevShareConfig(config.portal);

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
            address calculator =
                _deployRevSharePeriphery(config.portal, config.l1WithdrawerConfig, config.chainFeesRecipient);

            // Set calculator on fee splitter
            _depositCall(
                config.portal,
                RevShareLibrary.FEE_SPLITTER,
                RevShareLibrary.SETTERS_GAS_LIMIT,
                abi.encodeCall(IFeeSplitter.setSharesCalculator, (calculator))
            );

            // Configure all 4 vaults for revenue sharing
            _configureVaultsForRevShare(config.portal);

            emit ChainProcessed(config.portal, i);
        }
    }

    /// @notice Deploys L1Withdrawer and SuperchainRevenueShareCalculator to L2.
    /// @param _portal The OptimismPortal2 address for the target L2
    /// @param _l1WithdrawerConfig L1Withdrawer configuration
    /// @param _chainFeesRecipient Chain fees recipient address
    /// @return calculator The deployed calculator address
    function _deployRevSharePeriphery(
        address _portal,
        L1WithdrawerConfig calldata _l1WithdrawerConfig,
        address _chainFeesRecipient
    ) private returns (address calculator) {
        // Deploy L1Withdrawer
        bytes memory l1WithdrawerInitCode = bytes.concat(
            RevShareLibrary.l1WithdrawerCreationCode,
            abi.encode(
                _l1WithdrawerConfig.minWithdrawalAmount, _l1WithdrawerConfig.recipient, _l1WithdrawerConfig.gasLimit
            )
        );
        bytes32 l1WithdrawerSalt = _getSalt("L1Withdrawer");
        address precalculatedL1Withdrawer =
            Utils.getCreate2Address(l1WithdrawerSalt, l1WithdrawerInitCode, RevShareLibrary.CREATE2_DEPLOYER);
        _depositCreate2(
            _portal, RevShareLibrary.L1_WITHDRAWER_DEPLOYMENT_GAS_LIMIT, l1WithdrawerSalt, l1WithdrawerInitCode
        );

        // Deploy SuperchainRevenueShareCalculator
        bytes memory calculatorInitCode = bytes.concat(
            RevShareLibrary.scRevShareCalculatorCreationCode, abi.encode(precalculatedL1Withdrawer, _chainFeesRecipient)
        );
        bytes32 calculatorSalt = _getSalt("SCRevShareCalculator");
        calculator = Utils.getCreate2Address(calculatorSalt, calculatorInitCode, RevShareLibrary.CREATE2_DEPLOYER);
        _depositCreate2(
            _portal, RevShareLibrary.SC_REV_SHARE_CALCULATOR_DEPLOYMENT_GAS_LIMIT, calculatorSalt, calculatorInitCode
        );
    }

    /// @notice Configures all 4 vaults for revenue sharing (recipient=FeeSplitter, minWithdrawal=0, network=L2).
    /// @param _portal The OptimismPortal2 address for the target L2
    function _configureVaultsForRevShare(address _portal) private {
        address[4] memory vaults = [
            RevShareLibrary.OPERATOR_FEE_VAULT,
            RevShareLibrary.SEQUENCER_FEE_WALLET,
            RevShareLibrary.BASE_FEE_VAULT,
            RevShareLibrary.L1_FEE_VAULT
        ];

        for (uint256 i; i < vaults.length; i++) {
            _depositCall(
                _portal,
                vaults[i],
                RevShareLibrary.SETTERS_GAS_LIMIT,
                abi.encodeCall(IFeeVault.setRecipient, (RevShareLibrary.FEE_SPLITTER))
            );
            _depositCall(
                _portal,
                vaults[i],
                RevShareLibrary.SETTERS_GAS_LIMIT,
                abi.encodeCall(IFeeVault.setMinWithdrawalAmount, (0))
            );
            _depositCall(
                _portal,
                vaults[i],
                RevShareLibrary.SETTERS_GAS_LIMIT,
                abi.encodeCall(IFeeVault.setWithdrawalNetwork, (IFeeVault.WithdrawalNetwork.L2))
            );
        }
    }

    /// @notice Upgrades all 4 vaults with RevShare configuration (recipient=FeeSplitter, minWithdrawal=0, network=L2).
    ///         Deploys only 3 implementations: OperatorFeeVault, SequencerFeeVault, and the same FeeVault implementation is used for both BaseFeeVault and L1FeeVault (we use the same one for both to avoid making the deployment size bigger).
    /// @param _portal The OptimismPortal2 address for the target L2
    function _upgradeVaultsWithRevShareConfig(address _portal) private {
        address[4] memory vaultProxies = [
            RevShareLibrary.OPERATOR_FEE_VAULT,
            RevShareLibrary.SEQUENCER_FEE_WALLET,
            RevShareLibrary.BASE_FEE_VAULT,
            RevShareLibrary.L1_FEE_VAULT
        ];
        bytes[4] memory creationCodes = [
            RevShareLibrary.operatorFeeVaultCreationCode,
            RevShareLibrary.sequencerFeeVaultCreationCode,
            RevShareLibrary.defaultFeeVaultCreationCode,
            RevShareLibrary.defaultFeeVaultCreationCode
        ];
        string[4] memory vaultNames = ["OperatorFeeVault", "SequencerFeeVault", "BaseFeeVault", "L1FeeVault"];

        address defaultImpl;
        for (uint256 i; i < vaultProxies.length; i++) {
            bytes32 salt = _getSalt(vaultNames[i]);
            address impl;

            // Check if this is the BaseFeeVault or L1FeeVault (both use default implementation)
            bool isBaseFeeVault = keccak256(bytes(vaultNames[i])) == keccak256(bytes("BaseFeeVault"));
            bool isL1FeeVault = keccak256(bytes(vaultNames[i])) == keccak256(bytes("L1FeeVault"));

            if (isBaseFeeVault) {
                // Deploy default implementation for BaseFeeVault
                impl = Utils.getCreate2Address(salt, creationCodes[i], RevShareLibrary.CREATE2_DEPLOYER);
                defaultImpl = impl;
                _depositCreate2(_portal, RevShareLibrary.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT, salt, creationCodes[i]);
            } else if (isL1FeeVault) {
                // Reuse the default implementation for L1FeeVault
                impl = defaultImpl;
            } else {
                // Deploy specific implementations for OperatorFeeVault and SequencerFeeVault
                impl = Utils.getCreate2Address(salt, creationCodes[i], RevShareLibrary.CREATE2_DEPLOYER);
                _depositCreate2(_portal, RevShareLibrary.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT, salt, creationCodes[i]);
            }

            _depositCall(
                _portal,
                address(RevShareLibrary.PROXY_ADMIN),
                RevShareLibrary.UPGRADE_GAS_LIMIT,
                abi.encodeCall(
                    IProxyAdmin.upgradeAndCall,
                    (
                        payable(vaultProxies[i]),
                        impl,
                        abi.encodeCall(
                            IFeeVault.initialize, (RevShareLibrary.FEE_SPLITTER, 0, IFeeVault.WithdrawalNetwork.L2)
                        )
                    )
                )
            );
        }
    }

    /// @notice Helper for CREATE2 contract deployments via depositTransaction.
    /// @param _portal The OptimismPortal2 address
    /// @param _gasLimit Gas limit for the transaction
    /// @param _salt CREATE2 salt
    /// @param _initCode Contract creation code with constructor args
    function _depositCreate2(address _portal, uint64 _gasLimit, bytes32 _salt, bytes memory _initCode) private {
        IOptimismPortal2(payable(_portal)).depositTransaction(
            address(RevShareLibrary.CREATE2_DEPLOYER),
            0,
            _gasLimit,
            false,
            abi.encodeCall(ICreate2Deployer.deploy, (0, _salt, _initCode))
        );
    }

    /// @notice Helper for regular function calls via depositTransaction.
    /// @param _portal The OptimismPortal2 address
    /// @param _target Target contract address
    /// @param _gasLimit Gas limit for the transaction
    /// @param _data Encoded function call data
    function _depositCall(address _portal, address _target, uint64 _gasLimit, bytes memory _data) private {
        IOptimismPortal2(payable(_portal)).depositTransaction(_target, 0, _gasLimit, false, _data);
    }

    /// @notice Generates a unique salt for CREATE2 deployments based on the contract suffix.
    /// @param _suffix The suffix to append to the base salt seed
    /// @return The generated salt as bytes32
    function _getSalt(string memory _suffix) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(SALT_SEED, ":", _suffix));
    }
}
