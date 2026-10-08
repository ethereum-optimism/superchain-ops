# 114-op-sepolia-set-unsafe-signer

Status: [DRAFT, NOT READY TO SIGN]

## Objective

OP Sepolia OP Enterprise key rotation, part 2: registers the OP Enterprise unsafe block signer on the **OP Sepolia** (chainId 11155420) `SystemConfigProxy` with `setUnsafeBlockSigner(address)`, executed by
the SystemConfig owner, the [FoundationUpgradeSafe](../../../addresses.toml#L18) (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| OP Sepolia | 11155420 | [`0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L52) | `unsafeBlockSigner()` | `0x57CACBB0d30b01eb2462e5dC940c161aff3230D3` → `0xdead00000000000000000000000000002002dead` |

The batcher was rotated in sep/112; this task only moves the unsafe block signer. The new signer is a `0xdead…dead` placeholder until the OPE sequencer key is available.

> [!IMPORTANT]
> Like sep/112, this needs the SystemConfig owner transferred from the EOA `0xfd1D2e729aE8eEe2E146c033bf4400fE75284301` to the FoundationUpgradeSafe. Until that lands, [config.toml](./config.toml) overrides `SystemConfig.owner()` (slot `0x33`) for simulation. A standalone `just simulate` (without sep/112 applied) would also rotate the batcher; sign only from `just simulate-stack`.

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/sep/114-op-sepolia-set-unsafe-signer

just simulate-stack sep 114-op-sepolia-set-unsafe-signer

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 114-op-sepolia-set-unsafe-signer
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/sep/114-op-sepolia-set-unsafe-signer

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
