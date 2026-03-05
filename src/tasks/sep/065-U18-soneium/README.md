# 065-U18-soneium

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xd0d7c73a235a3dbe852f29eb79667bb67bd9c388889503fce0366ddb50b6a2d3)

## Objective

U18 on Soneium Minato Testnet.

## Simulation & Signing

### For Signers

```bash
# Change directory to the correct task
cd src/tasks/sep/065-U18-soneium

# Command to simulate
just simulate-stack sep 065-U18-soneium <council|foundation>

# Command to sign
just sign-stack sep 065-U18-soneium <council|foundation>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the correct task
cd src/tasks/sep/065-U18-soneium

# Command to approve
SIGNATURES=0x just approve <council|foundation>

# Command to execute
just execute

# Add USE_KEYSTORE=1 to the above if you are using a local keystore instead of a connected Ledger
```
