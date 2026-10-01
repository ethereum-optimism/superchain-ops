# 077-unichain-set-batcher-unsafe-signer

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Unichain Mainnet migration, cutover steps 2 and 3: registers the OP Enterprise batcher and unsafe
block signer on the **Unichain** (chainId 130) `SystemConfigProxy` with `setBatcherHash(bytes32)` and
`setUnsafeBlockSigner(address)`, executed by the SystemConfig owner, the
[FoundationUpgradeSafe](../../../addresses.toml#L6) (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| Unichain | 130 | [`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/unichain.toml#L51) | `batcherHash()` | `0x2F60A5184c63ca94f82a27100643DbAbe4F3f7Fd` → `0xdead000000000000000000000000000000000001` |
| | | | `unsafeBlockSigner()` | `0x833C6f278474A78658af91aE8edC926FE33a230e` → `0xdead000000000000000000000000000000000002` |

> [!WARNING]
> This task contains **placeholder** values, so it stays DRAFT and its hashes and calldata are
> not signable. Replace them in [config.toml](./config.toml), re-run the simulation and
> regenerate [VALIDATION.md](./VALIDATION.md):
>   - `0xdead000000000000000000000000000000000001`: OPE batcher
>   - `0xdead000000000000000000000000000000000002`: OPE sequencer (unsafe block signer)

> [!IMPORTANT]
> The FoundationUpgradeSafe only becomes the SystemConfig owner with `074-unichain-system-config-owner-to-fus`. Until that executes, [config.toml](./config.toml) overrides `SystemConfig.owner()` (slot `0x33`) to the FoundationUpgradeSafe for simulation; the override is a no-op once eth/074 has landed.

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/eth/077-unichain-set-batcher-unsafe-signer

just simulate-stack eth 077-unichain-set-batcher-unsafe-signer

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 077-unichain-set-batcher-unsafe-signer
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/eth/077-unichain-set-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
