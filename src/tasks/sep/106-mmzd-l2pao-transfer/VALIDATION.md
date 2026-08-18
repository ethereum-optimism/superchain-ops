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
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x6a67f09f1a1c8b105eae288e9c632946e3476e7186536356b880086ddcf425c4`
>
> ### SecurityCouncil (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x728f5d7b3e86bfe4944b71dbf73f2789c2332ffcb51161fb60e9890170de1be5`

Root L1PAO (`0x1Eb2fFc903729a0F03966B917003800b145F56E2`) safe transaction hash
(identical on both signing paths):
`0xec3fcc4f08f68180a65da83310f141bdae53b2ff033ec879d63908c2a9671591`

## Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000005c000000000000000000000000001d4dfc994878682811b2980653d03e589f093cb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b00000000000000000000000045588c2eb9018d5a6487bf0440838cd4238e9e030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000320e1580efff37e008f1c92700d1eba47c1b23fd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b00000000000000000000000045588c2eb9018d5a6487bf0440838cd4238e9e030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000effe2c6ca9ab797d418f0d91ea60807713f3536f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b00000000000000000000000045588c2eb9018d5a6487bf0440838cd4238e9e030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e6230bd9e96ad839d4c546710d9a99835052d1c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b00000000000000000000000045588c2eb9018d5a6487bf0440838cd4238e9e030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Understanding Task Calldata

The task is a single `Multicall3.aggregate3Value` from the L1PAO (selector
`0x174dea71`, the first four bytes above) containing **4** `depositTransaction`
calls (selector `0xe9e05c42`), one per chain's L1 OptimismPortal. Every deposit
uses `_to = 0x4200000000000000000000000000000000000018` (the L2 ProxyAdmin
predeploy), `_value = 0`, `_gasLimit = 200000` (`0x30d40`),
`_isCreation = false`, and carries the same inner payload —
`transferOwnership(address)`, selector `0xf2fde38b`, with the aliased operator
Safe `0x45588C2Eb9018d5a6487bF0440838cd4238E9E03`. On each L2 the deposit
executes as `0x2FC3ffc903729a0f03966b917003800B145F67F3`, the alias of the
current L1PAO, which is the L2 ProxyAdmin owner the transfer authorizes
against.

| # | Portal | Chain |
|---|---|---|
| 1 | `0x01D4dfC994878682811b2980653D03E589f093cB` | Metal Sepolia (1740) |
| 2 | `0x320e1580effF37E008F1C92700d1eBa47c1B23fD` | Mode Sepolia (919) |
| 3 | `0xeffE2C6cA9Ab797D418f0D91eA60807713f3536f` | Zora Sepolia (999999999) |
| 4 | `0xe6230Bd9e96AD839D4c546710D9A99835052d1C1` | Dust Testnet (55377) |

To verify the inner payload fingerprint:

```bash
cast calldata "transferOwnership(address)" 0x45588C2Eb9018d5a6487bF0440838cd4238E9E03
# Expected: 0xf2fde38b00000000000000000000000045588c2eb9018d5a6487bf0440838cd4238e9e03

# The alias is newOwner + 0x1111000000000000000000000000000000001111:
cast to-check-sum-address $(python3 -c "print(hex((0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2 + 0x1111000000000000000000000000000000001111) % 2**160))")
# Expected: 0x45588C2Eb9018d5a6487bF0440838cd4238E9E03
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
cd src/tasks/sep/106-mmzd-l2pao-transfer
just simulate-stack sep 106-mmzd-l2pao-transfer council   # or foundation
```

Check three things:

1. The domain and message hashes printed to the terminal match the ones at the
   top of this file.
