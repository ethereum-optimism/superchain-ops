# 062 betanet-rev-share: RevShare Upgrade and Setup for Betanet

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x22e77d96df50587a792ea60f17afe6f8be485ac4538b351c65e450a2a2e5d57a)

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
just simulate-stack sep 062-betanet-rev-share-v2

# For individual simulation:
cd src/tasks/sep/062-betanet-rev-share-v2
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile ../../../justfile simulate

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 062-U18-rev-share-betanet-v2
SIGNATURES=0x just execute
```
