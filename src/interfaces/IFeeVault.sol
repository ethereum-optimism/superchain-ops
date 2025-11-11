// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IFeeVault {
    enum WithdrawalNetwork {
        L1,
        L2
    }

    function initialize(address _recipient, uint256 _minWithdrawalAmount, WithdrawalNetwork _withdrawalNetwork) external;

    function RECIPIENT() external view returns (address);
    function MIN_WITHDRAWAL_AMOUNT() external view returns (uint256);
    function WITHDRAWAL_NETWORK() external view returns (WithdrawalNetwork);
    function minWithdrawalAmount() external view returns (uint256);
    function recipient() external view returns (address);
    function withdrawalNetwork() external view returns (WithdrawalNetwork);

    function setRecipient(address _recipient) external;
    function setMinWithdrawalAmount(uint256 _minWithdrawalAmount) external;
    function setWithdrawalNetwork(WithdrawalNetwork _withdrawalNetwork) external;
}
