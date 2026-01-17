# 040-U18-op-ink-mmz-arena-swell

Status: [READY TO SIGN]

## Objective

U18 on Mainnet networks of OP, Ink, Metal, Mode, Zora, Arena-Z, Swell.

## Simulation & Signing

### For Signers

```bash
# Change directory to the correct task
cd src/tasks/eth/040-U18-op-ink-mmz-arena-swell

# Command to simulate
just simulate-stack eth 040-U18-op-ink-mmz-arena-swell <council|foundation>

# Command to sign
just sign-stack eth 040-U18-op-ink-mmz-arena-swell <council|foundation>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the correct task
cd src/tasks/eth/040-U18-op-ink-mmz-arena-swell

# Command to approve
SIGNATURES=0x just approve <council|foundation>

# Command to execute
just execute

# Add USE_KEYSTORE=1 to the above if you are using a local keystore instead of a connected Ledger
```
