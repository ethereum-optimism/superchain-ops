# 058-U18-soneium

Status: [READY TO SIGN]

## Objective

U18 on Soneium Minato Testnet.

## Simulation & Signing

### For Signers

```bash
# Change directory to the correct task
cd src/tasks/sep/058-U18-soneium

# Command to simulate
just simulate-stack sep 058-U18-soneium <council|foundation>

# Command to sign
just sign-stack sep 058-U18-soneium <council|foundation>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the correct task
cd src/tasks/sep/058-U18-soneium

# Command to approve
SIGNATURES=0x just approve <council|foundation>

# Command to execute
just execute

# Add USE_KEYSTORE=1 to the above if you are using a local keystore instead of a connected Ledger
```
