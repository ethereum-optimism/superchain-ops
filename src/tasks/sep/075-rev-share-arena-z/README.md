# 075-rev-share-arena-z: RevShare Upgrade and Setup for arena-z-testnet

Status: [DRAFT]

## Objective

Upgrade proxies and setup RevShare contracts for arena-z-testnet. This task:

1. Deploys all needed contract implementations:
   - FeeVaults
   - FeeSplitter
   - L1Withdrawer (pointing to the FeesDepositor on L1)
   - RevShareCalculator (pointing to the L1Withdrawer and the ChainFeesRecipient)
2. Upgrades the fee vault proxy implementations (SequencerFeeVault, BaseFeeVault, L1FeeVault, OperatorFeeVault) on arena-z-testnet L2
3. Sets FeeSplitter predeploy to point to the new FeeSplitter implementation and initializes it with the RevShareCalculator address

Target chain:

- arena-z-testnet (chainId: 9899)

## Simulation & Signing

> **Note:** This task depends on prior tasks in the Sepolia stack. The hashes in VALIDATION.md
> were generated using `simulate-stack` which simulates all tasks in sequence. Running `simulate` individually
> may show different hashes because it doesn't account for nonce increments from prior tasks.

Simulation commands for each safe:

```bash
# For stacked simulation (recommended for validation):
just simulate-stack sep 075-rev-share-arena-z <council|foundation>

# For individual simulation:
cd src/tasks/sep/075-rev-share-arena-z
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile simulate <council|foundation>
```

Signing commands for each safe:

```bash
cd src/tasks/sep/075-rev-share-arena-z
just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile sign <council|foundation>
```
