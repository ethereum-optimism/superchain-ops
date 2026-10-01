# 081-soneium-set-batcher-unsafe-signer

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Soneium Mainnet migration, cutover steps 2 and 3: registers the OP Enterprise batcher and unsafe
block signer on the **Soneium** (chainId 1868) `SystemConfigProxy` with `setBatcherHash(bytes32)` and
`setUnsafeBlockSigner(address)`, executed by the SystemConfig owner, the
[FoundationUpgradeSafe](../../../addresses.toml#L6) (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| Soneium | 1868 | [`0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/soneium.toml#L51) | `batcherHash()` | `0x6776BE80dBAda6A02B5F2095cF13734ac303B8d1` → `0xdead000000000000000000000000000000001001` |
| | | | `unsafeBlockSigner()` | `0x7c2Bd59ee2a2C7391c9A240132f26071e9546262` → `0xdead000000000000000000000000000000001002` |

> [!WARNING]
> This task contains **placeholder** values, so it stays DRAFT and its hashes and calldata are
> not signable. Replace them in [config.toml](./config.toml), re-run the simulation and
> regenerate [VALIDATION.md](./VALIDATION.md):
>   - `0xdead000000000000000000000000000000001001`: OPE batcher
>   - `0xdead000000000000000000000000000000001002`: OPE sequencer (unsafe block signer)

> [!IMPORTANT]
> The FoundationUpgradeSafe only becomes the SystemConfig owner with `075-soneium-system-config-owner-to-fus`. Until that executes, [config.toml](./config.toml) overrides `SystemConfig.owner()` (slot `0x33`) to the FoundationUpgradeSafe for simulation; the override is a no-op once it has landed.

> [!IMPORTANT]
> Soneium Mainnet cuts over after U21 Mainnet. If the U21 tasks land before this one in the eth stack, the nonce pins, hashes and (if U21 redeploys the type-5 game) the impl must be regenerated, and the task may need renumbering after the U21 tasks.

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/eth/081-soneium-set-batcher-unsafe-signer

just simulate-stack eth 081-soneium-set-batcher-unsafe-signer

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 081-soneium-set-batcher-unsafe-signer
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/eth/081-soneium-set-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
