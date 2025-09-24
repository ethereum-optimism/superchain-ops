# THIS IS A TEST TASK THAT DOES NOT USE ANY PRODUCTION ADDRESSES.

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xa70795a463494c616c8672f0c5fb1c336a8a8b3c08764c61bab593320d71f067)

```bash
cd src/tasks/sep/022-nested-test
just simulate TestChildSafeDepth1
just sign TestChildSafeDepth1
# OR
just sign-stack sep 022-nested-test TestChildSafeDepth1
```

```
# Add Signature output
```

```bash
SIGNATURES= just approve TestChildSafeDepth1
```

Approval transaction: [0x67f424883508f17d5adfc632d97af350e9174bbc20041f48ef1faedfbdf4ae79](https://sepolia.etherscan.io/tx/0x67f424883508f17d5adfc632d97af350e9174bbc20041f48ef1faedfbdf4ae79)

```bash
just execute
```

Execution transaction: [0xa70795a463494c616c8672f0c5fb1c336a8a8b3c08764c61bab593320d71f067](https://sepolia.etherscan.io/tx/0xa70795a463494c616c8672f0c5fb1c336a8a8b3c08764c61bab593320d71f067)
