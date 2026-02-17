# 069-sc-rotation

Status: READY TO SIGN

## Objective

This task rotates a signer on the Sepolia SecurityCouncil Safe (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`):
- Removes: `0x72e828fdB48Cac259CB60d03222774fBD7e5522C` (Pete)
- Adds: `0xC703d73DB3804662B81b260056d8518Ab54e984E` (Eli)

## Simulation & Signing

Simulation commands:
```bash
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack sep 069-sc-rotation
```

Signing commands:
```bash
just sign-stack sep 069-sc-rotation
```
