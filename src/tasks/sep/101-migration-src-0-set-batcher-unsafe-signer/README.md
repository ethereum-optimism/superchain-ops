# 101-migration-src-0-set-batcher-unsafe-signer

Status: DRAFT, NOT READY TO SIGN

> [!NOTE]
> Requires the EOA → Safe B `SystemConfig.transferOwnership` (Migration Log step 1) to be executed **outside this repo** before on-chain execution. The hashes in [VALIDATION.md](./VALIDATION.md) were generated with a `SystemConfig.owner → Safe B` simulation override; once the transfer is on-chain the override is a no-op and the hashes hold (re-run `just simulate` to confirm if Safe B's nonce has moved).

## Objective

Registers the batcher and unsafe block signer on the `migration-src-0` (chainId 420120140) `SystemConfig` as part of the **Type A chain-migration exercise** that moves `migration-src-0` onto the `migration-dest-0` operator infrastructure. This batches Migration Log steps **3** (`setBatcherHash`) and **4** (`setUnsafeBlockSigner`) into a single Multicall3 transaction.

The receiving infrastructure is `migration-dest-0` (the destination operator for this exercise), per [devnets-private `dev/migration-dest-0`](https://github.com/ethereum-optimism/devnets-private/tree/main/dev/migration-dest-0/migration-dest-0); the values below are `migration-dest-0`'s batcher and sequencer (unsafe block signer).

- **Batcher**: `0x04bf2305DC047e9A00AD71c08c9e8DEC502091A2` (migration-dest-0 infra)
- **UnsafeBlockSigner**: `0x5D2680A041a63376071512eBF6f7fB3380Edad02` (migration-dest-0 infra)
- **Target**: `SystemConfigProxy` `0xeb776E1d4cda95D4155e73c5ceE34b9f7C2EE818`
- **Signer**: OPE Receiving Safe (Safe B) `0xb3228B623da92283280C87aB8019A405967A2B8f` — the destination operator's Safe for the `migration-dest-0` receiving infrastructure.

> [!IMPORTANT]
> This task assumes the `SystemConfig` owner is the OPE Receiving Safe (Safe B). On `migration-src-0` the owner is currently an **EOA** (`0x8f6C6dE7cAfE9b3367f194f2403697bbAa0bA65F`); the EOA → Safe B ownership transfer is performed **outside this repo** (Migration Log step 1). For simulation, [config.toml](./config.toml) overrides `SystemConfig.owner()` to Safe B. Remove that override once the transfer is executed on-chain.

## State Changes

Writes to `SystemConfigProxy` ([`0xeb776E1d…EE818`](https://sepolia.etherscan.io/address/0xeb776E1d4cda95D4155e73c5ceE34b9f7C2EE818#readProxyContract)):

| Field | Current (on-chain) | New |
|-------|--------------------|-----|
| `batcherHash()` | `0x0000000000000000000000009829eb0da5d44de187ddbd8cd6daeb6fc9495931` | `0x00000000000000000000000004bf2305dc047e9a00ad71c08c9e8dec502091a2` |
| `unsafeBlockSigner()` | `0x5887E87eE14012453e5a3C101d8A7f42E0E99853` | `0x5D2680A041a63376071512eBF6f7fB3380Edad02` |

- **Current values**: read on-chain on Sepolia from the SystemConfig (link above). Verified with `cast call 0xeb776E1d… "batcherHash()(bytes32)"` and `"unsafeBlockSigner()(address)"`.
- **New values**: `migration-dest-0` receiving infrastructure (batcher + sequencer), per [devnets-private `dev/migration-dest-0`](https://github.com/ethereum-optimism/devnets-private/tree/main/dev/migration-dest-0/migration-dest-0).

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
