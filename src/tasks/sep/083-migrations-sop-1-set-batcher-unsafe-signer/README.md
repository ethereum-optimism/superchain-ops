# 083-migrations-sop-1-set-batcher-unsafe-signer

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x6eebd08849b13d1f5245860b609b60e24bbd8a9209f26dd2873bf4d3d8a3ffc0)

## Objective

Registers the batcher and unsafe block signer on the `migrations-sop-1` (chainId 420120110) `SystemConfig`. This batches Migration Log steps **3** (`setBatcherHash`) and **4** (`setUnsafeBlockSigner`) into a single Multicall3 transaction.

- **Batcher**: `0x9bEE5085CB02BFb26E5838b88F2d3827401865Ce` (migrated-sop-1 receiving infra)
- **UnsafeBlockSigner**: `0x224C4E0a1d99CE75671C2C3f2a54ab775b999f90` (migrated-sop-1 receiving infra)
- **Target**: `SystemConfigProxy` `0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`
- **Signer**: OPE Receiving Safe (Safe B) `0xb3228B623da92283280C87aB8019A405967A2B8f`

> [!IMPORTANT]
> This task can only run AFTER [082-migrations-sop-1-transfer-system-config-owner](../082-migrations-sop-1-transfer-system-config-owner/) has executed on-chain — the OPE Receiving Safe (Safe B) must be the current `SystemConfig` owner for these setters to authorize.

## State Changes

Writes to `SystemConfigProxy` ([`0xc771958a…f9Fc`](https://sepolia.etherscan.io/address/0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc#readProxyContract)):

| Field | Current (on-chain) | New |
|-------|--------------------|-----|
| `batcherHash()` | `0x000000000000000000000000973c3abee371b32838e672411f386404bac704f3` | `0x0000000000000000000000009bee5085cb02bfb26e5838b88f2d3827401865ce` |
| `unsafeBlockSigner()` | `0x8cBf8D7Ad5B2F12C5FFC255d2982Ec39f9DF1991` | `0x224C4E0a1d99CE75671C2C3f2a54ab775b999f90` |

- **Current values**: read on-chain on Sepolia at block 10900000 from the SystemConfig (link above). Verified with `cast call 0xc771958a… "batcherHash()(bytes32)"` and `"unsafeBlockSigner()(address)"`.
- **New values**: receiving infrastructure addresses for the `migrated-sop-1` (permissionless) chain post-migration. Sourced from the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e).

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
