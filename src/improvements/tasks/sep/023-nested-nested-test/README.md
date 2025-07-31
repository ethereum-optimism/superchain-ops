# THIS IS A TEST TASK THAT DOES NOT USE ANY PRODUCTION ADDRESSES.

[READY TO SIGN](https://sepolia.etherscan.io/tx/)

```bash
cd src/improvements/tasks/sep/023-nested-nested-test
just simulate TestChildSafeDepth1 TestChildSafeDepth2
just sign TestChildSafeDepth1 TestChildSafeDepth2
# OR
just sign-stack sep 023-nested-nested-test TestChildSafeDepth1 TestChildSafeDepth2
```


```
just approve TestChildSafeDepth1 TestChildSafeDepth2
```

Approval transaction: [0x51a38ef6988523f8544d6dc2a682b633919760ae9bddf86e3478428e209e925b](https://sepolia.etherscan.io/tx/0x51a38ef6988523f8544d6dc2a682b633919760ae9bddf86e3478428e209e925b)

```
just approve TestChildSafeDepth1
```


```bash
just execute
```

Execution transaction: [](https://sepolia.etherscan.io/tx/)
