# THIS IS A TEST TASK THAT DOES NOT USE ANY PRODUCTION ADDRESSES.

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xa7b1a151dabe1ed6dd6e773aada9de6587a2f3604015758238bc2eed30ceda4b)

First NESTED nonceless (hash-once) task. The root safe
(0xf6475613C0Fa02c43eA6e6e296D3e424c39AE49d) is owned by the child safe from
task 105 (0x44A4f8364df6a38DD64DCB59A282f0106e292f2e); both are Safe v1.5.0
with the UnorderedExecutionModule enabled. No nonces pinned at either level.

Flow that was run:
- child approval executed through the module
  ([tx](https://sepolia.etherscan.io/tx/0x2f10df1abbc166001e9f6a27b785add2bdffa49a55d29796f282f0a718d7bbae)):
  the child safe delegatecalls Multicall3 to approveHash the root's hash-once
  transaction hash — the child's own nonce is untouched.
- root execution through the module with the child's prevalidated approval
  ([tx](https://sepolia.etherscan.io/tx/0xa7b1a151dabe1ed6dd6e773aada9de6587a2f3604015758238bc2eed30ceda4b)) —
  the root's nonce is untouched.

```bash
cd src/tasks/sep/106-nonceless-nested-welcome
just simulate
just sign foundation # or the relevant child safe
```
