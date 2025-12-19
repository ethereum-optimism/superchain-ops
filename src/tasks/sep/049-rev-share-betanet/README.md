# 049-rev-share-betanet: RevShare Upgrade and Setup for Betanet

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrade proxies and setup RevShare contracts for the RevShare Betanet chain. This task:

1. Deploys all needed contract implementations:
   - FeeVaults
   - FeeSplitter
   - L1Withdrawer (pointing to the FeesDepositor on L1)
   - RevShareCalculator (pointing to the L1Withdrawer and the ChainFeesRecipient)
2. Upgrades the fee vault proxy implementations (SequencerFeeVault, BaseFeeVault, L1FeeVault, OperatorFeeVault) on the Betanet L2
3. Sets FeeSplitter predeploy to point to the new FeeSplitter implementation and initializes it with the RevShareCalculator address

Target chain:

- revshare-beta-0 (chainId: 420120033)

## Simulation & Signing

Simulation commands for each safe:

```bash
# For stacked simulation (recommended for validation):
just simulate-stack sep 049-rev-share-betanet <council|foundation>

# For individual simulation:
cd src/tasks/sep/049-rev-share-betanet
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile simulate <council|foundation>
```

Signing commands for each safe:

```bash
cd src/tasks/sep/049-rev-share-betanet
just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile sign <council|foundation>
```
