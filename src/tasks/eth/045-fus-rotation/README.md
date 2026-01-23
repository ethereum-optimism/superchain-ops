# 045-fus-rotation

Status: READY TO SIGN

## Objective

This task rotates a signer on the FoundationUpgradeSafe:
- Removes: `0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02`
- Adds: `0xc222ab08333109243B1f4E2a80e3D0A190714AB5`

## Simulation & Signing

Simulation commands:
```bash
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack eth 045-fus-rotation
```

Signing commands:
```bash
just sign-stack eth 045-fus-rotation
```
