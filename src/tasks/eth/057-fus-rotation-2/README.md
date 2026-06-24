# 057-fus-rotation-2

Status: [READY TO SIGN]()

## Objective

This task removes 1 FoundationUpgradeSafe owner (`0x6419F81580343DF023E68715C6e269aFb00a2cc7`) and replaces it with a new owner (`0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639`). The threshold (5) and owner count (7) are unchanged.

This is task 2 of 4 in a signer rotation split into single-owner swaps (see [`056-fus-rotation-1`](../056-fus-rotation-1) for the full sequence). It executes after [`056-fus-rotation-1`](../056-fus-rotation-1).

> [!IMPORTANT]
>
> Owner `0x7F1D4FE689B73B628285454667B93cfd09409f27` (added to the Foundation Upgrade Safe in [`056-fus-rotation-1`](../056-fus-rotation-1)) **MUST be one of the signers for this task**, alongside 4 other current owners to reach the threshold of 5. This produces a real Safe signature from the new key, operationally verifying it.

## Simulation

To simulate this task in the context of the full task stack:

```bash
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack eth 057-fus-rotation-2
```

## Signing

```bash
cd src
just sign-stack eth 057-fus-rotation-2
```
