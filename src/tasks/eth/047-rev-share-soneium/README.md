# 047-rev-share-soneium: RevShare Upgrade and Setup for Soneium Mainnet

Status: [CANCELLED]

## Objective

Upgrade proxies and setup RevShare contracts for Soneium Mainnet. This task:

1. Deploys all needed contract implementations:
   - FeeVaults
   - FeeSplitter
   - L1Withdrawer (pointing to the FeesDepositor on L1)
   - RevShareCalculator (pointing to the L1Withdrawer and the ChainFeesRecipient)
2. Upgrades the fee vault proxy implementations (SequencerFeeVault, BaseFeeVault, L1FeeVault, OperatorFeeVault) on Soneium L2
3. Sets FeeSplitter predeploy to point to the new FeeSplitter implementation and initializes it with the RevShareCalculator address

Target chain:

- Soneium Mainnet (chainId: 1868)

## Simulation & Signing

Simulation commands for each safe:

```bash
cd src/tasks/eth/047-rev-share-soneium
just simulate-stack eth 047-rev-share-soneium <council|foundation>
```

Signing commands for each safe:

```bash
cd src/tasks/eth/047-rev-share-soneium
just sign-stack eth 047-rev-share-soneium <council|foundation>
```
