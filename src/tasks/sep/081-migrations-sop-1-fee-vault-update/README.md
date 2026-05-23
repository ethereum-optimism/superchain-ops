# 081-migrations-sop-1-fee-vault-update

Status: DRAFT, NOT READY TO SIGN

## Objective

Deploys new v1.6.0 fee-vault implementations on `migrations-sop-1` (chainId 420120110, Sepolia) and upgrades the three predeploy proxies — `SequencerFeeVault`, `BaseFeeVault`, `L1FeeVault` — to them, each initialized with its own OP-controlled recipient. This is Migration Log step **15** (post-cutover).

Each upgrade is performed via `OptimismPortal2.depositTransaction` calls batched through `Multicall3.aggregate3Value`, sending L1→L2 messages to:

1. **CREATE2-deploy** the new impl bytecode on L2 (one for `SequencerFeeVault`, one shared between `BaseFeeVault` & `L1FeeVault`).
2. **`ProxyAdmin.upgradeAndCall`** each proxy to the deployed impl, calling `initialize(recipient, 0, WithdrawalNetwork.L1)`.

Total: **5 portal deposits** in one Safe transaction (2 deploys + 3 upgrades). All signed by the L1 ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`).

## State Changes

All state changes land on the **migrations-sop-1 L2** (chainId 420120110) once the portal deposits are relayed. The current recipient on each vault is held in the v1.6.0 impl storage slot — but migrations-sop-1 is a **private devnet**, so the "current" column can't be read from this repo's RPCs. Operators must verify with the private L2 RPC before signing.

| L2 Vault | L2 Predeploy | Current recipient | New recipient |
|----------|--------------|-------------------|---------------|
| SequencerFeeVault | `0x4200000000000000000000000000000000000011` | _read via `cast call 0x4200…0011 "RECIPIENT()(address)" --rpc-url <MIGRATIONS_SOP_1_L2_RPC>`_ | `0xced11d52f2262d51a1f05ef483e5fd24619ad130` |
| BaseFeeVault | `0x4200000000000000000000000000000000000019` | _read via same pattern on `0x4200…0019`_ | `0xde7d944a4b6314bbb9da10f89c6a685c2465cfa0` |
| L1FeeVault | `0x420000000000000000000000000000000000001a` | _read via same pattern on `0x4200…001a`_ | `0x1b8dc99ae8142303884eb0e8956007f622279d7e` |

Each vault is also re-initialized with:

| Field | New value |
|-------|-----------|
| `MIN_WITHDRAWAL_AMOUNT()` | `0` |
| `WITHDRAWAL_NETWORK()` | `0` (= `WithdrawalNetwork.L1`) |
| proxy impl slot | new v1.6.0 implementation (CREATE2-deployed in this task; deterministic addresses) |

- **Current values**: not fetchable from this repo (private L2). The post-execution verification block at the end of [VALIDATION.md](./VALIDATION.md) shows the `cast call` commands the operator runs against the L2 to confirm pre- and post-state.
- **New recipients**: per [Chain Migration Log step 15](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e). These are OP-controlled — replace with `0xdead…` placeholders the same way as 079 if you only want CI/sim to pass.

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
