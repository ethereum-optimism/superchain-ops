# 056-U18-uni

Status: [READY TO SIGN]

## Objective

U18 on Unichain Sepolia.

## Simulation & Signing

### For Signers

```bash
# Change directory to the correct task
cd src/tasks/sep/056-U18-uni

# Command to simulate
just simulate-stack sep 056-U18-uni

# Command to sign
just sign-stack sep 056-U18-uni
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the correct task
cd src/tasks/sep/056-U18-uni

# Command to approve
SIGNATURES=0x just approve

# Command to execute
just execute

# Add USE_KEYSTORE=1 to the above if you are using a local keystore instead of a connected Ledger
```
