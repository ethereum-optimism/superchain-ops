# 085-op-mainnet-set-unsafe-signer

Status: [DRAFT, NOT READY TO SIGN]

## Objective

OP Mainnet OP Enterprise key rotation, part 2: registers the OP Enterprise unsafe block signer on the **OP Mainnet** (chainId 10) `SystemConfigProxy` with `setUnsafeBlockSigner(address)`, executed by
the SystemConfig owner, the [FoundationUpgradeSafe](../../../addresses.toml#L6) (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| OP Mainnet | 10 | [`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L51) | `unsafeBlockSigner()` | `0xAAAA45d9549EDA09E70937013520214382Ffc4A2` → `0xdead00000000000000000000000000002002dead` |

The batcher was rotated in eth/079; this task only moves the unsafe block signer. A standalone `just simulate` (without eth/079 applied) would also rotate the batcher, so sign only from `just simulate-stack`.

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/eth/085-op-mainnet-set-unsafe-signer

just simulate-stack eth 085-op-mainnet-set-unsafe-signer

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 085-op-mainnet-set-unsafe-signer
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/eth/085-op-mainnet-set-unsafe-signer

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
