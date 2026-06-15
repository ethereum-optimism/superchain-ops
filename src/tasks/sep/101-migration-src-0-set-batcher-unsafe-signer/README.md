# 101-migration-src-0-set-batcher-unsafe-signer

Status: DRAFT, NOT READY TO SIGN

> [!NOTE]
> Requires the EOA → Safe B `SystemConfig.transferOwnership` (Migration Log step 1) to be executed **outside this repo** before on-chain execution. The hashes in [VALIDATION.md](./VALIDATION.md) were generated with a `SystemConfig.owner → Safe B` simulation override; once the transfer is on-chain the override is a no-op and the hashes hold (re-run `just simulate` to confirm if Safe B's nonce has moved).

## Objective

Registers the batcher and unsafe block signer on the `migration-src-0` (chainId 420120140) `SystemConfig` as part of the **Type A chain-migration exercise** that moves `migration-src-0` onto the `migrated-sop-1` operator infrastructure. This batches Migration Log steps **3** (`setBatcherHash`) and **4** (`setUnsafeBlockSigner`) into a single Multicall3 transaction.

The receiving infrastructure is `migrated-sop-1` (the FROM side of this exercise); the values below are `migrated-sop-1`'s live batcher / unsafe block signer, read on-chain from its `SystemConfig` (`0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`).

- **Batcher**: `0x9bEE5085CB02BFb26E5838b88F2d3827401865Ce` (migrated-sop-1 infra)
- **UnsafeBlockSigner**: `0x224C4E0a1d99CE75671C2C3f2a54ab775b999f90` (migrated-sop-1 infra)
- **Target**: `SystemConfigProxy` `0xeb776E1d4cda95D4155e73c5ceE34b9f7C2EE818`
- **Signer**: OPE Receiving Safe (Safe B) `0xb3228B623da92283280C87aB8019A405967A2B8f` — the same Safe that currently owns `migrated-sop-1`'s SystemConfig.

> [!IMPORTANT]
> This task assumes the `SystemConfig` owner is the OPE Receiving Safe (Safe B). On `migration-src-0` the owner is currently an **EOA** (`0x8f6C6dE7cAfE9b3367f194f2403697bbAa0bA65F`); the EOA → Safe B ownership transfer is performed **outside this repo** (Migration Log step 1). For simulation, [config.toml](./config.toml) overrides `SystemConfig.owner()` to Safe B. Remove that override once the transfer is executed on-chain.

## State Changes

Writes to `SystemConfigProxy` ([`0xeb776E1d…EE818`](https://sepolia.etherscan.io/address/0xeb776E1d4cda95D4155e73c5ceE34b9f7C2EE818#readProxyContract)):

| Field | Current (on-chain) | New |
|-------|--------------------|-----|
| `batcherHash()` | `0x0000000000000000000000009829eb0da5d44de187ddbd8cd6daeb6fc9495931` | `0x0000000000000000000000009bee5085cb02bfb26e5838b88f2d3827401865ce` |
| `unsafeBlockSigner()` | `0x5887E87eE14012453e5a3C101d8A7f42E0E99853` | `0x224C4E0a1d99CE75671C2C3f2a54ab775b999f90` |

- **Current values**: read on-chain on Sepolia from the SystemConfig (link above). Verified with `cast call 0xeb776E1d… "batcherHash()(bytes32)"` and `"unsafeBlockSigner()(address)"`.
- **New values**: `migrated-sop-1` receiving infrastructure, read on-chain from `migrated-sop-1`'s SystemConfig (`cast call 0xc771958a… "batcherHash()(bytes32)" / "unsafeBlockSigner()(address)"`).

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/101-migration-src-0-set-batcher-unsafe-signer
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
```

Signing commands:
```bash
cd src/tasks/sep/101-migration-src-0-set-batcher-unsafe-signer
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprints.
