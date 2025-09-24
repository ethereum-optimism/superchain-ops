# THIS IS A TEST TASK THAT DOES NOT USE ANY PRODUCTION ADDRESSES.

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x3a4d424bae48ab219908a73bc62f3c391a42b0cba248478c6f0c5055ea293ef7)

```bash
cd src/tasks/sep/023-nested-nested-test
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

Approval transaction: [0xe09de09b095de95e2017bc7595f17370ee7a7739720e1a6bab9b56abb1782333](https://sepolia.etherscan.io/tx/0xe09de09b095de95e2017bc7595f17370ee7a7739720e1a6bab9b56abb1782333)

```bash
just execute
```

Execution transaction: [0x3a4d424bae48ab219908a73bc62f3c391a42b0cba248478c6f0c5055ea293ef7](https://sepolia.etherscan.io/tx/0x3a4d424bae48ab219908a73bc62f3c391a42b0cba248478c6f0c5055ea293ef7)
