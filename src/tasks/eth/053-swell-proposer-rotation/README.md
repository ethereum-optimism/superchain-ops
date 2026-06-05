# 053-swell-proposer-rotation

Status: DRAFT

## Objective

Rotate the proposer key for Swellchain mainnet (chain ID 1923) on the DisputeGameFactory.

The PermissionedDisputeGame (PDG) implementation remains unchanged (`0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`),
but the `gameArgs` are updated to include the new proposer address:
- Previous proposer: `0xA2Acb8142b64fabda103DA19b0075aBB56d29FbD`
- New proposer: `0xdFe6834AC8B97c2d9Bf9df330E55b51c849111FC`

The challenger is unchanged (`0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`), and the FDG remains
zeroed (permissioned chain, no permissionless dispute game).

## Simulation & Signing

```bash
cd src/tasks/eth/053-swell-proposer-rotation

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
cd src/tasks/eth/053-swell-proposer-rotation

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
