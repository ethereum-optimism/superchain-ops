# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe 72, i.e. after eth/071 and
eth/072) and move only if that nonce moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xfd63b36ee23c93a36ad8f5251ef45d08b6aa1589dbae41f6264c3f54400436d1`

Safe transaction hash: `0xda0887b52b1506e84ce94310c61e6394f6e90b8336cf4c3706fa1811326ac737`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/073-gas-limit-ink
just simulate-stack eth 073-gas-limit-ink
```

While eth/071 and eth/072 are pending, the stacked simulation executes them first; the hashes
and Tenderly link for this task are the last ones printed.

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the
   [task calldata](#task-calldata) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes),
   and nothing else.
3. The decoded input is a single `setGasLimit` call on
   `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` with `_gasLimit = 30000000`, and the Tenderly
   **Events** tab shows exactly one `ConfigUpdate` with `updateType = 2` (`GAS_LIMIT`).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers: the raw
calldata and its breakdown, the pre-execution checks and execution commands, the expected
state changes and the post-execution checks. Signers only need the two sections above.

### Task Calldata

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e83640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024b40a817c0000000000000000000000000000000000000000000000000000000001c9c38000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the Foundation Upgrade
Safe (selector `0x174dea71`, the first four bytes above) containing **1** call, with
`allowFailure = false` and `value = 0`:

| # | Target | Function | Argument |
|---|---|---|---|
| 1 | `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` (Ink SystemConfigProxy) | `setGasLimit(uint64)` | `_gasLimit = 30000000` (`0x1c9c380`) |

To verify the payload fingerprint:

```bash
cast calldata "setGasLimit(uint64)" 30000000
# Expected: 0xb40a817c0000000000000000000000000000000000000000000000000000000001c9c380
```

The payload selector `b40a817c` and the target each appear exactly once. Every other byte
is standard ABI encoding: offsets, lengths and zero padding. To decode the full calldata and
confirm no additional content is present:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

Before executing, confirm the live state matches the assumptions in
[config.toml](./config.toml):

```bash
RPC=https://ethereum-rpc.publicnode.com

# Nonce must equal the pin (72) once eth/071 and eth/072 have executed; if not, re-simulate and
# regenerate the hashes.
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC

# The Foundation Upgrade Safe must still own the SystemConfig and the gas limit must still
# be the value this task changes.
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "owner()(address)" -r $RPC     # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "gasLimit()(uint64)" -r $RPC   # 60000000
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/073-gas-limit-ink

SIGNATURES=0x... just execute
```

### Task State Changes

Two contracts change.

#### `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` (Ink SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000068`
  - **Before:** `0x00000000000000000000000000000000000c5f4f000011480000000003938700`
  - **After:**  `0x00000000000000000000000000000000000c5f4f000011480000000001c9c380`
  - **Summary:** `gasLimit` (`uint64`, the low 8 bytes of the slot) `60000000` (`0x3938700`)
    → `30000000` (`0x1c9c380`). The same slot packs `basefeeScalar` (`0x1148` = 4424) and
    `blobbasefeeScalar` (`0xc5f4f` = 810831), both unchanged.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...48` (72) → **After:** `0x...49` (73)
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects
    the nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the
simulation's sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com
SC=0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364

cast call $SC "gasLimit()(uint64)" -r $RPC                                            # 30000000
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 73

# Unchanged
cast call $SC "owner()(address)" -r $RPC                 # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
cast call $SC "basefeeScalar()(uint32)" -r $RPC          # 4424
cast call $SC "blobbasefeeScalar()(uint32)" -r $RPC      # 810831
cast call $SC "eip1559Denominator()(uint32)" -r $RPC     # 0
cast call $SC "eip1559Elasticity()(uint32)" -r $RPC      # 0

# Ink adopts the new limit once the L1 block containing the ConfigUpdate becomes an L1 origin.
cast block latest --field gasLimit -r https://rpc-gel.inkonchain.com   # 30000000
```
