# 112-op-sepolia-set-batcher

Status: [READY TO SIGN]

## Objective

OP Sepolia OP Enterprise key rotation, part 1: registers the OP Enterprise batcher on the **OP Sepolia** (chainId 11155420) `SystemConfigProxy` with `setBatcherHash(bytes32)`, executed by
the SystemConfig owner, the [FoundationUpgradeSafe](../../../addresses.toml#L18) (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| OP Sepolia | 11155420 | [`0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L52) | `batcherHash()` | `0x8F23BB38F531600e5d8FDDaAEC41F13FaB46E98c` → `0x64EDa4F93314ECd619bd4f79D8d1F8112A4E6e16` |

The unsafe block signer is unchanged here and rotated in sep/114.

The batcher public key is the OP Enterprise signer config: [`op-signer` manifest](https://github.com/ethereum-optimism/k8s-netchef-prod/blob/e296ff03b303882fc764b658c8c1f18cbec7c67e/manifests/op-sepolia-0/tn-op-sepolia-0-op-signer/tn-op-sepolia-0-op-signer.yaml#L51-L54).


## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/sep/112-op-sepolia-set-batcher

just simulate-stack sep 112-op-sepolia-set-batcher

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 112-op-sepolia-set-batcher
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` without `SIGNATURES` will revert at the Safe.

```bash
cd src/tasks/sep/112-op-sepolia-set-batcher

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
