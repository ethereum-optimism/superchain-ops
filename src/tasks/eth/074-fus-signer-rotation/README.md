# 074-fus-signer-rotation

Status: [READY TO SIGN]

## Objective

Rotates one owner of the [FoundationUpgradeSafe](../../../addresses.toml#L6)
(`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`) with a single `swapOwner` call:

| | Address |
|---|---|
| Owner removed | `0x7F1D4FE689B73B628285454667B93cfd09409f27` |
| Owner added | `0xa564C83958f7F9fA5a255a540EF5e49445873104` |

The threshold (5) and the owner count (7) are unchanged. The same rotation is applied to the
FoundationOperationsSafe in [075-fos-signer-rotation](../075-fos-signer-rotation/README.md).

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/eth/074-fus-signer-rotation

just simulate-stack eth 074-fus-signer-rotation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 074-fus-signer-rotation
```

## Execution

For facilitators, once the FoundationUpgradeSafe has collected its signatures. Run the pre-execution checks
in [VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/eth/074-fus-signer-rotation

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata
breakdown and the expected state changes.
