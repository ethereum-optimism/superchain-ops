# 039-U18-uni

Status: [READY TO SIGN]

## Objective

U18 on Unichain Mainnet.

## Simulation & Signing

### For Signers

```bash
# Change directory to the correct task
cd src/tasks/eth/039-U18-uni

# Command to simulate
just simulate-stack eth 039-U18-uni <foundation|council|chain-governor>

# Command to sign
just sign-stack eth 039-U18-uni <foundation|council|chain-governor>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the correct task
cd src/tasks/eth/039-U18-uni

# Command to approve
SIGNATURES=0x just approve <foundation|council|chain-governor>

# Command to execute
just execute

# Add USE_KEYSTORE=1 to the above if you are using a local keystore instead of a connected Ledger
```
