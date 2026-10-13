# 075-fos-signer-rotation

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Rotates one owner of the [FoundationOperationsSafe](../../../addresses.toml#L9)
(`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`) with a single `swapOwner` call:

| | Address |
|---|---|
| Owner removed | `0x7F1D4FE689B73B628285454667B93cfd09409f27` |
| Owner added | `0xa564C83958f7F9fA5a255a540EF5e49445873104` |

The threshold (5) and the owner count (7) are unchanged. The same rotation is applied to the
FoundationUpgradeSafe in [074-fus-signer-rotation](../074-fus-signer-rotation/README.md).

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationOperationsSafe.

```bash
cd src/tasks/eth/075-fos-signer-rotation

just simulate-stack eth 075-fos-signer-rotation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 075-fos-signer-rotation
```

## Execution

For facilitators, once the FoundationOperationsSafe has collected its signatures. Run the pre-execution checks
in [VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/eth/075-fos-signer-rotation

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata
breakdown and the expected state changes.
