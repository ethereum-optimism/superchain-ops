# 046-worldchain-l2pao-key-handback-over

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x28f74a6314e34f4d94e35ca9194656044d259855b014da943db3ab4cc6a64dcc)

## Objective

Transfer the L2 ProxyAdmin Owner for Worldchain Sepolia to Alchemy-controlled EOA.

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/046-worldchain-l2pao-key-handback-over
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/046-worldchain-l2pao-key-handback-over
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign <council|foundation>
```
