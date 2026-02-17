# 070-fos-rotation

Status: READY TO SIGN

## Objective

This task rotates a signer on the Sepolia FoundationOperationsSafe (`0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`):
- Removes: `0x72e828fdB48Cac259CB60d03222774fBD7e5522C` (Pete)
- Adds: `0xC703d73DB3804662B81b260056d8518Ab54e984E` (Eli)

## Simulation & Signing

Simulation commands:
```bash
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack sep 070-fos-rotation
```

Signing commands:
```bash
just sign-stack sep 070-fos-rotation
```
