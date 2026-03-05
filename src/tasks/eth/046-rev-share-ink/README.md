# 046-rev-share-ink: RevShare Upgrade and Setup for Ink Mainnet

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Upgrade proxies and setup RevShare contracts for Ink Mainnet. This task:

1. Deploys all needed contract implementations:
   - FeeVaults
   - FeeSplitter
   - L1Withdrawer (pointing to the FeesDepositor on L1)
   - RevShareCalculator (pointing to the L1Withdrawer and the ChainFeesRecipient)
2. Upgrades the fee vault proxy implementations (SequencerFeeVault, BaseFeeVault, L1FeeVault, OperatorFeeVault) on Ink L2
3. Sets FeeSplitter predeploy to point to the new FeeSplitter implementation and initializes it with the RevShareCalculator address

Target chain:

- Ink Mainnet (chainId: 57073)

## Simulation & Signing

Simulation commands for each safe:

```bash
cd src/tasks/eth/046-rev-share-ink
just simulate-stack eth 046-rev-share-ink <council|foundation>
```

Signing commands for each safe:

```bash
cd src/tasks/eth/046-rev-share-ink
just sign-stack eth 046-rev-share-ink <council|foundation>
```
