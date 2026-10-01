# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1 nonce 11) and move only if that
nonce moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Unichain SystemConfigOwner (`0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1`)
>
> - Domain Hash:  `0xbea15583997db2831ec7dea58be331771c073bea8444c2b48ded663621f2260e`
> - Message Hash: `0x940e07eb7e9a34e4bf8b583c0d84c5fa29ade58fadcb07876b3497a5274fc79a`

Safe transaction hash: `0xec2a1e1d53a1af4108eaf9f1fed35385ee45e219b449547d816761fbd1bd795d`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/074-unichain-system-config-owner-to-fus
just simulate-stack eth 074-unichain-system-config-owner-to-fus
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, `Safe.execTransaction`, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes), and
   nothing else. The inner task calldata (`0x174dea71`) on its own reverts against the Safe.
3. The call trace shows a single `transferOwnership` call on `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` with
   `newOwner = 0x847B5c174615B1B7fDF770882256e2D3E95b9D92`, and one `OwnershipTransferred(0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1, 0x847B5c174615B1B7fDF770882256e2D3E95b9D92)` event.
4. `newOwner` (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`) is the Mainnet Foundation Upgrade Safe, see
   [Verifying the new owner](#verifying-the-new-owner).

### Verifying the new owner

The transfer is irreversible for the current owner, so check that `newOwner` is the Mainnet
Foundation Upgrade Safe against independent sources:

- [`src/addresses.toml#L6`](../../../addresses.toml#L6) `FoundationUpgradeSafe`.
- superchain-registry [`standard-config-roles-mainnet.toml#L4`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/validation/standard/standard-config-roles-mainnet.toml#L4) lists it as the standard `protocolVersionsOwner`, and [`#L3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/validation/standard/standard-config-roles-mainnet.toml#L3) lists the L1 ProxyAdmin owner `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`, whose two owners are the Foundation Upgrade Safe and the Security Council (first check below).
- On-chain:

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A "getOwners()(address[])" -r $RPC   # [0x847B5c174615B1B7fDF770882256e2D3E95b9D92, 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03] (L1PAO = FUS + Security Council)
cast call 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 "owner()(address)" -r $RPC        # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (OP Mainnet SystemConfig owner)
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "owner()(address)" -r $RPC        # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (Ink SystemConfig owner since eth/065)
```

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the Safe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d9200000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the Safe (selector
`0x174dea71`) containing **1** call, with `allowFailure = false` and `value = 0`:

| # | Target | Function | Argument |
|---|---|---|---|
| 1 | `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` (Unichain SystemConfigProxy) | `transferOwnership(address)` | `newOwner = 0x847B5c174615B1B7fDF770882256e2D3E95b9D92` |

To verify the payload fingerprint:

```bash
cast calldata "transferOwnership(address)" 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
# Expected: 0xf2fde38b000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d92
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1 "nonce()(uint256)" -r $RPC          # 11
cast call 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6 "owner()(address)" -r $RPC           # 0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "getThreshold()(uint256)" -r $RPC   # must succeed (newOwner is a Safe)
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/074-unichain-system-config-owner-to-fus

SIGNATURES=0x... just execute
```

### Task State Changes

Two contracts change.

#### `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` (Unichain SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000009245d5d10aa8a842b31530de71ea86c0760ca1b1`
  - **After:**  `0x000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d92`
  - **Summary:** `owner` (OZ `OwnableUpgradeable` slot) moves to the Foundation Upgrade Safe.

#### `0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1` (Unichain SystemConfigOwner)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `11` → **After:** `12`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6 "owner()(address)" -r $RPC   # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
cast call 0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1 "nonce()(uint256)" -r $RPC  # 12
```
