# 071-chain-governor-rotation

Status: READY TO SIGN

## Objective

This task rotates a signer on the Sepolia ChainGovernorSafe (`0x5c86c4499eeDCCe74618006F376110dc0F8eb84a`):
- Removes: `0x72e828fdB48Cac259CB60d03222774fBD7e5522C` (Pete)
- Adds: `0xC703d73DB3804662B81b260056d8518Ab54e984E` (Eli)

## Simulation & Signing

Simulation commands:
```bash
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack sep 071-chain-governor-rotation
```

Signing commands:
```bash
just sign-stack sep 071-chain-governor-rotation
```
