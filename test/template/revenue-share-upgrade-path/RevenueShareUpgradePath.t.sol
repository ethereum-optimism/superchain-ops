// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {RevenueShareV100UpgradePath} from "src/template/RevenueShareUpgradePath.sol";

/// @notice Test contract for the RevenueShareUpgradePath that expect reverts on misconfiguration of required fields.
contract RevenueShareUpgradePathRequiredFieldsTest is Test {
    RevenueShareV100UpgradePath public template;

    function setUp() public {
        vm.createSelectFork("mainnet", 23197819);
        template = new RevenueShareV100UpgradePath();
    }

    /// @notice Tests that the template reverts when the portal is a zero address.
    function test_revenueShareUpgradePath_portal_zero_address_reverts() public {
        string memory configPath = "test/template/revenue-share-upgrade-path/config/portal-zero-address-config.toml";
        vm.expectRevert("portal must be set in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the salt seed is an empty string.
    function test_revenueShareUpgradePath_saltSeed_empty_string_reverts() public {
        string memory configPath = "test/template/revenue-share-upgrade-path/config/saltSeed-empty-string-config.toml";
        vm.expectRevert("saltSeed must be set in the config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the base fee vault recipient is a zero address.
    function test_revenueShareUpgradePath_baseFeeVaultRecipient_zero_address_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/baseFeeVaultRecipient-zero-address-config.toml";
        vm.expectRevert("baseFeeVaultRecipient must be set in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the l1 fee vault recipient is a zero address.
    function test_revenueShareUpgradePath_l1FeeVaultRecipient_zero_address_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/l1FeeVaultRecipient-zero-address-config.toml";
        vm.expectRevert("l1FeeVaultRecipient must be set in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the sequencer fee vault recipient is a zero address.
    function test_revenueShareUpgradePath_sequencerFeeVaultRecipient_zero_address_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/sequencerFeeVaultRecipient-zero-address-config.toml";
        vm.expectRevert("sequencerFeeVaultRecipient must be set in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the operator fee vault recipient is a zero address.
    function test_revenueShareUpgradePath_operatorFeeVaultRecipient_zero_address_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/operatorFeeVaultRecipient-zero-address-config.toml";
        vm.expectRevert("operatorFeeVaultRecipient must be set in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the base fee vault withdrawal network is invalid.
    function test_revenueShareUpgradePath_baseFeeVaultWithdrawalNetwork_invalid_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/baseFeeVaultWithdrawalNetwork-invalid-config.toml";
        vm.expectRevert("baseFeeVaultWithdrawalNetwork must be set to either 0 (L1) or 1 (L2) in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the l1 fee vault withdrawal network is invalid.
    function test_revenueShareUpgradePath_l1FeeVaultWithdrawalNetwork_invalid_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/l1FeeVaultWithdrawalNetwork-invalid-config.toml";
        vm.expectRevert("l1FeeVaultWithdrawalNetwork must be set to either 0 (L1) or 1 (L2) in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the sequencer fee vault withdrawal network is invalid.
    function test_revenueShareUpgradePath_sequencerFeeVaultWithdrawalNetwork_invalid_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/sequencerFeeVaultWithdrawalNetwork-invalid-config.toml";
        vm.expectRevert("sequencerFeeVaultWithdrawalNetwork must be set to either 0 (L1) or 1 (L2) in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the operator fee vault withdrawal network is invalid.
    function test_revenueShareUpgradePath_operatorFeeVaultWithdrawalNetwork_invalid_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/operatorFeeVaultWithdrawalNetwork-invalid-config.toml";
        vm.expectRevert("operatorFeeVaultWithdrawalNetwork must be set to either 0 (L1) or 1 (L2) in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the l1 withdrawer recipient is a zero address.
    function test_revenueShareUpgradePath_l1WithdrawerRecipient_zero_address_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/l1WithdrawerRecipient-zero-address-config.toml";
        vm.expectRevert("l1WithdrawerRecipient must be set in config");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the l1 withdrawer gas limit is zero.
    function test_revenueShareUpgradePath_l1WithdrawerGasLimit_zero_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/l1WithdrawerGasLimit-zero-config.toml";
        vm.expectRevert("l1WithdrawerGasLimit must be greater than 0");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the l1 withdrawer gas limit is too high.
    function test_revenueShareUpgradePath_l1WithdrawerGasLimit_too_high_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/l1WithdrawerGasLimit-too-high-config.toml";
        vm.expectRevert("l1WithdrawerGasLimit must be less than uint32.max");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the chain fees recipient is a zero address.
    function test_revenueShareUpgradePath_scRevShareCalcChainFeesRecipient_zero_address_reverts() public {
        string memory configPath =
            "test/template/revenue-share-upgrade-path/config/scRevShareCalcChainFeesRecipient-zero-address-config.toml";
        vm.expectRevert("scRevShareCalcChainFeesRecipient must be set in config");
        template.simulate(configPath);
    }
}
