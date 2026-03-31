# 048-arena-z-proposer-rotation

Status: [EXECUTED](https://etherscan.io/tx/0xfbcdd181c245cc3e628bb5ba45b5a3d3c07039b0f1a3a5a99b2e9925ff9d5efc)

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

Signing commands for each safe:
```bash
cd src/tasks/eth/048-arena-z-proposer-rotation

just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../justfile \
   sign \
   council

just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../justfile \
   sign \
   foundation
```
