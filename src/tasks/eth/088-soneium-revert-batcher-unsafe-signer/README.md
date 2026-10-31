# 088-soneium-revert-batcher-unsafe-signer

Status: CANCELLED (CONTINGENCY TASK, SIGN AS NEEDED)

> [!WARNING]
> Rollback for [085](../085-soneium-set-batcher-unsafe-signer), executed only if the OP Enterprise
> sequencer or batcher has to be handed back to Sony after the cutover. `CANCELLED` keeps it out of
> the stacked simulation, because it shares FoundationUpgradeSafe nonce 83 with the foundation
> approval of [086](../086-soneium-fee-vault): only one of the two can execute. Execute 086 only once
> the cutover is confirmed; if this rollback executes instead, 086 and every later FoundationUpgradeSafe
> task move up by one nonce and are re-signed. There is no rollback for the proposer
> ([084](../084-soneium-proposer-rotation)).

## Objective

Soneium Mainnet migration rollback: restores Sony's batcher and unsafe block signer on the
**Soneium** (chainId 1868) `SystemConfigProxy` with `setBatcherHash(bytes32)` and
`setUnsafeBlockSigner(address)`, executed by the SystemConfig owner, the
[FoundationUpgradeSafe](../../../addresses.toml#L6) (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`).
SystemConfig ownership stays with the FoundationUpgradeSafe.

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| Soneium | 1868 | [`0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/soneium.toml#L51) | `batcherHash()` | `0x1C7566fE8FAe38a93BDCb1fBF7D746FD08C11545` → `0x6776BE80dBAda6A02B5F2095cF13734ac303B8d1` |
| | | | `unsafeBlockSigner()` | `0x3cDacd9da979ab023a9f2D16C42AFA062CCF33F5` → `0x7c2Bd59ee2a2C7391c9A240132f26071e9546262` |

The restored values are the ones live on-chain before 085.

> [!IMPORTANT]
> Until 085 lands, [config.toml](./config.toml) overrides `SystemConfig.owner()` (slot `0x33`),
> `batcherHash` (slot `0x67`) and `unsafeBlockSigner` to their post-085 values for simulation; the
> overrides are no-ops once 085 has executed.

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe. It is outside the
stack, so it is simulated on its own.

```bash
cd src/tasks/eth/088-soneium-revert-batcher-unsafe-signer

just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate

SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Execution

For facilitators, once the Safe has collected its signatures and the rollback is called. Run the
pre-execution checks in [VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run
without `SIGNATURES`.

```bash
cd src/tasks/eth/088-soneium-revert-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
