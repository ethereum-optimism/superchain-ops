# 083-migrations-sop-1-set-batcher-unsafe-signer

Status: DRAFT, NOT READY TO SIGN

## Objective

Registers the batcher and unsafe block signer on the `migrations-sop-1` (chainId 420120110) `SystemConfig`. This batches Migration Log steps **3** (`setBatcherHash`) and **4** (`setUnsafeBlockSigner`) into a single Multicall3 transaction.

- **Batcher**: `0xdead000000000000000000000000000000000001` (test placeholder)
- **UnsafeBlockSigner**: `0xdead000000000000000000000000000000000002` (test placeholder)
- **Target**: `SystemConfigProxy` `0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`
- **Signer**: OPE Receiving Safe (Safe B) `0xb3228B623da92283280C87aB8019A405967A2B8f`

> [!IMPORTANT]
> This task can only run AFTER [082-migrations-sop-1-transfer-system-config-owner](../082-migrations-sop-1-transfer-system-config-owner/) has executed on-chain — the OPE Receiving Safe (Safe B) must be the current `SystemConfig` owner for these setters to authorize.

## State Changes

Writes to `SystemConfigProxy` ([`0xc771958a…f9Fc`](https://sepolia.etherscan.io/address/0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc#readProxyContract)):

| Field | Current (on-chain) | New |
|-------|--------------------|-----|
| `batcherHash()` | `0x000000000000000000000000973c3abee371b32838e672411f386404bac704f3` | `0x000000000000000000000000dead000000000000000000000000000000000001` |
| `unsafeBlockSigner()` | `0x8cBf8D7Ad5B2F12C5FFC255d2982Ec39f9DF1991` | `0xdead000000000000000000000000000000000002` |

- **Current values**: read on-chain on Sepolia at block 10900000 from the SystemConfig (link above). Verified with `cast call 0xc771958a… "batcherHash()(bytes32)"` and `"unsafeBlockSigner()(address)"`.
- **New values**: `0xdead…0001` and `0xdead…0002` are test placeholders chosen for CI/sim only — they do **not** correspond to real OP-controlled keys. Replace with production batcher / sequencer addresses (e.g. from the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e)) before any live signing.

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/083-migrations-sop-1-set-batcher-unsafe-signer
just simulate-stack sep 083-migrations-sop-1-set-batcher-unsafe-signer
```

Signing commands:
```bash
cd src/tasks/sep/083-migrations-sop-1-set-batcher-unsafe-signer
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
