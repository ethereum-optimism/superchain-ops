# 080-migrations-sop-1-proposer-rotation

Status: DRAFT, NOT READY TO SIGN

## Objective

Rotates the proposer for the `migrations-sop-1` (chainId 420120110) PermissionedDisputeGame (PDG, game type 1) on the Sepolia DisputeGameFactory. The PDG implementation contract is unchanged (`0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`); only the `gameArgs` are updated to embed the new OP proposer.

This is Migration Log step **3a** (`DisputeGameFactory.setImplementation`).

- **Previous proposer**: (chain's pre-cutover proposer, from deploy artifacts)
- **New proposer**: `0x31f018d02be7a6e89b8933bd28a05780a6ecf7c8` (OP)
- **Challenger**: `0x55744b685bd143385d118fc1f413d2b93758602c` (OP)
- **DisputeGameFactoryProxy**: `0xD22e520F9005402a80715A3C2A60a6271B823A23`
- **Signer**: L1 ProxyAdminOwner Safe `0xe934Dc97E347C6aCef74364B50125bb8689c40ff`

The FDG slot (game type 0) is left zeroed — FDG was added in task 076 and is retained as the chain's primary permissionless dispute game.

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/080-migrations-sop-1-proposer-rotation
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
```

Signing commands:
```bash
cd src/tasks/sep/080-migrations-sop-1-proposer-rotation
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```
