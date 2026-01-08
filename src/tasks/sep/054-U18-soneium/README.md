# 054-U18-soneium-minato

Status: [READY TO SIGN]

## Objective

U18 on Soneium Minato Testnet.

## Simulation & Signing

### For Signers

```bash
# Change directory to the correct task
cd src/tasks/sep/054-U18-soneium-minato

# Command to simulate
just simulate-stack sep 054-U18-soneium-minato <council|foundation>

# Command to sign
just sign-stack sep 054-U18-soneium-minato <council|foundation>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the correct task
cd src/tasks/sep/054-U18-soneium-minato

# Command to approve
SIGNATURES=0x just --dotenv-path $(pwd)/.env approve <council|foundation>

# Command to execute
just --dotenv-path $(pwd)/.env execute

# Add USE_KEYSTORE=1 to the above if you are using a local keystore instead of a connected Ledger
# For a quick, non-stacked simulation
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```
