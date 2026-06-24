# 055-fus-rotation-1

Status: [READY TO SIGN]()

## Objective

This task removes 1 FoundationUpgradeSafe owner (`0xBF93D4d727F7Ba1F753E1124C3e532dCb04Ea2c8`) and replaces it with a new owner (`0x7F1D4FE689B73B628285454667B93cfd09409f27`). The threshold (5) and owner count (7) are unchanged.

This is task 1 of 4 in a signer rotation that is intentionally split into single-owner swaps to limit blast radius. The 4 tasks are sequenced so that each newly added owner is required to sign a later task, operationally verifying the new key:

1. `055-fus-rotation-1` (FUS) — adds `0x7F1D4FE689B73B628285454667B93cfd09409f27`.
2. [`056-fus-rotation-2`](../056-fus-rotation-2) (FUS) — adds `0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639`; `0x7F1D4FE689B73B628285454667B93cfd09409f27` MUST sign.
3. [`057-fos-rotation-1`](../057-fos-rotation-1) (FOS) — adds `0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639`.
4. [`058-fos-rotation-2`](../058-fos-rotation-2) (FOS) — adds `0x7F1D4FE689B73B628285454667B93cfd09409f27`; `0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639` MUST sign.

## Simulation

To simulate this task in the context of the full task stack:

```bash
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack eth 055-fus-rotation-1
```

## Signing

```bash
cd src
just sign-stack eth 055-fus-rotation-1
```
