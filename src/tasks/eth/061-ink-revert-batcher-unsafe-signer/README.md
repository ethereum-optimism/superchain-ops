# 061-ink-revert-batcher-unsafe-signer: ROLLBACK — restore Gelato batcher & unsafe block signer

Status: CANCELLED

> [!WARNING]
> **ARMED break-glass rollback — NOT abandoned work.** The `CANCELLED` status is deliberate: `fetch-tasks.sh` skips `EXECUTED`/`CANCELLED`/`APPROVED`, so this removes the task from the active `eth` stacked simulation and CI stops enforcing pinned nonces/hashes. A rollback can fire at any migration stage, so its nonce cannot be sequenced ahead of time — instead this task reads the **live** on-chain FOS nonce at activation (no nonce override; `StateOverrideManager._getNonceOrOverride` → `IGnosisSafe.nonce()`).
>
> **Activation (only if a problem is detected after the [`eth/060`](../060-ink-set-batcher-unsafe-signer) sequencer & batcher rotation and it must be rolled back):**
> 1. Change this `Status:` to `READY TO SIGN` (re-arms the task in the stack).
> 2. If the forward migration already executed, the post-migration state is live on-chain — **remove the three modelling overrides** in [config.toml](./config.toml) (`owner()` slot `0x33` → FOS, `batcherHash` slot `0x67` → OPE, `unsafeBlockSigner` slot → OPE).
> 3. Run `just simulate` — the FOS's live nonce is read automatically.
> 4. Copy the freshly printed Domain/Message/Safe hashes into [VALIDATION.md](./VALIDATION.md), verify, then sign.

## Objective

Restores the **original Gelato** batcher and unsafe block signer on the **Ink mainnet** (chainId 57073) `SystemConfig`, reversing [`eth/060-ink-set-batcher-unsafe-signer`](../060-ink-set-batcher-unsafe-signer) (cutover steps 2 & 3). Batches `setBatcherHash` + `setUnsafeBlockSigner` into a single Multicall3 transaction.

| Field | Post-migration (OPE) | Restore to (Gelato) |
|-------|----------------------|---------------------|
| `batcherHash()` | `0x6db6161fC5662450E801398Bad62dD9921216B98` | `0x500d7Ea63CF2E501dadaA5feeC1FC19FE2Aa72Ac` |
| `unsafeBlockSigner()` | `0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1` | `0x7D056B99AA2021864c42E25B4F8cE3BdEAc9463C` |

- **Target**: `SystemConfigProxy` [`0x62C0a111…E8364`](https://etherscan.io/address/0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364)
- **Signer**: `FoundationOperationsSafe` [`0x9BA6e03D…006b3A`](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A) — the post-migration SystemConfig owner.

> [!CAUTION]
> The restore values are the **pre-migration Gelato** batcher and unsafe block signer, read live on-chain 2026-07-09 (batcher == registry genesis batcher). Re-confirm against the execution log at rollback time.

> [!IMPORTANT]
> This task assumes `SystemConfig.owner()` is the `FoundationOperationsSafe` (post-migration), which retains ownership through this rollback — only the batcher and unsafe block signer are reverted; SystemConfig ownership is **not** handed back to Gelato. [config.toml](./config.toml) overrides slot `0x33` → FOS for standalone simulation; remove that override once the forward migration (the Gelato → FOS ownership transfer + `eth/060`) has executed on-chain.

## State Changes

Writes to `SystemConfigProxy` ([`0x62C0a111…E8364`](https://etherscan.io/address/0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364#readProxyContract)):

- `batcherHash()` reverts `0x00…6db6161f…16B98` (OPE) → `0x00…500d7Ea6…72Ac` (Gelato).
- `unsafeBlockSigner()` reverts `0x7b32…F8E1` (OPE) → `0x7D05…463C` (Gelato).

Plus the FoundationOperationsSafe nonce increments by 1 (the live on-chain value read at activation — **not** pinned, since a rollback can fire at any migration stage). (The slot-`0x33` owner, slot-`0x67` batcherHash and unsafeBlockSigner **pre-state** values are simulation-only overrides modelling the post-migration state — see above.)

## Simulation & Signing

```bash
cd src/tasks/eth/061-ink-revert-batcher-unsafe-signer
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "batcherHash()(bytes32)" --rpc-url mainnet
# Expected: 0x000000000000000000000000500d7ea63cf2e501dadaa5feec1fc19fe2aa72ac
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "unsafeBlockSigner()(address)" --rpc-url mainnet
# Expected: 0x7D056B99AA2021864c42E25B4F8cE3BdEAc9463C
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and calldata fingerprints.
