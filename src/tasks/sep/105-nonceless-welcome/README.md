# THIS IS A TEST TASK THAT DOES NOT USE ANY PRODUCTION ADDRESSES.

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x83638b83e85c655deb12064891144ed4c3cb88772bd5bbf6da87c889242df59a)

First nonceless (hash-once) task. The root safe is a freshly deployed Safe
v1.5.0 with a single signer and the UnorderedExecutionModule enabled. No nonce
is pinned: signers sign the safe transaction hash computed with the hash-once
value (derived from `hashOnceInput`) in the nonce slot, and execution goes
through the module.

```bash
cd src/tasks/sep/105-nonceless-welcome
just simulate
just sign
```
