// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {RevShareContractsUpgrader} from "src/RevShareContractsUpgrader.sol";
import {RevShareUpgradeAndSetup} from "src/template/RevShareUpgradeAndSetup.sol";
import {IntegrationBase} from "./IntegrationBase.t.sol";

contract RevShareContractsUpgraderIntegrationTest is IntegrationBase {
    RevShareUpgradeAndSetup public revShareTask;

    function setUp() public {
        // Create forks for L1 (mainnet) and L2 (OP Mainnet)
        _mainnetForkId = vm.createFork("http://127.0.0.1:8545");
        _opMainnetForkId = vm.createFork("http://127.0.0.1:9545");
        _inkMainnetForkId = vm.createFork("http://127.0.0.1:9546");

        // Deploy contracts on L1
        vm.selectFork(_mainnetForkId);

        // Deploy RevShareContractsUpgrader and etch at predetermined address
        revShareUpgrader = new RevShareContractsUpgrader();
        vm.etch(REV_SHARE_UPGRADER_ADDRESS, address(revShareUpgrader).code);
        revShareUpgrader = RevShareContractsUpgrader(REV_SHARE_UPGRADER_ADDRESS);

        // Deploy RevShareUpgradeAndSetup task
        revShareTask = new RevShareUpgradeAndSetup();
    }

    /// @notice Test the integration of upgradeAndSetupRevShare
    function test_upgradeAndSetupRevShare_integration() public {
        // Step 1: Record logs for L1→L2 message relay
        vm.recordLogs();

        // Step 2: Execute task simulation
        revShareTask.simulate("test/tasks/example/eth/016-revshare-upgrade-and-setup/config.toml");

        // Step 3: Relay deposit transactions from L1 to all L2s
        uint256[] memory forkIds = new uint256[](2);
        forkIds[0] = _opMainnetForkId;
        forkIds[1] = _inkMainnetForkId;

        address[] memory portals = new address[](2);
        portals[0] = OP_MAINNET_PORTAL;
        portals[1] = INK_MAINNET_PORTAL;

        _relayAllMessages(forkIds, IS_SIMULATE, portals);

        // Step 4: Assert the state of the OP Mainnet contracts
        vm.selectFork(_opMainnetForkId);
        _assertL2State(
            OP_L1_WITHDRAWER,
            OP_REV_SHARE_CALCULATOR,
            OP_MIN_WITHDRAWAL_AMOUNT,
            OP_L1_WITHDRAWAL_RECIPIENT,
            OP_WITHDRAWAL_GAS_LIMIT,
            OP_CHAIN_FEES_RECIPIENT
        );

        // Step 5: Assert the state of the Ink Mainnet contracts
        vm.selectFork(_inkMainnetForkId);
        _assertL2State(
            INK_L1_WITHDRAWER,
            INK_REV_SHARE_CALCULATOR,
            INK_MIN_WITHDRAWAL_AMOUNT,
            INK_L1_WITHDRAWAL_RECIPIENT,
            INK_WITHDRAWAL_GAS_LIMIT,
            INK_CHAIN_FEES_RECIPIENT
        );

        // Step 6: Do a withdrawal flow

        // Fund vaults with amount > minWithdrawalAmount
        _fundVaults(1 ether, _opMainnetForkId);
        _fundVaults(1 ether, _inkMainnetForkId);

        // Disburse fees in both chains and expect the L1Withdrawer to trigger the withdrawal
        // Expected L1Withdrawer share = 3 ether * 15% = 0.45 ether
        // It is 3 ether instead of 4 because net revenue doesn't count L1FeeVault's balance
        // For details on the rev share calculation, check the SuperchainRevSharesCalculator contract.
        // https://github.com/ethereum-optimism/optimism/blob/f392d4b7e8bc5d1c8d38fcf19c8848764f8bee3b/packages/contracts-bedrock/src/L2/SuperchainRevSharesCalculator.sol#L67-L101
        uint256 expectedWithdrawalAmount = 0.45 ether;

        _executeDisburseAndAssertWithdrawal(_opMainnetForkId, OP_L1_WITHDRAWAL_RECIPIENT, expectedWithdrawalAmount);
        _executeDisburseAndAssertWithdrawal(_inkMainnetForkId, INK_L1_WITHDRAWAL_RECIPIENT, expectedWithdrawalAmount);
    }
}