2. In the Tenderly link printed by the simulation: paste the
   [task calldata](#task-calldata) into the **Raw input data** field and
   simulate; the state diff must match
   [L1 State Changes](#l1-state-changes) below.
3. The Tenderly **Events** tab shows exactly four `TransactionDeposited`
   events, one per portal, each with
   `from = 0x2FC3ffc903729a0f03966b917003800B145F67F3` and
   `to = 0x4200000000000000000000000000000000000018`.

### L2 Simulation

**Manual replay (required independent check):** reproduce exactly what each
deposit will do on its L2 and inspect the resulting state, on a local fork.
Repeat for each chain (these L2s are not in Tenderly's supported-network list,
so the replay is local only):

```bash
# 1. Fork the chain (one at a time):
anvil --fork-url https://testnet.rpc.metall2.com --port 9545            # Metal Sepolia
# anvil --fork-url https://sepolia.mode.network --port 9545             # Mode Sepolia
# anvil --fork-url https://sepolia.rpc.zora.energy --port 9545          # Zora Sepolia
# anvil --fork-url https://rpc-dust-testnet-0.t.conduit.xyz --port 9545 # Dust Testnet

# 2. Impersonate the deposits' L2 sender — the aliased L1PAO (= the L2 ProxyAdmin owner)
L2RPC=http://127.0.0.1:9545
ALIASED=0x2FC3ffc903729a0f03966b917003800B145F67F3
cast rpc anvil_impersonateAccount $ALIASED --rpc-url $L2RPC
cast rpc anvil_setBalance $ALIASED 0xDE0B6B3A7640000 --rpc-url $L2RPC

# 3. Send the exact inner call the deposit carries
cast send 0x4200000000000000000000000000000000000018 "transferOwnership(address)" \
  0x45588C2Eb9018d5a6487bF0440838cd4238E9E03 \
  --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 200000

# 4. Compare the storage diff against "L2 State Changes" below, then kill anvil
cast storage 0x4200000000000000000000000000000000000018 0 --rpc-url $L2RPC
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url $L2RPC
```

This replay was executed during task preparation (2026-08-18) on forks of all
four chains: the transfer succeeds at 33,545 gas (6x headroom under the 200k
deposit limit), changes only slot `0` of the predeploy, and the same call from
any other sender reverts with `Ownable: caller is not the owner`.

## Task State Changes

### L1 State Changes

Tenderly lists the touched contracts in address order, as below. The council
path shows the LivenessGuard and SecurityCouncil entries; the foundation path
shows the FoundationUpgradeSafe entry instead. Anything not listed here
appearing in the diff means the transaction does not do what this document
claims: do not sign.

#### `0x01D4dfC994878682811b2980653D03E589f093cB` (Metal Sepolia OptimismPortalProxy) — both paths

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** deposit gas metering (`ResourceMetering.ResourceParams`).
    After: `prevBoughtGas` = `0x30d40` = 200,000 (this portal's single
    deposit); `prevBlockNum` = the simulation block; `prevBaseFee` unchanged at
    1 gwei (`0x3b9aca00`). Only this slot of each portal may change.

#### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (ProxyAdminOwner, root safe) — both paths

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...37` (55) → **After:** `0x...38` (56)
  - **Summary:** nonce increment of the root safe executing the task. The
    before-value reflects the nonce state override in
    [config.toml](./config.toml).
- **Key (council path):**    `0xb5a8f3859b644d479f4eac8b8391fb26e999852f988d8e682ebbaad0deb8f1d6`
- **Key (foundation path):** `0xdb028ed470014dcc3530215cc241e190f9708c82cdcd2bc5ba4c1e1282503f50`
  - **Before:** `0x00...00` → **After:** `0x00...01`
  - **Summary:** `approvedHashes[<child safe>][<root safe tx hash>] = 1` — the
    child safe's approval of the task.

#### `0x320e1580effF37E008F1C92700d1eBa47c1B23fD` (Mode Sepolia OptimismPortalProxy) — both paths

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** same `ResourceParams` update as the Metal Sepolia portal above.

#### `0xc26977310bC89DAee5823C2e2a73195E85382cC7` (SecurityCouncil LivenessGuard) — council path only

- **Key:** `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Before:** `0x00...00` → **After:** the simulation block timestamp
  - **Summary:** `lastLive[0xca11bde05977b3631167028862bE2a173976CA11]` — a
    **simulation artifact**. The simulation overrides the child safe's owners
    and threshold so Multicall3 acts as the sole signer, and the guard records
    a liveness timestamp for it. On the real execution this is written for the
    actual signers instead.

#### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe) — foundation path only

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...4b` (75) → **After:** `0x...4c` (76)
  - **Summary:** nonce increment of the approving child safe.

#### `0xe6230Bd9e96AD839D4c546710D9A99835052d1C1` (Dust Testnet OptimismPortalProxy) — both paths

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** same `ResourceParams` update as the Metal Sepolia portal above.
    Dust is not in the superchain-registry, so Tenderly cannot label this
    contract — verify the address against [addresses.json](./addresses.json).

#### `0xeffE2C6cA9Ab797D418f0D91eA60807713f3536f` (Zora Sepolia OptimismPortalProxy) — both paths

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** same `ResourceParams` update as the Metal Sepolia portal above.

#### `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (SecurityCouncil) — council path only

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...45` (69) → **After:** `0x...46` (70)
  - **Summary:** nonce increment of the approving child safe.

Tenderly also shows `Nonce N → N+1` (no storage key) on the child safe used as
the simulation's sender — its protocol account nonce, unrelated to the Safe's
signing nonce. Ignore it; it does not occur on the real execution.

### L2 State Changes

Applied on each L2 when its deposit is relayed. Verified by replaying the
deposit on forks of all four chains and diffing the predeploy's storage:
exactly the write below occurs on every chain, nothing else.

#### `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin) — identical on Metal, Mode, Zora Sepolia and Dust Testnet

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000002fc3ffc903729a0f03966b917003800b145f67f3`
  - **After:**  `0x00000000000000000000000045588c2eb9018d5a6487bf0440838cd4238e9e03`
  - **Summary:** owner: aliased L1PAO → aliased operator Safe
    (`0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` + alias offset).

## Post-execution verification calls

The L2 changes land only once each deposit is relayed. Each command is expected
to return the new owner `0x45588C2Eb9018d5a6487bF0440838cd4238E9E03`:

```bash
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://testnet.rpc.metall2.com
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://sepolia.mode.network
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://sepolia.rpc.zora.energy
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://rpc-dust-testnet-0.t.conduit.xyz
```

If any value did not update, that chain's deposit reverted on L2 while the L1
transaction still shows success: inspect the relayed L2 transaction sent from
`0x2FC3ffc903729a0f03966b917003800B145F67F3` to the L2 ProxyAdmin on that
chain's explorer.
