# 081-migrations-sop-1-fee-vault-update

Status: DRAFT, NOT READY TO SIGN

## Objective

Deploys new v1.6.0 fee-vault implementations on `migrations-sop-1` (chainId 420120110, Sepolia) and upgrades the four predeploy proxies — `SequencerFeeVault`, `BaseFeeVault`, `L1FeeVault`, `OperatorFeeVault` — to them, each initialized with its own recipient. This is Migration Log step **15** (post-cutover).

Each upgrade is performed via `OptimismPortal2.depositTransaction` calls batched through `Multicall3.aggregate3Value`, sending L1→L2 messages to:

1. **CREATE2-deploy** the new impl bytecode on L2 (one for `SequencerFeeVault`, one shared between `BaseFeeVault` & `L1FeeVault`, one for `OperatorFeeVault`).
2. **`ProxyAdmin.upgradeAndCall`** each proxy to the deployed impl, calling `initialize(recipient, 0, WithdrawalNetwork.L1)`.

Total: **7 portal deposits** in one Safe transaction (3 deploys + 4 upgrades). All signed by the L1 ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`).

## State Changes

State changes land on the **migrations-sop-1 L2** (chainId 420120110) once the portal deposits are relayed. The chain currently has the OP-controlled recipients from the Migration Log already set on-chain (verified via `https://migrations-sop-1.optimism.io`); this task **overwrites them with `0xdead…` test placeholders** for the migration exercise.

| L2 Vault | L2 Predeploy | Current recipient (on-chain) | New recipient (this task) |
|----------|--------------|-------------------------------|---------------------------|
| SequencerFeeVault | `0x4200000000000000000000000000000000000011` | `0xCEd11d52f2262d51a1f05eF483e5FD24619AD130` | `0xdead000000000000000000000000000000000011` |
| BaseFeeVault | `0x4200000000000000000000000000000000000019` | `0xde7d944A4b6314bbB9Da10F89c6A685c2465Cfa0` | `0xdead000000000000000000000000000000000019` |
| L1FeeVault | `0x420000000000000000000000000000000000001a` | `0x1B8dC99Ae8142303884EB0E8956007f622279d7e` | `0xdead00000000000000000000000000000000001a` |
| OperatorFeeVault | `0x420000000000000000000000000000000000001b` | `0x8a3d5BA5d653111f80E2d5fB12B6Ff6381711B45` | `0xdead00000000000000000000000000000000001b` |

Each vault is also re-initialized with:

| Field | Current (on-chain) | New (this task) |
|-------|--------------------|-----------------|
| `MIN_WITHDRAWAL_AMOUNT()` | `10000000000000000000` (10 ETH, on Sequencer; check L2 RPC for others) | `0` |
| `WITHDRAWAL_NETWORK()` | `1` (L2) | `0` (L1) |
| proxy impl slot | v1.6.0 | new v1.6.0 implementation (CREATE2-deployed in this task; deterministic addresses) |

- **Current values**: read on-chain at 2026-05-23 via `cast call <vault> "RECIPIENT()(address)" --rpc-url https://migrations-sop-1.optimism.io`. All four already match the Migration Log "OP Infrastructure → FeeVault recipients" entries — the chain was bootstrapped straight into the post-cutover recipient state.
- **New recipients**: `0xdead…` test placeholders chosen so the low-nibble matches the predeploy slot (visually obvious mapping). Replace with the real OP-controlled recipients from the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) (seqFee `0xced11d52…`, baseFee `0xde7d944a…`, l1Fee `0x1b8dc99a…`, opFee `0x8a3d5ba5…`) before any production signing.

> [!IMPORTANT]
> Unlike the prior draft of this task, the new impls **do not** require pre-deployment — they are deployed and initialized atomically in this single transaction. The recipient is stored in v1.6.0 contract storage (settable post-init), so a single shared default-impl bytecode serves both `BaseFeeVault` and `L1FeeVault` despite having different recipients.

## Execution order

This task is **Migration Log step 15**. Run **after** the chain-cutover sequence:
1. `076-migrations-sop-1-add-game-type`
2. `077-migrations-sop-1-set-respected-game-type`
3. `078-migrations-sop-1-transfer-system-config-owner` (Safe-signed by Safe A → OPE Receiving Safe / Safe B)
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
