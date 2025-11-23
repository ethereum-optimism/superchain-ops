// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRevShareContractsUpgrader {
    error PortalCannotBeZeroAddress();
    error L1WithdrawerRecipientCannotBeZeroAddress();
    error ChainFeesRecipientCannotBeZeroAddress();
    error GasLimitCannotBeZero();
    error EmptyArray();

    event ChainProcessed(address portal, uint256 chainIndex);

    struct L1WithdrawerConfig {
        uint256 minWithdrawalAmount;
        address recipient;
        uint32 gasLimit;
    }

    struct RevShareConfig {
        address portal;
        L1WithdrawerConfig l1WithdrawerConfig;
        address chainFeesRecipient;
    }

    function upgradeAndSetupRevShare(RevShareConfig[] calldata _configs) external;
    function setupRevShare(RevShareConfig[] calldata _configs) external;
}
