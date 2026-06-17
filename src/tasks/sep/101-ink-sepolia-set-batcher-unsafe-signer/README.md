# 101-ink-sepolia-set-batcher-unsafe-signer

Status: DRAFT, NOT READY TO SIGN — simulates successfully (OPE Safe nonce 12; domain/message/safe hashes recorded in [VALIDATION.md](./VALIDATION.md)). Re-run `just simulate` to regenerate the hashes if the OPE Safe nonce advances or the `SystemConfig.owner` override is removed (after Gelato's W26 transfer) before signing.

## Objective

Registers the OP Enterprise (OPE) batcher and unsafe block signer on the **Ink Sepolia** (chainId 763373) `SystemConfig` as part of the **Gelato → OPE rollup-operator migration** (Type A Standard OP Stack takeover). This batches cutover steps **2** (`setBatcherHash`) and **3** (`setUnsafeBlockSigner`) into a single Multicall3 transaction.

Source of truth: _Ink Sepolia Testnet Migration — Engineering Plan_ (§3.3 Addresses; cutover 2026-06-22).

| Field | Current (Gelato) | New (OPE) |
|-------|------------------|-----------|
| `batcherHash()` | `0x00…21e57C21530Bc33F12Ba96C9dDC135488365002F` | `0x00…42c4dBdD6C573b9C2a8657F59EE8E84AE45F2695` |
| `unsafeBlockSigner()` | `0x43ec5732581d3FAE18AbB7CE34a796E111dBD1a0` | `0x900C36E0CcAC26F9F49ECa6bbD748e347531864b` |

- **Target**: `SystemConfigProxy` `0x05C993e60179f28bF649a2Bb5b00b5F4283bD525` (resolved from the superchain-registry).
- **Signer**: OPE Safe `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (2-of-13) — the SystemConfig owner after Gelato's W26 ownership transfer.

> [!IMPORTANT]
> This task assumes the `SystemConfig` owner is the **OPE Safe**. On Ink Sepolia the owner is currently the **Gelato 3/5 Safe** (`0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`); the Gelato → OPE `transferOwnership` is performed **outside this repo** by Gelato (Migration Plan step **W26**, irreversible — OPE receiving address verified by ≥3 OP engineers). For simulation, [config.toml](./config.toml) overrides `SystemConfig.owner()` (slot `0x33`) to the OPE Safe. **Remove that override once W26 is executed on-chain.**

> [!CAUTION]
> Per plan step **W4**, the OPE batcher and unsafe-block-signer addresses must be independently verified by ≥3 OP Labs engineers before any on-chain use.

## State Changes

Writes to `SystemConfigProxy` ([`0x05C993e6…bD525`](https://sepolia.etherscan.io/address/0x05C993e60179f28bF649a2Bb5b00b5F4283bD525#readProxyContract)):

| Field | Current (on-chain) | New |
|-------|--------------------|-----|
| `batcherHash()` | `0x00000000000000000000000021e57c21530bc33f12ba96c9ddc135488365002f` | `0x00000000000000000000000042c4dbdd6c573b9c2a8657f59ee8e84ae45f2695` |
| `unsafeBlockSigner()` | `0x43ec5732581d3FAE18AbB7CE34a796E111dBD1a0` | `0x900C36E0CcAC26F9F49ECa6bbD748e347531864b` |

- **Current values** verified on-chain: `cast call 0x05C993e6…bD525 "batcherHash()(bytes32)"` / `"unsafeBlockSigner()(address)"` on Sepolia.
- **New values**: OPE receiving infrastructure (plan §3.3).

Plus the OPE Safe nonce increments by 1. (The `SystemConfig.owner()` slot-`0x33` change is a **simulation-only override**, not a state change produced by this task — see the note above.)

## Simulation & Signing

```bash
cd src/tasks/sep/101-ink-sepolia-set-batcher-unsafe-signer
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
# then, to sign:
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Post-execution verification

```bash
cast call 0x05C993e60179f28bF649a2Bb5b00b5F4283bD525 "batcherHash()(bytes32)" --rpc-url <SEPOLIA_RPC>
# Expected: 0x00000000000000000000000042c4dbdd6c573b9c2a8657f59ee8e84ae45f2695
cast call 0x05C993e60179f28bF649a2Bb5b00b5F4283bD525 "unsafeBlockSigner()(address)" --rpc-url <SEPOLIA_RPC>
# Expected: 0x900C36E0CcAC26F9F49ECa6bbD748e347531864b
```

Record the executed tx hash in the migration plan execution log (cutover steps 2 & 3).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprints.
