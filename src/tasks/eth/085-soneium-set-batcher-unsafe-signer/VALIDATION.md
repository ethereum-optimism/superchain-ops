# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe
81), with the SystemConfig owner set to the FoundationUpgradeSafe and move only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x3c82f3579c516c430318584fac1048d44ddbace7866f6977381571cb28a4f0ae`

Safe transaction hash: `0x248dca960b17f5add89b2ed0ce3ad82c45b3200d9987fffe49708439b2580008`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/085-soneium-set-batcher-unsafe-signer
just simulate-stack eth 085-soneium-set-batcher-unsafe-signer
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
3. The call trace shows `setBatcherHash` and `setUnsafeBlockSigner` on `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` with the values in the [Understanding Task Calldata](#understanding-task-calldata) table, and two `ConfigUpdate` events (`updateType` 0 `BATCHER` and 3 `UNSAFE_BLOCK_SIGNER`).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the FoundationUpgradeSafe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024c9b26f610000000000000000000000001c7566fe8fae38a93bdcb1fbf7d746fd08c11545000000000000000000000000000000000000000000000000000000000000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002418d139180000000000000000000000003cdacd9da979ab023a9f2d16c42afa062ccf33f500000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the FoundationUpgradeSafe (selector
`0x174dea71`) containing **2** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (SystemConfigProxy) | `setBatcherHash(bytes32)` | `_batcherHash = 0x1C7566fE8FAe38a93BDCb1fBF7D746FD08C11545` (left-padded) |
| 2 | `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (SystemConfigProxy) | `setUnsafeBlockSigner(address)` | `_unsafeBlockSigner = 0x3cDacd9da979ab023a9f2D16C42AFA062CCF33F5` |

To verify the payload fingerprints:

```bash
cast calldata "setBatcherHash(bytes32)" 0x0000000000000000000000001c7566fe8fae38a93bdcb1fbf7d746fd08c11545
# Expected: 0xc9b26f610000000000000000000000001c7566fe8fae38a93bdcb1fbf7d746fd08c11545

cast calldata "setUnsafeBlockSigner(address)" 0x3cDacd9da979ab023a9f2D16C42AFA062CCF33F5
# Expected: 0x18d139180000000000000000000000003cdacd9da979ab023a9f2d16c42afa062ccf33f5
```

Each payload appears exactly once and the target twice. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 81
cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "owner()(address)" -r $RPC   # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (after the Safe UI transfer)
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/085-soneium-set-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (Soneium SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000067`
  - **Before:** `0x0000000000000000000000006776be80dbada6a02b5f2095cf13734ac303b8d1`
  - **After:**  `0x0000000000000000000000001c7566fe8fae38a93bdcb1fbf7d746fd08c11545`
  - **Summary:** `batcherHash`.
- **Key:** `0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08`
  - **Before:** `0x0000000000000000000000007c2bd59ee2a2c7391c9a240132f26071e9546262`
  - **After:**  `0x0000000000000000000000003cdacd9da979ab023a9f2d16c42afa062ccf33f5`
  - **Summary:** `unsafeBlockSigner` (`keccak256("systemconfig.unsafeblocksigner") - 1`).

The slot `0x33` owner value is a state override standing in for the Safe UI transfer, not a change made by this task.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `81` → **After:** `82`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "batcherHash()(bytes32)" -r $RPC        # 0x0000000000000000000000001c7566fe8fae38a93bdcb1fbf7d746fd08c11545
cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "unsafeBlockSigner()(address)" -r $RPC   # 0x3cDacd9da979ab023a9f2D16C42AFA062CCF33F5
cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "owner()(address)" -r $RPC               # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (unchanged)
```
