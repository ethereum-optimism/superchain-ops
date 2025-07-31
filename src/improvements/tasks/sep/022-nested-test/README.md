# THIS IS A TEST TASK THAT DOES NOT USE ANY PRODUCTION ADDRESSES.

Status: [READY TO SIGN]()

```bash
cd src/improvements/tasks/sep/022-nested-test
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

Approval transaction: [](https://sepolia.etherscan.io/tx/)

```bash
just execute
```

Execution transaction: [](https://sepolia.etherscan.io/tx/)
