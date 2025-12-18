# 037-rev-share-ink-soneium: RevShare Upgrade and Setup for Ink and Soneium Mainnets

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrade proxies and setup RevShare contracts for Ink and Soneium Mainnets. This task:

1. Deploys all needed contract implementations:
   - FeeVaults
   - FeeSplitter
   - L1Withdrawer (pointing to the FeesDepositor on L1)
   - RevShareCalculator (pointing to the L1Withdrawer and the ChainFeesRecipient)
2. Upgrades the fee vault proxy implementations (SequencerFeeVault, BaseFeeVault, L1FeeVault, OperatorFeeVault) on Ink and Soneium L2s
3. Sets FeeSplitter predeploy to point to the new FeeSplitter implementation and initializes it with the RevShareCalculator address

Target chains:

- Ink Mainnet (chainId: 57073)
- Soneium Mainnet (chainId: 1868)

## Simulation & Signing

Simulation commands for each safe:

```bash
cd src/tasks/eth/037-rev-share-ink-soneium
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile simulate <council|foundation>
```

Signing commands for each safe:

```bash
cd src/tasks/eth/037-rev-share-ink-soneium
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile sign <council|foundation>
```
