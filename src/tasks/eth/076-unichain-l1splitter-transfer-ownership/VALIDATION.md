# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (Unichain SystemConfig owner Safe
13), i.e. two transactions after its current nonce 11 (its SystemConfig owner transfer, then one more Safe transaction), and move only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Unichain SystemConfig owner Safe (`0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1`)
>
> - Domain Hash:  `0xbea15583997db2831ec7dea58be331771c073bea8444c2b48ded663621f2260e`
> - Message Hash: `0x7b35989283e9278a2ca84f573838fa453a22cd8445390afd5e2e270c422ccb08`

Safe transaction hash: `0x7e9f90d993b2842f88266b3ce04550460f8c8b9c28be1537e4c6f7307bcefb9d`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/076-unichain-l1splitter-transfer-ownership
just simulate-stack eth 076-unichain-l1splitter-transfer-ownership
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, the outer
   `execTransaction`, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes), and
   nothing else.
3. The call trace shows one `depositTransaction` on `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` with `_to = 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003` and `_data = transferOwnership(0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b)`, and one `TransactionDeposited` event whose `from` is the alias `0xa356d5D10aA8A842B31530dE71EA86c0760CB2C2`.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the Unichain SystemConfig owner Safe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c420000000000000000000000004300c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the Unichain SystemConfig owner Safe (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003`, `_gasLimit = 150000`, `_data = transferOwnership(0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b)` |

To verify the payload fingerprints:

```bash
cast calldata "transferOwnership(address)" 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
# Expected: 0xf2fde38b0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b
```

The payload, the portal and the L1Splitter address each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1 "nonce()(uint256)" -r $RPC   # 13
cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "owner()(address)" -r https://mainnet.unichain.org          # 0xa356d5D10aA8A842B31530dE71EA86c0760CB2C2
cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "pendingOwner()(address)" -r https://mainnet.unichain.org   # 0x0000000000000000000000000000000000000000
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/076-unichain-l1splitter-transfer-ownership

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (Unichain OptimismPortalProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `ResourceMetering.ResourceParams`: `prevBoughtGas` becomes 150,000 (1 × 150,000) and `prevBlockNum` the simulation block; both are block-dependent. Only this slot of the portal may change.

On L2, once relayed, the L1Splitter's `pendingOwner` (slot `1`) becomes `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`.

#### `0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1` (Unichain SystemConfig owner Safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `13` → **After:** `14`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
L2RPC=https://mainnet.unichain.org

cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "pendingOwner()(address)" -r $L2RPC   # 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "owner()(address)" -r $L2RPC          # 0xa356d5D10aA8A842B31530dE71EA86c0760CB2C2 (unchanged)
```
