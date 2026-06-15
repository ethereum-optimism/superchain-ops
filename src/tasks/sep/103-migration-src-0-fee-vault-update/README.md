# 103-migration-src-0-fee-vault-update

Status: [READY TO SIGN]()

## Objective

Deploys new v1.6.0 fee-vault implementations on `migration-src-0` (chainId 420120140, Sepolia) and upgrades the four predeploy proxies — `SequencerFeeVault`, `BaseFeeVault`, `L1FeeVault`, `OperatorFeeVault` — to them, each initialized with its own recipient. This is Migration Log step **15** (post-cutover) of the Type A migration exercise.

Each upgrade is performed via `OptimismPortal2.depositTransaction` calls batched through `Multicall3.aggregate3Value`, sending L1→L2 messages to:

1. **CREATE2-deploy** the new impl bytecode on L2 (one for `SequencerFeeVault`, one shared between `BaseFeeVault` & `L1FeeVault`, one for `OperatorFeeVault`).
2. **`ProxyAdmin.upgradeAndCall`** each proxy to the deployed impl, calling `initialize(recipient, 0, WithdrawalNetwork.L1)`.

Total: **7 portal deposits** in one Safe transaction (3 deploys + 4 upgrades). All signed by the L1 ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`).

## State Changes

State changes land on the **migration-src-0 L2** (chainId 420120140) once the portal deposits are relayed.

| L2 Vault | L2 Predeploy | New recipient (this task) |
|----------|--------------|---------------------------|
| SequencerFeeVault | `0x4200000000000000000000000000000000000011` | `0xdead000000000000000000000000000000000011` |
| BaseFeeVault | `0x4200000000000000000000000000000000000019` | `0xdead000000000000000000000000000000000019` |
| L1FeeVault | `0x420000000000000000000000000000000000001a` | `0xdead00000000000000000000000000000000001a` |
| OperatorFeeVault | `0x420000000000000000000000000000000000001b` | `0xdead00000000000000000000000000000000001b` |

Each vault is also re-initialized with `MIN_WITHDRAWAL_AMOUNT() = 0` and `WITHDRAWAL_NETWORK() = 0` (L1), and its proxy impl slot is set to the newly CREATE2-deployed v1.6.0 implementation (deterministic addresses).

> [!IMPORTANT]
> The recipients above are **`0xdead…` test placeholders** for the migration exercise (low nibble matches the predeploy slot for a visually obvious state diff). Replace with the real OP-controlled recipients from the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) before any production signing.

> [!IMPORTANT]
> The new impls are deployed and initialized atomically in this single transaction (no pre-deployment required). The recipient is stored in v1.6.0 contract storage (settable post-init), so a single shared default-impl bytecode serves both `BaseFeeVault` and `L1FeeVault` despite different recipients.

## Execution order

This task is **Migration Log step 15**. Run **after** the chain-cutover sequence for this exercise:
1. (out-of-ops) EOA → Safe B `SystemConfig.transferOwnership`
2. `101-migration-src-0-set-batcher-unsafe-signer`
3. `102-migration-src-0-proposer-rotation`
4. **`103-migration-src-0-fee-vault-update`** ← this task

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/103-migration-src-0-fee-vault-update
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate
```

Signing commands:
```bash
cd src/tasks/sep/103-migration-src-0-fee-vault-update
just --dotenv-path $(pwd)/.env sign
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the state changes.
