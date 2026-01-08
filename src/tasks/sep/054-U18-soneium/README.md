# 054-U18-soneium-minato

Status: [DRAFT]

## Objective

U18 on Soneium Minato Testnet.

## Simulation & Signing

```bash
cd src/tasks/sep/054-U18-soneium-minato

# Command to Simulate
just simulate-stack sep 054-U18-soneium-minato

# Command to Sign
USE_KEYSTORE=1 just sign-stack sep 054-U18-soneium-minato

# Command to Execute
USE_KEYSTORE=1 SIGNATURES=0x just execute
```