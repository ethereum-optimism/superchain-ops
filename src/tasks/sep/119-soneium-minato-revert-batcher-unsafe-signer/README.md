# 119-soneium-minato-revert-batcher-unsafe-signer

Status: CANCELLED (CONTINGENCY TASK, SIGN AS NEEDED)

> [!WARNING]
> Rollback for [117](../117-soneium-minato-set-batcher-unsafe-signer), executed only if the OP Enterprise
> sequencer or batcher has to be handed back to Sony after the cutover. `CANCELLED` keeps it out of
> the stacked simulation, because it shares FoundationUpgradeSafe nonce 84 with the foundation
> approval of [118](../118-soneium-minato-fee-vault): only one of the two can execute. Execute 118 only once
> the cutover is confirmed; if this rollback executes instead, 118 and every later FoundationUpgradeSafe
> task move up by one nonce and are re-signed. There is no rollback for the proposer
> ([116](../116-soneium-minato-proposer-rotation)).

## Objective

Soneium Minato migration rollback: restores Sony's batcher and unsafe block signer on the
**Soneium Minato** (chainId 1946) `SystemConfigProxy` with `setBatcherHash(bytes32)` and
`setUnsafeBlockSigner(address)`, executed by the SystemConfig owner, the
[FoundationUpgradeSafe](../../../addresses.toml#L18) (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`).
SystemConfig ownership stays with the FoundationUpgradeSafe.

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| Soneium Minato | 1946 | [`0x4Ca9608Fef202216bc21D543798ec854539bAAd3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/soneium-minato.toml#L52) | `batcherHash()` | `0x2fE55AA59D58e7c3cb333c652E0FDD9b6D4f3541` → `0xF0AB0441c8f4B89b561aE685B98c6aD5175e0CAB` |
| | | | `unsafeBlockSigner()` | `0xA657d31425BC40068032Ec4433D781099Ed9EE3F` → `0x55930859CD7003F32A2ba171297408476532E535` |

The restored values are the ones live on-chain before 117.

> [!IMPORTANT]
> Until 117 lands, [config.toml](./config.toml) overrides `SystemConfig.owner()` (slot `0x33`),
> `batcherHash` (slot `0x67`) and `unsafeBlockSigner` to their post-117 values for simulation; the
> overrides are no-ops once 117 has executed.

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe. It is outside the
stack, so it is simulated on its own.

```bash
cd src/tasks/sep/119-soneium-minato-revert-batcher-unsafe-signer

just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate

SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Execution

For facilitators, once the Safe has collected its signatures and the rollback is called. Run the
pre-execution checks in [VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run
without `SIGNATURES`.

```bash
cd src/tasks/sep/119-soneium-minato-revert-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
