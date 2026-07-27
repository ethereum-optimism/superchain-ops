// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IntegrationBase} from "test/integration/IntegrationBase.t.sol";
import {IFeeVault} from "src/interfaces/IFeeVault.sol";
import {SetFeeVaultConfig} from "src/template/SetFeeVaultConfig.sol";

/// @title SetFeeVaultConfigIntegrationTest
/// @notice Integration test that simulates the L1 task and replays the resulting deposit transactions
///         on a forked OP Sepolia L2 to verify the fee-vault config update end-to-end — i.e. that
///         `recipient()` / `withdrawalNetwork()` / `minWithdrawalAmount()` (and their legacy getters)
///         actually change on L2.
///
///         Reuses `IntegrationBase` for the deposit relay (`_relayAllMessages`), the fee-vault address
///         constants, and the getter assertions (`_assertVaultGetters`).
///
///         Manual-only (like the other *Integration* tests — CI runs `forge test --skip Integration`).
///         Provide RPC URLs or use the defaults:
///         - L1 (Sepolia):    default https://ci-sepolia-l1-archive.optimism.io or set SEPOLIA_RPC_URL
///         - L2 (OP Sepolia): default https://sepolia.optimism.io               or set OP_SEPOLIA_RPC_URL
///
///         Example:
///         forge test --match-test test_setFeeVaultConfig_integration -vvv
contract SetFeeVaultConfigIntegrationTest is IntegrationBase {
    SetFeeVaultConfig public template;

    uint256 internal sepoliaForkId;
    uint256 internal opSepoliaForkId;

    // OP Sepolia OptimismPortal on L1 (source: superchain-registry sepolia/op.toml).
    address internal constant OP_SEPOLIA_PORTAL = 0x16Fc5058F25648194471939df75CF27A2fdC48BC;

    // Expected end-state from test/tasks/example/sep/041-set-fee-vault-config/config.toml
    // (WithdrawalNetwork.L1, min 0, shared example recipient). L1_FEE_VAULT / OPERATOR_FEE_VAULT
    // come from IntegrationBase.
    address internal constant NEW_RECIPIENT = 0xE75f598754A552841E65f43197C85028874A96a4;
    uint256 internal constant NEW_MIN = 0;

    string internal constant CONFIG_PATH = "test/tasks/example/sep/041-set-fee-vault-config/config.toml";

    function setUp() public {
        sepoliaForkId = vm.createFork(vm.envOr("SEPOLIA_RPC_URL", string("https://ci-sepolia-l1-archive.optimism.io")));
        opSepoliaForkId = vm.createFork(vm.envOr("OP_SEPOLIA_RPC_URL", string("https://sepolia.optimism.io")));

        vm.selectFork(sepoliaForkId);
        template = new SetFeeVaultConfig();
    }

    /// @notice End-to-end: simulate the L1 task, replay the setter deposits on L2, verify final config.
    function test_setFeeVaultConfig_integration() public {
        // Simulate the L1 task, recording the emitted deposit events.
        vm.selectFork(sepoliaForkId);
        vm.recordLogs();
        template.simulate(CONFIG_PATH);

        // Relay the setter deposits onto the OP Sepolia L2 fork (asserts every deposit succeeds).
        uint256[] memory forkIds = new uint256[](1);
        forkIds[0] = opSepoliaForkId;
        address[] memory portals = new address[](1);
        portals[0] = OP_SEPOLIA_PORTAL;
        _relayAllMessages(forkIds, true, portals);

        // Verify both vaults ended up with the configured recipient / network / min. Reaching the
        // target recipient also proves the deposits landed (a no-op relay would leave the old value).
        vm.selectFork(opSepoliaForkId);
        _assertVaultGetters(L1_FEE_VAULT, NEW_RECIPIENT, IFeeVault.WithdrawalNetwork.L1, NEW_MIN);
        _assertVaultGetters(OPERATOR_FEE_VAULT, NEW_RECIPIENT, IFeeVault.WithdrawalNetwork.L1, NEW_MIN);
    }
}
