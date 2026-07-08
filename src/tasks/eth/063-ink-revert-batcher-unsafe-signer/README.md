# 063-ink-revert-batcher-unsafe-signer: ROLLBACK — restore Gelato batcher & unsafe block signer

Status: DRAFT — CONTINGENCY / ROLLBACK. NOT READY TO SIGN. Use only if the Ink mainnet Gelato → OPE migration must be aborted.

## Objective

Restores the **original Gelato** batcher and unsafe block signer on the **Ink mainnet** (chainId 57073) `SystemConfig`, reversing [`eth/060-ink-set-batcher-unsafe-signer`](../060-ink-set-batcher-unsafe-signer) (cutover steps 2 & 3). Batches `setBatcherHash` + `setUnsafeBlockSigner` into a single Multicall3 transaction.

| Field | Post-migration (OPE) | Restore to (Gelato) |
|-------|----------------------|---------------------|
| `batcherHash()` | OPE batcher | `TODO` pre-migration Gelato batcher (role audit §3.1) |
| `unsafeBlockSigner()` | OPE sequencer | `TODO` pre-migration Gelato unsafe signer (role audit §3.1) |

- **Target**: `SystemConfigProxy` [`0x62C0a111…E8364`](https://etherscan.io/address/0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364)
- **Signer**: `FoundationOperationsSafe` [`0x9BA6e03D…006b3A`](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A) — the post-migration SystemConfig owner.

> [!CAUTION]
> The restore values are the **pre-migration Gelato** batcher and unsafe block signer. Capture them on-chain **before** the forward migration executes (role audit §3.1 / execution log) and pin them here — do not guess. The registry only carries the genesis batcher (`0x500d7Ea63CF2E501dadaA5feeC1FC19FE2Aa72Ac`), which may differ from the live pre-migration value.

> [!IMPORTANT]
> This task assumes `SystemConfig.owner()` is the `FoundationOperationsSafe` (post-migration). Run it **before** the ownership revert [`062`](../062-ink-revert-system-config-owner), while the OP side still controls SystemConfig. [config.toml](./config.toml) overrides slot `0x33` → FOS for standalone simulation; remove that once the forward migration has executed.

## State Changes

Writes to `SystemConfigProxy` ([`0x62C0a111…E8364`](https://etherscan.io/address/0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364#readProxyContract)):

- `batcherHash()` → pre-migration Gelato batcher (left-padded to 32 bytes).
- `unsafeBlockSigner()` → pre-migration Gelato unsafe block signer.

Plus the FoundationOperationsSafe nonce increments by 1. (The slot-`0x33` owner value is a simulation-only override — see above.)

## Simulation & Signing

```bash
cd src/tasks/eth/063-ink-revert-batcher-unsafe-signer
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "batcherHash()(bytes32)" --rpc-url mainnet
# Expected: 0x000000000000000000000000<Gelato batcher>
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "unsafeBlockSigner()(address)" --rpc-url mainnet
# Expected: <Gelato unsafe block signer>
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and calldata fingerprints.
