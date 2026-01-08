# 053-U18-op-ink-mmz-arena

Status: [DRAFT, NOT READY TO SIGN]

## Objective

U18 on Sepolia networks of OP, Ink, Metal, Mode, Zora, Arena-Z.

## Simulation & Signing

### For Signers

```bash
# Change directory to the correct task
cd src/tasks/sep/053-U18-op-ink-mmz-arena

# Command to simulate
just simulate-stack sep 053-U18-op-ink-mmz-arena <council|foundation>

# Command to sign
just sign-stack sep 053-U18-op-ink-mmz-arena <council|foundation>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the correct task
cd src/tasks/sep/053-U18-op-ink-mmz-arena

# Command to approve
SIGNATURES=0x just --dotenv-path $(pwd)/.env approve <council|foundation>

# Command to execute
just --dotenv-path $(pwd)/.env execute

# Add USE_KEYSTORE=1 to the above if you are using a local keystore instead of a connected Ledger
# For a quick, non-stacked simulation
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <council|foundation>
```