# Validation

This document can be used to validate the inputs and result of the execution of
the transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the
values on your ledger and the values printed to the terminal when you run the
task. The hashes assume the pinned nonces in [config.toml](./config.toml).

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xe7c0f1f9163bc1016ec2e09d79ee3da76e8fcf62eab0fba4f9a2c2255328226f`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xf621e8a79c6ca7dda9c6d19138e549035369c41d63e286a80863f629b08695b8`

Root L1PAO (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) safe transaction hash
(identical on both signing paths):
`0xd12f95d7291d245c505669ac68d3a5eb5481d412641725313ab0d44bcf83efe5`

## Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000005c00000000000000000000000003f37abde2c6b5b2ed6f8045787df1ed1e37539560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b85700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008b34b14c7c7123459cf3076b8cb929be097d0c070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b85700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a0ad011913a150f69f6a19df447a0cfd95510540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b8570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f573a6da7a5b5de9fbadfc26cffc595ad04dc7d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b8570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Understanding Task Calldata

The task is a single `Multicall3.aggregate3Value` from the L1PAO (selector
`0x174dea71`, the first four bytes above) containing **4** `depositTransaction`
calls (selector `0xe9e05c42`), one per chain's L1 OptimismPortal. Every deposit
uses `_to = 0x4200000000000000000000000000000000000018` (the L2 ProxyAdmin
predeploy), `_value = 0`, `_gasLimit = 200000` (`0x30d40`),
`_isCreation = false`, and carries the same inner payload —
`transferOwnership(address)`, selector `0xf2fde38b`, with the aliased operator
Safe `0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857`. On each L2 the deposit
executes as `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`, the alias of the
current L1PAO, which is the L2 ProxyAdmin owner the transfer authorizes
against.

| # | Portal | Chain |
|---|---|---|
| 1 | `0x3F37aBdE2C6b5B2ed6F8045787Df1ED1E3753956` | Metal (1750) |
| 2 | `0x8B34b14c7c7123459Cf3076b8Cb929BE097d0C07` | Mode (34443) |
| 3 | `0x1a0ad011913A150f69f6A19DF447A0CfD9551054` | Zora (7777777) |
| 4 | `0xF573A6DA7a5b5dE9fbADfC26cFFC595ad04Dc7D4` | Dust (55378) |

To verify the inner payload fingerprint:

```bash
cast calldata "transferOwnership(address)" 0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857
# Expected: 0xf2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b857

# The alias is newOwner + 0x1111000000000000000000000000000000001111:
cast to-check-sum-address $(python3 -c "print(hex((0x4a4962275DF8C60a80d3a25faEc5AA7De116A746 + 0x1111000000000000000000000000000000001111) % 2**160))")
# Expected: 0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857
```

Every byte not belonging to the fields above is standard ABI encoding:
zero-padding, offsets, and lengths. The deposit selector `e9e05c42`, the gas
limit `30d40` and the payload selector `f2fde38b` each appear exactly 4 times,
and each portal exactly once. To decode the full calldata back into the four
deposits and confirm no additional content is present:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

## L1 and L2 Simulation

### L1 Simulation

```bash
cd src/tasks/eth/068-mmzd-l2pao-transfer
just simulate-stack eth 068-mmzd-l2pao-transfer council   # or foundation
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the
   top of this file.
2. In the Tenderly link printed by the simulation: paste the
   [task calldata](#task-calldata) into the **Raw input data** field and
   simulate; the state diff must match
   [L1 State Changes](#l1-state-changes) below.
3. The Tenderly **Events** tab shows exactly four `TransactionDeposited`
   events, one per portal, each with
   `from = 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` and
   `to = 0x4200000000000000000000000000000000000018`.

### L2 Simulation

**Manual replay (required independent check):** reproduce exactly what each
deposit will do on its L2 and inspect the resulting state, on a local fork.
Repeat for each chain (Metal, Mode, Zora and Dust are not in Tenderly's
supported-network list, so the replay is local only):

```bash
# 1. Fork the chain (one at a time):
anvil --fork-url https://rpc.metall2.com --port 9545              # Metal
# anvil --fork-url https://mainnet.mode.network --port 9545       # Mode
# anvil --fork-url https://rpc.zora.energy --port 9545            # Zora
# anvil --fork-url https://rpc-dust-mainnet-0.t.conduit.xyz --port 9545  # Dust

