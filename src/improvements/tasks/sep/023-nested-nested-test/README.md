# THIS IS A TEST TASK THAT DOES NOT USE ANY PRODUCTION ADDRESSES.

[READY TO SIGN]()

```bash
cd src/improvements/tasks/sep/023-nested-nested-test
just simulate TestChildSafeDepth1 TestChildSafeDepth2
just sign TestChildSafeDepth1 TestChildSafeDepth2
# OR
just sign-stack sep 023-nested-nested-test TestChildSafeDepth1 TestChildSafeDepth2
```
