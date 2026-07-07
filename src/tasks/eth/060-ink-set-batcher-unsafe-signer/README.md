# 060-ink-set-batcher-unsafe-signer

Status: DRAFT — warm-phase preparation (plan W23/W24). Not ready to sign: the OPE mainnet keys and the OPE Safe are placeholders until warm-phase key generation (W1–W4) lands. Fill every `TODO(Wxx)` from the mainnet role audit (§3) and key generation (§3.3), then `just simulate` to generate the hashes recorded in [VALIDATION.md](./VALIDATION.md).

## Objective

Registers the OP Enterprise (OPE) batcher and unsafe block signer on the **Ink mainnet** (chainId 57073) `SystemConfig` as part of the **Gelato → OPE rollup-operator migration** (Type A Standard OP Stack takeover). This batches cutover steps **2** (`setBatcherHash`) and **3** (`setUnsafeBlockSigner`) into a single Multicall3 transaction.

Source of truth: _Ink Mainnet Migration — Engineering Plan_ (§3.3 Addresses; target cutover 2026-07-28). This task is the mainnet counterpart of the Ink Sepolia rehearsal task `sep/101-ink-sepolia-set-batcher-unsafe-signer` (executed 2026-06-22).

| Field | Current (Gelato) | New (OPE) |
|-------|------------------|-----------|
| `batcherHash()` | CONFIRM on-chain (role audit §3.1) | `TODO(W3)` OPE batcher |
| `unsafeBlockSigner()` | CONFIRM on-chain (role audit §3.1) | `TODO(W2)` OPE sequencer |

- **Target**: `SystemConfigProxy` `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` (resolved from the superchain-registry).
- **Signer**: OPE Safe `TODO(§3.3)` — the SystemConfig owner after Gelato's W26 ownership transfer.

> [!IMPORTANT]
> This task assumes the `SystemConfig` owner is the **OPE Safe**. On Ink mainnet the owner is currently the **Gelato Safe** (CONFIRM exact address in the role audit); the Gelato → OPE `transferOwnership` is performed **outside this repo** by Gelato (Migration Plan steps **W25/W26**, irreversible — OPE receiving address verified by ≥3 OP engineers). For simulation, [config.toml](./config.toml) overrides `SystemConfig.owner()` (slot `0x33`) to the OPE Safe. **Remove that override once W26 is executed on-chain.**

> [!CAUTION]
> Per plan step **W4**, the OPE batcher and unsafe-block-signer addresses must be independently verified by ≥3 OP Labs engineers before any on-chain use. **Mainnet keys are NEW — do not reuse the Ink Sepolia OPE keys.** The superchain-registry only carries the genesis batcher (`0x500d7Ea63CF2E501dadaA5feeC1FC19FE2Aa72Ac`); confirm the *current* batcher and unsafe block signer on-chain before diffing.

## State Changes

Writes to `SystemConfigProxy` ([`0x62C0a111…E8364`](https://etherscan.io/address/0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364#readProxyContract)):

| Field | Current (on-chain) | New |
|-------|--------------------|-----|
| `batcherHash()` | `TODO` — `cast call 0x62C0a111… "batcherHash()(bytes32)"` | OPE batcher, left-padded to 32 bytes |
| `unsafeBlockSigner()` | `TODO` — `cast call 0x62C0a111… "unsafeBlockSigner()(address)"` | OPE sequencer |

Plus the OPE Safe nonce increments by 1. (The `SystemConfig.owner()` slot-`0x33` change is a **simulation-only override**, not a state change produced by this task — see the note above.)

## Simulation & Signing

```bash
cd src/tasks/eth/060-ink-set-batcher-unsafe-signer
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
# then, to sign:
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "batcherHash()(bytes32)" --rpc-url <MAINNET_RPC>
# Expected: 0x000000000000000000000000<OPE batcher>
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "unsafeBlockSigner()(address)" --rpc-url <MAINNET_RPC>
# Expected: <OPE sequencer>
```

Record the executed tx hash in the migration plan execution log (cutover steps 2 & 3).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprints.
