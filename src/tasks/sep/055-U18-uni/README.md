# 055-U18-uni-sepolia

Status: [DRAFT]

## Objective

U18 on Unichain Sepolia.

## Simulation & Signing

```bash
cd src/tasks/sep/055-U18-uni-sepolia

# Command to Simulate
just simulate-stack sep 055-U18-uni-sepolia

# Command to Sign
USE_KEYSTORE=1 just sign-stack sep 055-U18-uni-sepolia

# Command to Execute
USE_KEYSTORE=1 SIGNATURES=0x just execute
```