# 014-set-game-implementation-arena-z-swell

Status: [DRAFT]()

## Objective

This task resets the FaultDisputeGame implementation on the DisputeGameFactory contract to the zero address for Arena-Z and Swell Mainnet

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/improvements/tasks/eth/014-set-game-implementation-arena-z-swell

SIMULATE_WITHOUT_LEDGER=1 just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../nested.just \
   simulate \
   foundation 0

```

Signing commands for each safe:
```bash
cd src/improvements/tasks/eth/014-set-game-implementation-arena-z-swell

SIMULATE_WITHOUT_LEDGER=1 just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../nested.just \
   simulate \
   council 0

```
