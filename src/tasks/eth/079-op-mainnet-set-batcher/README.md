# 079-op-mainnet-set-batcher

Status: [DRAFT, NOT READY TO SIGN]

## Objective

OP Mainnet OP Enterprise key rotation, part 1: registers the OP Enterprise batcher on the **OP Mainnet** (chainId 10) `SystemConfigProxy` with `setBatcherHash(bytes32)`, executed by
the SystemConfig owner, the [FoundationUpgradeSafe](../../../addresses.toml#L6) (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| OP Mainnet | 10 | [`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L51) | `batcherHash()` | `0x6887246668a3b87F54DeB3b94Ba47a6f63F32985` → `0xdead00000000000000000000000000002001dead` |

The unsafe block signer is unchanged here and rotated in eth/085.

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/eth/079-op-mainnet-set-batcher

just simulate-stack eth 079-op-mainnet-set-batcher

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 079-op-mainnet-set-batcher
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/eth/079-op-mainnet-set-batcher

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
