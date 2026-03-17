# 073-arena-z-fee-vault-update

Status: [READY TO SIGN]

## Objective

Updates the fee vault recipient for Arena-Z Testnet (Chain ID 9899) on Sepolia.

The three fee vault proxies are upgraded to pre-deployed implementations that have the new
recipient address baked in as an immutable:

- `SequencerFeeVault` (`0x4200000000000000000000000000000000000011`) → impl `0x1A4898C391a34E2C38B38A3D2CA4cEbF1BBA783e`
- `BaseFeeVault`      (`0x4200000000000000000000000000000000000019`) → impl `0x8dCC1BbE83752DDB79df32D56B3f37758bBac7AE`
- `L1FeeVault`        (`0x420000000000000000000000000000000000001A`) → impl `0x8dCC1BbE83752DDB79df32D56B3f37758bBac7AE`

Each upgrade is performed via a `depositTransaction` call through the Arena-Z Sepolia
`OptimismPortal` (`0x90FdCE6eFFF020605462150cdE42257193d1e558`), sending an L1→L2 upgrade
message to the L2 `ProxyAdmin` (`0x4200000000000000000000000000000000000018`).

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/sep/073-arena-z-fee-vault-update
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate council
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate foundation
```

Signing commands for each safe:
```bash
cd src/tasks/sep/073-arena-z-fee-vault-update
just --dotenv-path $(pwd)/.env sign council
just --dotenv-path $(pwd)/.env sign foundation
```
