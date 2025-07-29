# THIS IS A TEST TASK THAT DOES NOT USE ANY PRODUCTION ADDRESSES.

[READY TO SIGN]()

```bash
cd src/improvements/tasks/sep/023-nested-nested-test
just simulate TestChildSafeDepth1 TestChildSafeDepth2
just sign TestChildSafeDepth1 TestChildSafeDepth2
# OR
just sign-stack sep 023-nested-nested-test TestChildSafeDepth1 TestChildSafeDepth2
```

```
Data: 0x190179112859ed39df18bb5aaa5e1af40e20b7ed6bbc749825ce64c9ba02de0bb2b5260bbdceeede996afe0e219b6b773a19f128949d2175ecda29efd54f6a9049ae
Signer: 0x95E774787A63f145f7B05028a1479bDc9D055f3d
Signature: 328348d896a66c5a8d9528e1375a8de20cbe3f42b939fe0a616a7f65d24ed1302e83d5c8d4f4125ae94f4760882cf4d4a6c4a318c03b7b0fb2088f99b6cee93f1b
```