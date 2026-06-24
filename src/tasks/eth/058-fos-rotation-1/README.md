# 058-fos-rotation-1

Status: [READY TO SIGN]()

## Objective

This task removes 1 FoundationOperationsSafe owner (`0x6419F81580343DF023E68715C6e269aFb00a2cc7`) and replaces it with a new owner (`0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639`). The threshold (5) and owner count (7) are unchanged.

This is task 3 of 4 in a signer rotation split into single-owner swaps (see [`056-fus-rotation-1`](../056-fus-rotation-1) for the full sequence). The Foundation Operations Safe is not affected by the pending U19 tasks.

This task adds `0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639` to the Foundation Operations Safe. That new owner is then required to sign [`059-fos-rotation-2`](../059-fos-rotation-2), which operationally verifies the new key.

## Simulation

To simulate this task in the context of the full task stack:

```bash
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack eth 058-fos-rotation-1
```

## Signing

```bash
cd src
just sign-stack eth 058-fos-rotation-1
```
