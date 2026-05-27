# 082-migrations-sop-1-transfer-system-config-owner

Status: DRAFT — NOT READY TO SIGN

## Objective

Transfers ownership of the `migrations-sop-1` (chainId 420120110) `SystemConfigProxy` from the current owner (Safe A) to the OPE Receiving Safe (Safe B). The prior EOA → Safe A transfer has already been executed on-chain.

- **Current owner** (signer): `0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9` — **Safe A**
- **New owner**: `0xb3228B623da92283280C87aB8019A405967A2B8f` — **OPE Receiving Safe (Safe B)**
- **Target**: `SystemConfigProxy` `0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`

> [!NOTE]
> Both Safe A and Safe B are OPE-controlled on Sepolia. For the migration exercise, **Safe A impersonates the Partner-side role** (it is what an upstream partner-owned Safe would look like at the start of the cutover) and Safe B is the OPE-side receiving Safe that holds SystemConfig ownership post-cutover. In a real Type A migration the same calldata applies; the signers behind Safe A would belong to the partner.

> [!CAUTION]
> Ownership transfers are **irreversible**. Per the Migration Log, the receiving Safe must be verified by **≥3 OP Labs engineers** before executing.

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/082-migrations-sop-1-transfer-system-config-owner
just simulate-stack sep 082-migrations-sop-1-transfer-system-config-owner
```

Signing commands:
```bash
cd src/tasks/sep/082-migrations-sop-1-transfer-system-config-owner
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