# 2. Impersonate the deposits' L2 sender — the aliased L1PAO (= the L2 ProxyAdmin owner)
L2RPC=http://127.0.0.1:9545
ALIASED=0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
cast rpc anvil_impersonateAccount $ALIASED --rpc-url $L2RPC
cast rpc anvil_setBalance $ALIASED 0xDE0B6B3A7640000 --rpc-url $L2RPC

# 3. Send the exact inner call the deposit carries
cast send 0x4200000000000000000000000000000000000018 "transferOwnership(address)" \
  0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857 \
  --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 200000

# 4. Compare the storage diff against "L2 State Changes" below, then kill anvil
cast storage 0x4200000000000000000000000000000000000018 0 --rpc-url $L2RPC
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url $L2RPC
```

## Task State Changes

### L1 State Changes

#### `0x1a0ad011913A150f69f6A19DF447A0CfD9551054` (Zora OptimismPortalProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** deposit gas metering (`ResourceMetering.ResourceParams`).
    After: `prevBoughtGas` = `0x30d40` = 200,000 (this portal's single
    deposit); `prevBlockNum` = the simulation block; `prevBaseFee` unchanged at
    1 gwei (`0x3b9aca00`). Only this slot of each portal may change.

#### `0x24424336F04440b1c28685a38303aC33C9D14a25` (SecurityCouncil LivenessGuard)

- **Key:** `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Before:** `0x00...00` → **After:** the simulation block timestamp
  - **Summary:** `lastLive[0xca11bde05977b3631167028862bE2a173976CA11]` — a
    **simulation artifact**. The simulation overrides the child safe's owners
    and threshold so Multicall3 acts as the sole signer, and the guard records
    a liveness timestamp for it. On the real execution this is written for the
    actual signers instead.

#### `0x3F37aBdE2C6b5B2ed6F8045787Df1ED1E3753956` (Metal OptimismPortalProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** same `ResourceParams` update as the Zora portal above.

#### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (ProxyAdminOwner, root safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...29` (41) → **After:** `0x...2a` (42)
  - **Summary:** nonce increment of the root safe executing the task. The
    before-value reflects the nonce state override in
    [config.toml](./config.toml).
- **Key (council path):**    `0x63a8fd0c4c702409dcc29f0e0776bc7f636fc8a0e6c6ef2ef3888673dfbb2eb9`
- **Key (foundation path):** `0x06f4d8be9f7e0bd7609d7018ffa29cdc8c129409f8cc8951021b3787e4cbb61c`
  - **Before:** `0x00...00` → **After:** `0x00...01`
  - **Summary:** `approvedHashes[<child safe>][<root safe tx hash>] = 1` — the
    child safe's approval of the task.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...43` (67) → **After:** `0x...44` (68)
  - **Summary:** nonce increment of the approving child safe.

#### `0x8B34b14c7c7123459Cf3076b8Cb929BE097d0C07` (Mode OptimismPortalProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** same `ResourceParams` update as the Zora portal above.

#### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (SecurityCouncil)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...41` (65) → **After:** `0x...42` (66)
  - **Summary:** nonce increment of the approving child safe.

#### `0xF573A6DA7a5b5dE9fbADfC26cFFC595ad04Dc7D4` (Dust OptimismPortalProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** same `ResourceParams` update as the Zora portal above. Dust is
    not in the superchain-registry, so Tenderly cannot label this contract —
    verify the address against [addresses.json](./addresses.json).

Tenderly also shows `Nonce N → N+1` (no storage key) on the child safe used as
the simulation's sender — its protocol account nonce, unrelated to the Safe's
signing nonce. Ignore it; it does not occur on the real execution.

### L2 State Changes

Applied on each L2 when its deposit is relayed. Verified by replaying the
deposit on forks of all four chains and diffing the predeploy's storage:
exactly the write below occurs on every chain, nothing else.

#### `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin) — same on Metal, Mode, Zora and Dust

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b`
  - **After:**  `0x0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b857`
  - **Summary:** owner: aliased L1PAO → aliased operator Safe
    (`0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` + alias offset).

## Post-execution verification calls

The L2 changes land only once each deposit is relayed. Each command is expected
to return the new owner `0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857`:

```bash
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://rpc.metall2.com
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://mainnet.mode.network
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://rpc.zora.energy
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://rpc-dust-mainnet-0.t.conduit.xyz
```

If any value did not update, that chain's deposit reverted on L2 while the L1
transaction still shows success: inspect the relayed L2 transaction sent from
`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` to the L2 ProxyAdmin on that
chain's explorer.
