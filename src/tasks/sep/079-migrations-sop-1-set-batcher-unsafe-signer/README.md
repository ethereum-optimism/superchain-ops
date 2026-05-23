# 079-migrations-sop-1-set-batcher-unsafe-signer

Status: DRAFT, NOT READY TO SIGN

## Objective

Registers the batcher and unsafe block signer on the `migrations-sop-1` (chainId 420120110) `SystemConfig`. This batches Migration Log steps **3** (`setBatcherHash`) and **4** (`setUnsafeBlockSigner`) into a single Multicall3 transaction.

- **Batcher**: `0xdead000000000000000000000000000000000001` (test placeholder)
- **UnsafeBlockSigner**: `0xdead000000000000000000000000000000000002` (test placeholder)
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
