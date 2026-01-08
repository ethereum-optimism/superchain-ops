# 055-U18-uni-sepolia

Status: [READY TO SIGN]

## Objective

U18 on Unichain Sepolia.

## Simulation & Signing

### For Signers

```bash
# Change directory to the correct task
cd src/tasks/sep/055-U18-uni-sepolia

# Command to simulate
just simulate-stack sep 055-U18-uni-sepolia

# Command to sign
just sign-stack sep 055-U18-uni-sepolia
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the correct task
cd src/tasks/sep/055-U18-uni-sepolia

# Command to approve
SIGNATURES=0x just approve

# Command to execute
just execute

# Add USE_KEYSTORE=1 to the above if you are using a local keystore instead of a connected Ledger
# For a quick, non-stacked simulation
SIMULATE_WITHOUT_LEDGER=1 just simulate
```
