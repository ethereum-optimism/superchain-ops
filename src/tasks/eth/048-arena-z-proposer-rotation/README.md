# 048-arena-z-proposer-rotation

Status: DRAFT

## Objective

Rotate the proposer key for Arena-Z mainnet (chain ID 7897) on the DisputeGameFactory.

The PermissionedDisputeGame (PDG) implementation remains unchanged (`0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`),
but the `gameArgs` are updated to include the new AltLayer proposer address:
- Previous proposer: `0x5f16e66d8736b689a430564a31c8d887ca357cd8`
- New proposer: `0xDA89371d5C940233B200f9a235bF0Ea8AB9fAe96`

The FDG remains zeroed (permissioned chain, no permissionless dispute game).

## Simulation & Signing

```bash
cd src/tasks/eth/048-arena-z-proposer-rotation

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
