# 015-set-game-implementation-arena-z-swell

Status: [EXECUTED](https://etherscan.io/tx/0x7d2a05b891c480b91a472a135e867e6a94ba196439e47e76cc08954401a9b224)

## Objective

This task resets the FaultDisputeGame implementation on the DisputeGameFactory contract to the zero address for Arena-Z and Swell Mainnet

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/015-set-game-implementation-arena-z-swell

SIMULATE_WITHOUT_LEDGER=1 just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../nested.just \
   simulate \
   council 0

SIMULATE_WITHOUT_LEDGER=1 just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../nested.just \
   simulate \
   foundation 0

```
