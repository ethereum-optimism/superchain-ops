# 049-arena-z-fee-vault-update

Status: DRAFT, NOT READY TO SIGN

## Objective

Updates the fee vault recipient for Arena-Z Mainnet (Chain ID 7897).

The three fee vault proxies are upgraded to pre-deployed implementations that have the new
recipient address baked in as an immutable:

- `SequencerFeeVault` (`0x4200000000000000000000000000000000000011`) → impl `0x6B0660A3be44da5e37A7A9Be4D384a43D2596ea4`
- `BaseFeeVault`      (`0x4200000000000000000000000000000000000019`) → impl `0xD7e148FEc0d8F59a672B3EE3e1e3Ba5C82Bdf015`
- `L1FeeVault`        (`0x420000000000000000000000000000000000001A`) → impl `0xD7e148FEc0d8F59a672B3EE3e1e3Ba5C82Bdf015`

Each upgrade is performed via a `depositTransaction` call through the Arena-Z Mainnet
`OptimismPortal` (`0xB20f99b598E8d888d1887715439851BC68806b22`), sending an L1→L2 upgrade
message to the L2 `ProxyAdmin` (`0x4200000000000000000000000000000000000018`).

## Simulation & Signing

Simulation commands for each safe:
```bash
cd src/tasks/eth/049-arena-z-fee-vault-update
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate council
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate foundation
```

Signing commands for each safe:
```bash
cd src/tasks/eth/049-arena-z-fee-vault-update
just --dotenv-path $(pwd)/.env sign council
just --dotenv-path $(pwd)/.env sign foundation
```
