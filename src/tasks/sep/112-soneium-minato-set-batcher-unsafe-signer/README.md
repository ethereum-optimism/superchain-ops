# 112-soneium-minato-set-batcher-unsafe-signer

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Soneium Minato migration, cutover steps 2 and 3: registers the OP Enterprise batcher and unsafe
block signer on the **Soneium Minato** (chainId 1946) `SystemConfigProxy` with `setBatcherHash(bytes32)` and
`setUnsafeBlockSigner(address)`, executed by the SystemConfig owner, the
[FoundationUpgradeSafe](../../../addresses.toml#L18) (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| Soneium Minato | 1946 | [`0x4Ca9608Fef202216bc21D543798ec854539bAAd3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/soneium-minato.toml#L52) | `batcherHash()` | `0xF0AB0441c8f4B89b561aE685B98c6aD5175e0CAB` → `0xdead000000000000000000000000000000001001` |
| | | | `unsafeBlockSigner()` | `0x55930859CD7003F32A2ba171297408476532E535` → `0xdead000000000000000000000000000000001002` |

> [!IMPORTANT]
> The FoundationUpgradeSafe becomes the SystemConfig owner through a `transferOwnership` the current owner executes from its own Safe, outside this repo. Until that lands, [config.toml](./config.toml) overrides `SystemConfig.owner()` (slot `0x33`) to the FoundationUpgradeSafe for simulation; the override is a no-op once it has landed.

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/sep/112-soneium-minato-set-batcher-unsafe-signer

just simulate-stack sep 112-soneium-minato-set-batcher-unsafe-signer

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 112-soneium-minato-set-batcher-unsafe-signer
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/sep/112-soneium-minato-set-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
