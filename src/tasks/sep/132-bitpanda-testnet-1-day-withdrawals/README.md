# 132-bitpanda-testnet-1-day-withdrawals

Status: [DRAFT, NOT READY TO SIGN]

**Blocked** on the Bitpanda customer change order acknowledging 1-day withdrawals. Do not sign until it is executed.

## Summary

| | |
|---|---|
| Target date | TBD, early/mid January 2027 (testnet deploy week) |
| Depends on | Bitpanda testnet deployment (January) and the signed customer change order. |
| Sequencing | Independent of the U22 tasks (different root safe). |

| Chain | Chain ID | Change |
|---|---|---|
| Bitpanda testnet | TODO | proof maturity, finality and DelayedWETH delays -> 1 day |

## Objective

Sets 1-day withdrawals on the Bitpanda testnet via `SetReviewPeriodDelays`, from the chain's ProxyAdminOwner: `OptimismPortal2.setProofMaturityDelaySeconds(86400)`, `AnchorStateRegistry.setDisputeGameFinalityDelaySeconds(86400)` and `DelayedWETH.setDelay(86400)`. First activation of 1-day withdrawals anywhere; the stealth mainnet follows one to two weeks later. No staging activation (agreed Nov 17).

## Open items

- [ ] Customer change order signed (blocker).
- [ ] Testnet name, chain ID, L1 (assumed Sepolia), registry listing or `addresses.json`.
- [ ] ProxyAdminOwner address and nonce pin.
- [ ] Contract versions meet the template minimums (OptimismPortal2 >= 6.0.0, ASR >= 5.0.0, DelayedWETH >= 3.0.0).
- [ ] Monitors for 1-day withdrawals live on the chain.
- [ ] Domain/message hashes in VALIDATION.md, calldata breakdown and state changes.

## Simulation & Signing

This is a **single-safe** task, so no child-safe argument is needed.

```bash
cd src/tasks/sep/132-bitpanda-testnet-1-day-withdrawals

just simulate-stack sep 132-bitpanda-testnet-1-day-withdrawals

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 132-bitpanda-testnet-1-day-withdrawals
```

## Validation

See [VALIDATION.md](./VALIDATION.md).
