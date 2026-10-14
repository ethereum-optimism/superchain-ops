# 113-op-sepolia-set-batcher-rollback

Status: [DRAFT, NOT READY TO SIGN]

## Objective

OP Sepolia OP Enterprise key rotation, **rollback of sep/112**: restores the legacy batcher on the
**OP Sepolia** (chainId 11155420) `SystemConfigProxy` with `setBatcherHash(bytes32)`, executed by
the SystemConfig owner, the [FoundationUpgradeSafe](../../../addresses.toml#L18) (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| OP Sepolia | 11155420 | [`0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L52) | `batcherHash()` | `0x64EDa4F93314ECd619bd4f79D8d1F8112A4E6e16` → `0x8F23BB38F531600e5d8FDDaAEC41F13FaB46E98c` |

This is a **contingency task**. It is signed in advance together with sep/112 and executed
**only** if the cutover runbook calls for rollback step **RB3**. sep/112 itself executes at
cutover step **C10**. It deliberately shares task number sep/113 with the proposer rotation
(`113-op-sepolia-proposer-rotation`): it is never merged, and the two compete for the same slot.
The unsafe block signer is unchanged here (rotated separately in sep/114).

## Nonce

This rollback is pinned to FoundationUpgradeSafe nonce **80**, i.e. sep/112 (79) + 1. It only makes
sense after sep/112 has executed, and the simulation overrides `batcherHash` (slot `0x67`) to
the OPE batcher to model that state.

Nonce 80 is also pinned by the proposer rotation (`113-op-sepolia-proposer-rotation`, which approves a hash on the
FoundationUpgradeSafe as an L1PAO child). Only one Safe transaction can ever execute at a given
nonce, so the proposer rotation and this rollback compete for nonce 80:

- **Rollback not needed**: execute the proposer rotation (or any other FoundationUpgradeSafe transaction) at
  nonce 80. That consumes the nonce and permanently invalidates the rollback signatures; nothing
  else needs to be done. Do not execute the proposer rotation until the RB3 rollback window has closed.
- **Rollback needed (RB3)**: execute this rollback at nonce 80. Every later FoundationUpgradeSafe task
  pinned at nonce >= 80 (the proposer rotation, sep/114, sep/116-118 at the time of writing) must then be
  re-simulated and re-signed at nonce + 1.
- **sep/112 never executes**: this rollback is not applicable. Its signatures can never be executed
  usefully at nonce 79, and become invalid once nonce 80 is used.

Until nonce 80 is consumed the collected signatures stay valid, so the facilitator holding them
must not share them outside the cutover.

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/sep/113-op-sepolia-set-batcher-rollback

just --dotenv-path $(pwd)/.env simulate

SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```

## Execution

For facilitators, only on rollback step RB3 and only after sep/112 has executed. Run the
pre-execution checks in [VALIDATION.md](./VALIDATION.md) first. `just execute` without
`SIGNATURES` will revert at the Safe.

```bash
cd src/tasks/sep/113-op-sepolia-set-batcher-rollback

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
