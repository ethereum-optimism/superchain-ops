# 053-rev-share-ink-soneium: RevShare Upgrade and Setup for Ink Sepolia and Soneium Minato

Status: [READY TO SIGN]

## Objective

Upgrade proxies and setup RevShare contracts for Ink Sepolia and Soneium Testnet Minato. This task:

1. Deploys all needed contract implementations:
   - FeeVaults
   - FeeSplitter
   - L1Withdrawer (pointing to the FeesDepositor on L1)
   - RevShareCalculator (pointing to the L1Withdrawer and the ChainFeesRecipient)
2. Upgrades the fee vault proxy implementations (SequencerFeeVault, BaseFeeVault, L1FeeVault, OperatorFeeVault) on Ink Sepolia and Soneium Minato L2s
3. Sets FeeSplitter predeploy to point to the new FeeSplitter implementation and initializes it with the RevShareCalculator address

Target chains:

- Ink Sepolia (chainId: 763373)
- Soneium Testnet Minato (chainId: 1946)

## Simulation & Signing

Simulation commands for each safe:

```bash
# For stacked simulation (recommended for validation):
just simulate-stack sep 053-rev-share-ink-soneium <council|foundation>

# For individual simulation:
cd src/tasks/sep/053-rev-share-ink-soneium
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile simulate <council|foundation>
```

Signing commands for each safe:

```bash
cd src/tasks/sep/053-rev-share-ink-soneium
just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile sign <council|foundation>
```
