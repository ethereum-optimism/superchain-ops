# 079-migrations-sop-1-set-batcher-unsafe-signer

Status: **NO-OP** — both target values are already set on-chain as of 2026-05-22.

> **On-chain check (Sepolia):**
> - `SystemConfig.batcherHash()` = `0x000…973c3abee371b32838e672411f386404bac704f3` (already OP batcher)
> - `SystemConfig.unsafeBlockSigner()` = `0x8cBf8D7Ad5B2F12C5FFC255d2982Ec39f9DF1991` (already OP sequencer)
>
> Re-running the simulation reverts with `SetBatcherAndOrSigner: no-op (both fields already match current values)`. This task should be **skipped** unless one of the two values is later rotated and needs to be restored. The Migration Log steps 3/4 are effectively already satisfied on-chain.

## Objective

Registers the OP batcher and OP unsafe block signer on the `migrations-sop-1` (chainId 420120110) `SystemConfig`. This batches Migration Log steps **3** (`setBatcherHash`) and **4** (`setUnsafeBlockSigner`) into a single Multicall3 transaction.

- **Batcher**: `0x973c3abee371b32838e672411f386404bac704f3` (OP batcher)
- **UnsafeBlockSigner**: `0x8cbf8d7ad5b2f12c5ffc255d2982ec39f9df1991` (OP sequencer)
- **Target**: `SystemConfigProxy` `0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`
- **Signer**: OPE Admin Safe `0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`

> [!IMPORTANT]
> This task can only run AFTER [078-migrations-sop-1-transfer-system-config-owner](../078-migrations-sop-1-transfer-system-config-owner/) has executed on-chain — the OPE Admin Safe must be the current `SystemConfig` owner for these setters to authorize.

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/079-migrations-sop-1-set-batcher-unsafe-signer
just simulate-stack sep 079-migrations-sop-1-set-batcher-unsafe-signer
```

Signing commands:
```bash
cd src/tasks/sep/079-migrations-sop-1-set-batcher-unsafe-signer
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
