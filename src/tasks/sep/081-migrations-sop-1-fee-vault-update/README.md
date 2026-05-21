# 081-migrations-sop-1-fee-vault-update

Status: DRAFT — NOT READY TO SIGN

## Objective

Deploys new v1.6.0 fee-vault implementations on `migrations-sop-1` (chainId 420120110, Sepolia) and upgrades the three predeploy proxies — `SequencerFeeVault`, `BaseFeeVault`, `L1FeeVault` — to them, each initialized with its own OP-controlled recipient. This is Migration Log step **15** (post-cutover).

| Vault | Predeploy | New recipient |
|-------|-----------|---------------|
| SequencerFeeVault | `0x4200…0011` | `0xced11d52f2262d51a1f05ef483e5fd24619ad130` (OP seqFee) |
| BaseFeeVault      | `0x4200…0019` | `0xde7d944a4b6314bbb9da10f89c6a685c2465cfa0` (OP baseFee) |
| L1FeeVault        | `0x4200…001a` | `0x1b8dc99ae8142303884eb0e8956007f622279d7e` (OP l1Fee) |

Each upgrade is performed via `OptimismPortal2.depositTransaction` calls batched through `Multicall3.aggregate3Value`, sending L1→L2 messages to:

1. **CREATE2-deploy** the new impl bytecode on L2 (one for `SequencerFeeVault`, one shared between `BaseFeeVault` & `L1FeeVault`).
2. **`ProxyAdmin.upgradeAndCall`** each proxy to the deployed impl, calling `initialize(recipient, 0, WithdrawalNetwork.L1)`.

Total: **5 portal deposits** in one Safe transaction (2 deploys + 3 upgrades). All signed by the L1 ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`).

> [!IMPORTANT]
> Unlike the prior draft of this task, the new impls **do not** require pre-deployment — they are deployed and initialized atomically in this single transaction. The recipient is stored in v1.6.0 contract storage (settable post-init), so a single shared default-impl bytecode serves both `BaseFeeVault` and `L1FeeVault` despite having different recipients.

## Execution order

This task is **Migration Log step 15**. Run **after** the chain-cutover sequence:
1. `076-migrations-sop-1-add-game-type`
2. `077-migrations-sop-1-set-respected-game-type`
3. `078-migrations-sop-1-transfer-system-config-owner` (EOA-signed)
4. `079-migrations-sop-1-set-batcher-unsafe-signer`
5. `080-migrations-sop-1-proposer-rotation`
6. **`081-migrations-sop-1-fee-vault-update`** ← this task

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/081-migrations-sop-1-fee-vault-update
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate
```

Signing commands:
```bash
cd src/tasks/sep/081-migrations-sop-1-fee-vault-update
just --dotenv-path $(pwd)/.env sign
```
