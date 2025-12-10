// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {RevShareContractsUpgrader} from "src/RevShareContractsUpgrader.sol";
import {RevShareUpgradeAndSetup} from "src/template/RevShareUpgradeAndSetup.sol";
import {IntegrationBase} from "./IntegrationBase.t.sol";

contract RevShareContractsUpgraderIntegrationTest is IntegrationBase {
    RevShareUpgradeAndSetup public revShareTask;

    function setUp() public {
        // Create forks for L1 (mainnet) and L2s (Ink and Soneium only - need proxy upgrade)
        _mainnetForkId = vm.createFork("http://127.0.0.1:8545");
        _inkMainnetForkId = vm.createFork("http://127.0.0.1:9546");
        _soneiumMainnetForkId = vm.createFork("http://127.0.0.1:9547");

        // Deploy contracts on L1
        vm.selectFork(_mainnetForkId);

        // Deploy RevShareContractsUpgrader and etch at predetermined address
        revShareUpgrader = new RevShareContractsUpgrader();
        vm.etch(REV_SHARE_UPGRADER_ADDRESS, address(revShareUpgrader).code);
        revShareUpgrader = RevShareContractsUpgrader(REV_SHARE_UPGRADER_ADDRESS);

        // Deploy RevShareUpgradeAndSetup task
        revShareTask = new RevShareUpgradeAndSetup();
    }

    /// @notice Test the integration of upgradeAndSetupRevShare (Ink and Soneium only - need proxy upgrade)
    function test_upgradeAndSetupRevShare_integration() public {
        // Step 1: Record logs for L1→L2 message relay
        vm.recordLogs();

        // Step 2: Execute task simulation
        revShareTask.simulate("test/tasks/example/eth/017-revshare-upgrade-and-setup-sony-ink/config.toml");

        // Step 3: Relay deposit transactions from L1 to Ink and Soneium
        uint256[] memory forkIds = new uint256[](2);
        forkIds[0] = _inkMainnetForkId;
        forkIds[1] = _soneiumMainnetForkId;

        address[] memory portals = new address[](2);
        portals[0] = INK_MAINNET_PORTAL;
        portals[1] = SONEIUM_MAINNET_PORTAL;

        _relayAllMessages(forkIds, IS_SIMULATE, portals);

        // Step 4: Assert the state of the Ink Mainnet contracts
        vm.selectFork(_inkMainnetForkId);
        address inkL1Withdrawer = _computeL1WithdrawerAddress(
            INK_MIN_WITHDRAWAL_AMOUNT, INK_L1_WITHDRAWAL_RECIPIENT, INK_WITHDRAWAL_GAS_LIMIT
        );
        address inkRevShareCalculator = _computeRevShareCalculatorAddress(inkL1Withdrawer, INK_CHAIN_FEES_RECIPIENT);
        _assertL2State(
            inkL1Withdrawer,
            inkRevShareCalculator,
            INK_MIN_WITHDRAWAL_AMOUNT,
            INK_L1_WITHDRAWAL_RECIPIENT,
            INK_WITHDRAWAL_GAS_LIMIT,
            INK_CHAIN_FEES_RECIPIENT
        );

        // Step 5: Assert the state of the Soneium Mainnet contracts
        vm.selectFork(_soneiumMainnetForkId);
        address soneiumL1Withdrawer = _computeL1WithdrawerAddress(
            SONEIUM_MIN_WITHDRAWAL_AMOUNT, SONEIUM_L1_WITHDRAWAL_RECIPIENT, SONEIUM_WITHDRAWAL_GAS_LIMIT
        );
        address soneiumRevShareCalculator =
            _computeRevShareCalculatorAddress(soneiumL1Withdrawer, SONEIUM_CHAIN_FEES_RECIPIENT);
        _assertL2State(
            soneiumL1Withdrawer,
            soneiumRevShareCalculator,
            SONEIUM_MIN_WITHDRAWAL_AMOUNT,
            SONEIUM_L1_WITHDRAWAL_RECIPIENT,
            SONEIUM_WITHDRAWAL_GAS_LIMIT,
            SONEIUM_CHAIN_FEES_RECIPIENT
        );

        // Step 6: Do a withdrawal flow

        // Fund vaults with amount > minWithdrawalAmount
        // It disburses 5 ether to each of the 4 vaults, so total sent is 20 ether per chain
        _fundVaults(5 ether, _inkMainnetForkId);
        _fundVaults(5 ether, _soneiumMainnetForkId);

        // Disburse fees in all chains and expect the L1Withdrawer to trigger the withdrawal
        // Expected L1Withdrawer share = 15 ether * 15% = 2.25 ether
        // It is 15 ether instead of 20 because net revenue doesn't count L1FeeVault's balance
        // For details on the rev share calculation, check the SuperchainRevSharesCalculator contract.
        // https://github.com/ethereum-optimism/optimism/blob/f392d4b7e8bc5d1c8d38fcf19c8848764f8bee3b/packages/contracts-bedrock/src/L2/SuperchainRevSharesCalculator.sol#L67-L101
        uint256 expectedWithdrawalAmount = 2.25 ether;

        _executeDisburseAndAssertWithdrawal(_inkMainnetForkId, INK_L1_WITHDRAWAL_RECIPIENT, expectedWithdrawalAmount);
        _executeDisburseAndAssertWithdrawal(
            _soneiumMainnetForkId, SONEIUM_L1_WITHDRAWAL_RECIPIENT, expectedWithdrawalAmount
        );
    }
}
