# THIS IS A TEST TASK THAT DOES NOT USE ANY PRODUCTION ADDRESSES.

[READY TO SIGN]()

```bash
cd src/improvements/tasks/sep/022-nested-test
just simulate TestChildSafeDepth1
just sign TestChildSafeDepth1
# OR
just sign-stack sep 022-nested-test TestChildSafeDepth1
```

```
Data: 0x190179112859ed39df18bb5aaa5e1af40e20b7ed6bbc749825ce64c9ba02de0bb2b58df0342f0e9a443994311f1c87ed6772477fd00ed03724a6d3572c55f607053f
Signer: 0x95E774787A63f145f7B05028a1479bDc9D055f3d
Signature: 3da563967b8c435a36f666ee0efb1c488abbea315948fabf49efb275adc0e913113c3ff231691940a9789590ce1a33c42e406a7d113b02c9333c6925e5f8db5d1b
```

```bash
SIGNATURES=3da563967b8c435a36f666ee0efb1c488abbea315948fabf49efb275adc0e913113c3ff231691940a9789590ce1a33c42e406a7d113b02c9333c6925e5f8db5d1b just approve TestChildSafeDepth1
```

Approval transaction: [0x6e10b71216c75b09ea0267762aa61037922960fa60599796dc57452aa982b13e](https://sepolia.etherscan.io/tx/0x6e10b71216c75b09ea0267762aa61037922960fa60599796dc57452aa982b13e)

```bash
just execute
```

Execution transaction: [0x16222fba83893a20f3ffa7d26a72e6b31906f8ec6540d588208dace01acfbcbe](https://sepolia.etherscan.io/tx/0x16222fba83893a20f3ffa7d26a72e6b31906f8ec6540d588208dace01acfbcbe)