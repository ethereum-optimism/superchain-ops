# 064 permissioned-betanet-rev-share: RevShare Upgrade and Setup for Betanet

Status: [READY TO SIGN]

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
just simulate-stack sep 064-permissioned-betanet-rev-share

# For individual simulation:
cd src/tasks/sep/064-permissioned-betanet-rev-share
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 064-U18-rev-share-betanet-v2
SIGNATURES=0x just execute
```
