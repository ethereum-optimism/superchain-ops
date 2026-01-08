# 053-U18-op-ink-mmz-arena

Status: [DRAFT]

## Objective

U18 on Sepolia networks of OP, Ink, Metal, Mode, Zora, Arena-Z.

## Simulation & Signing

```bash
cd src/tasks/sep/053-U18-op-ink-mmz-arena

# Command to Simulate
just simulate-stack sep 053-U18-op-ink-mmz-arena

# Command to Sign
USE_KEYSTORE=1 just sign-stack sep 053-U18-op-ink-mmz-arena

# Command to Execute
USE_KEYSTORE=1 SIGNATURES=0x just execute
```