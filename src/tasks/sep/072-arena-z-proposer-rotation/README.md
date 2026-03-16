# 072-arena-z-proposer-rotation

Status: DRAFT

## Objective

Rotate the proposer key for Arena-Z testnet (chain ID 9899) on the Sepolia DisputeGameFactory.

The PermissionedDisputeGame (PDG) implementation remains unchanged (`0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`),
but the `gameArgs` are updated to include the new AltLayer proposer address:
- Previous proposer: `0xc97ffcb0953e60995b5d06755ded41b78a3c8b48`
- New proposer: `0x5D7481c68Eb61da46b2F4eF81B9FD988d97527E0`

The FDG remains zeroed (permissioned chain, no permissionless dispute game).

## Simulation & Signing

```bash
cd src/tasks/sep/072-arena-z-proposer-rotation

SIMULATE_WITHOUT_LEDGER=1 just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../justfile \
   simulate \
   council

SIMULATE_WITHOUT_LEDGER=1 just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../justfile \
   simulate \
   foundation
```
