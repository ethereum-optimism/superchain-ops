# 078-migrations-sop-1-transfer-system-config-owner

Status: DRAFT — NOT READY TO SIGN

## Objective

Transfers ownership of the `migrations-sop-1` (chainId 420120110) `SystemConfigProxy` from the current owner (OPE Admin Safe) to safeB. The prior EOA → OPE Admin Safe transfer is assumed to have already executed on-chain.

- **Current owner** (signer): `0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9` (OPE Admin Safe on Sepolia)
- **New owner**: `0xb3228B623da92283280C87aB8019A405967A2B8f` (safeB)
- **Target**: `SystemConfigProxy` `0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`

> [!CAUTION]
> Ownership transfers are **irreversible**. Per the Migration Log, the receiving Safe must be verified by **≥3 OP Labs engineers** before executing.

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/078-migrations-sop-1-transfer-system-config-owner
just simulate-stack sep 078-migrations-sop-1-transfer-system-config-owner
```

Signing commands:
```bash
cd src/tasks/sep/078-migrations-sop-1-transfer-system-config-owner
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
