# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonces in [config.toml](./config.toml) (ProxyAdminOwner 13, DunamuUpgradeSafe 1,
GIWASecurityCouncil 2) and move only if one of those nonces moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### DunamuUpgradeSafe (`0x3d58888b6903B87bD030b93F6FD37cb843b92DB7`)
>
> - Domain Hash:  `0x7facc7260bdbe9daf48f963a4cc37c2f6c572f111108f5098f7a812765fb69ae`
> - Message Hash: `0x9c36fd6747506bfba9f63e58b33e882ce1d4a5fc116386b8ed824191f45ab988`
>
> ### GIWASecurityCouncil (`0x37FF75B6545F0747b21c43EEB95744b791d1bf1C`)
>
> - Domain Hash:  `0xd40b6fd43756c32be619cfaf561fa03ebd664df652dbadab1cb5160c47ea115b`
> - Message Hash: `0x51151485276a4872c01cdb637d7f35c5d03ac3489279822ff01c046dafa0c955`

Root GIWA Sepolia ProxyAdminOwner (`0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E`) safe
transaction hash (identical on both signing paths):
`0xd1dbd0366bacae42c03611b3b5e9f1973c461d11f7ffe3511382be46e990a554`

Child safe transaction hashes (the value each owner signs, `keccak256(0x1901 ‖ domain ‖ message)`):

- DunamuUpgradeSafe: `0xffd768c6cd8bc86af06a886c01408cf35b68cbae48c0b131df2e9a9b8e8077ca`
- GIWASecurityCouncil: `0xd005db108ebe1185bffc4f56213e8c1a974f8f1df613d69c6d40ae04b5f1f206`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/124-U20-giwa-sepolia
just simulate-stack sep 124-U20-giwa-sepolia DunamuUpgradeSafe   # or GIWASecurityCouncil
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the
   [task calldata](#task-calldata) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes),
   and nothing else.
3. The decoded `upgrade` input shows `startingRespectedGameType = 5`, game 9 disabled, and the
   anchor root/timestamp from [config.toml](./config.toml).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers: the raw
calldata and its breakdown, the pre-execution checks and execution commands, the expected
state changes and the post-execution checks. Signers only need the two sections above.

### Task Calldata

```
0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001600000000000000000000000006abfabbc793883add5fa308a97163e8225a9f4ca00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000008486fe1c660000000000000000000000000000000000000000000000000000000000000020000000000000000000000000ef3a8c9ec7873c3acee4e6153fb66072cde9032d00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006abfabbc793883add5fa308a97163e8225a9f4ca0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000007648a847e2e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000008352825ba56c32d816dd906ad4a392b5bc9ec98400000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000520000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002a00000000000000000000000000000000000000000000000000000000000000360000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000032d5bd4401047e3a3d9f5e18226bf4e1699097c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000276f76657272696465732e6366672e7374617274696e6752657370656374656447616d655479706500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000206f76657272696465732e6366672e7374617274696e67416e63686f72526f6f7400000000000000000000000000000000000000000000000000000000000000406afd237816adcfb144cc0d7aef8c33ed298612448d1e20e65cd5b7b5e66c5be6000000000000000000000000000000000000000000000000000000006aec1bf700000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3` from the ProxyAdminOwner (selector
`0x82ad56cb`, the first four bytes above) containing **2** delegatecalls, both to the OPCM
`0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca` with `allowFailure = false`:

| # | Function | Selector | Payload |
|---|---|---|---|
| 1 | `upgradeSuperchain((address,(string,bytes)[]))` | `0x86fe1c66` | GIWA SuperchainConfig `0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d`, no extra instructions |
| 2 | `upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))` | `0x8a847e2e` | GIWA Sepolia Testnet |

The `upgrade` call carries the chain's `SystemConfigProxy`, six game configs in the fixed order
0, 1, 8, 5, 9, 10 and two extra instructions. Game types 0, 1, 8, 9 and 10 are disabled
(`enabled = false`, zero bond, empty args). The enabled config and overrides are:

| Chain | SystemConfigProxy | Game 5 args (proposer), bond | Game 9 | `startingRespectedGameType` | `startingAnchorRoot` (root, timestamp) |
|---|---|---|---|---|---|
| GIWA Sepolia Testnet | `0x8352825bA56C32d816Dd906Ad4A392B5BC9eC984` | `0x032D5bd4401047e3A3d9f5e18226bF4E1699097c`, 0 | disabled (no CANNON_KONA impl to carry over) | 5 | `0x6afd237816adcfb144cc0d7aef8c33ed298612448d1e20e65cd5b7b5e66c5be6`, 1793858551 |

The proposer is the chain's registry `Proposer` role
([addresses.json](https://github.com/ethereum-optimism/superchain-registry/blob/8fde8b3c615ffac0cf9ba82cbdb1fd716a4a7f8a/superchain/extra/addresses/addresses.json)),
the same address the current PERMISSIONED_CANNON game args carry. The `cannonKonaPrestate` in
[config.toml](./config.toml) is not encoded anywhere in the calldata.

To verify the fingerprint of call 1:

```bash
cast calldata "upgradeSuperchain((address,(string,bytes)[]))" "(0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d,[])"
# Expected: 0x86fe1c660000000000000000000000000000000000000000000000000000000000000020000000000000000000000000ef3a8c9ec7873c3acee4e6153fb66072cde9032d00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000
```

Every byte not belonging to the payloads above is standard ABI encoding: zero-padding,
offsets and lengths. The OPCM address appears exactly 2 times (as target), the `upgrade`
selector `8a847e2e` exactly once and the anchor root exactly once. To decode the calldata back
into the two calls and the `upgrade` input:

```bash
cast calldata-decode "aggregate3((address,bool,bytes)[])" <task calldata>
# then, for the 0x8a847e2e... payload returned above:
cast calldata-decode "upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))" <payload>
```

### Pre-execution checks and execution

Before approving, confirm the live state still matches the assumptions in
[config.toml](./config.toml):

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

# Nonces must equal the pins (13 / 1 / 2); if not, re-simulate and regenerate the hashes.
cast call 0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E "nonce()(uint256)" -r $RPC   # ProxyAdminOwner
cast call 0x3d58888b6903B87bD030b93F6FD37cb843b92DB7 "nonce()(uint256)" -r $RPC   # DunamuUpgradeSafe
cast call 0x37FF75B6545F0747b21c43EEB95744b791d1bf1C "nonce()(uint256)" -r $RPC   # GIWASecurityCouncil

# The L1 ProxyAdmin, the SuperchainConfig ProxyAdmin and the DisputeGameFactory must be owned by
# the ProxyAdminOwner 0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E; execution reverts otherwise.
cast call 0x6AdB900DC56F7028D5E7943638897C8103cf0da5 "owner()(address)" -r $RPC   # L1 ProxyAdmin
cast call 0x06E971d7d25fAB6BFd4C850BE0A9F6b7910f248C "owner()(address)" -r $RPC   # SuperchainConfig ProxyAdmin
cast call 0x37347caB2afaa49B776372279143D71ad1f354F6 "owner()(address)" -r $RPC   # DisputeGameFactory
```

Then approve once per child safe with the collected signatures and execute:

```bash
cd src/tasks/sep/124-U20-giwa-sepolia

SIGNATURES=0x... just approve DunamuUpgradeSafe
SIGNATURES=0x... just approve GIWASecurityCouncil
just execute
```

### Task State Changes

Tenderly lists the contracts below and nothing else, on either signing path. Chain addresses
are the registry entries in
[addresses.json](https://github.com/ethereum-optimism/superchain-registry/blob/8fde8b3c615ffac0cf9ba82cbdb1fd716a4a7f8a/superchain/extra/addresses/addresses.json).

#### `0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d` (GIWA SuperchainConfig)

- ERC-1967 implementation `0xE4F9779ab53070a55db24dFAeFf9AF147c6ED550` (2.4.2) →
  `0x5570b1f2b97B1E35b5C6f9Ee76f6cf02c9917504` (2.4.3), written by `upgradeSuperchain`.

#### `0x8352825bA56C32d816Dd906Ad4A392B5BC9eC984` (SystemConfigProxy)

- ERC-1967 implementation `0x42Ad0173051225Ac784100e9acD43349707F4db9` (3.14.2) →
  `0x670b850A235A6fA98cD7a195eB139D0277E471fA` (4.0.0).
- Legacy batch inbox slot `0x71ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597`
  `0x00Ef2e3B7754f2a65F1e897a27A3306D9B52F544` → zero (4.0.0 removed it, derivation reads the
  inbox from the rollup config).
- Recorded OPCM slot `0x99f45962df4bc30de8d4c3c6d1ffc0f100edce16e80c7a5768b6d55ca463ff42`
  `0x69F1991706b4f11F651eB2aF363bF88459fC24fF` (GIWA's v7 OPCM, 7.1.17) →
  `0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca` (8.0.1).

#### `0x956962C34687A954e611A83619ABaA37Ce6bC78A` (OptimismPortalProxy)

- ERC-1967 implementation `0xe89F13c5ee4033B2D3cD76C9d6958eFBfe26D3C2` (5.6.1) →
  `0x1005217ad392DC64CEf501FA1777A27D42166748` (5.8.0).

#### `0x6DaB826f3cF6932FB8614D00442612834873d61d` (AnchorStateRegistryProxy)

The simulation's slot labels for this contract are off by one; the slots below follow the
3.9.0 layout.

- Slot `0x02` `anchorGame` `0xd3698F500C47b2244294abcb069d7C8E88471d46` → zero (cleared).
- Slots `0x03` / `0x04` `startingAnchorRoot` `(0x4fbeab60264ad6066accd1328c7f7695c9036f71ac6c18dd4949c94e9bffd624, 8976739)`
  → `(0x6afd237816adcfb144cc0d7aef8c33ed298612448d1e20e65cd5b7b5e66c5be6, 1793858551)`
  (the values in [config.toml](./config.toml)).
- Slot `0x06` `respectedGameType` 1 (PERMISSIONED_CANNON) → 5 (SUPER_PERMISSIONED); the packed
  `retirementTimestamp` `0x69142ed8` (1762930392) is unchanged.
- The implementation is unchanged.

#### `0x37347caB2afaa49B776372279143D71ad1f354F6` (DisputeGameFactoryProxy)

- `gameImpls[1]` (`0x4d5a9bd2…a35f9e`) `0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e`
  (PermissionedDisputeGame) → zero.
- `initBonds[1]` (`0xe34b8b74…da2dce6`) 0.08 ETH → 0.
- `gameArgs[1]` (`0xc073f36c…536add` and its six data words `0x9afb513d…fb0fa7c` –
  `…fb0fa81`) cleared. The old 164-byte args were the `0xdead…` placeholder prestate, MIPS
  `0xacc005dcd857b401e4732e6f7837135a22825cfa`, the AnchorStateRegistry, DelayedWETH
  `0x11ada074a88066119dc95e9efe706736a82233b2`, chain id 91342, the proposer and the challenger
  `0x4160344aa39B6237D44A4e3F2e57A211f0fBeBFF`.
- `gameImpls[5]` (`0xa658daa5…5ce9b2`) zero → `0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`
  (SuperPermissionedDisputeGame 1.1.0), bondless.
- `gameArgs[5]` (`0x58181d40…70d979`, data words `0x7879f54b…5acf7` / `…5acf8`) set to the 40
  bytes AnchorStateRegistry `0x6DaB826f3cF6932FB8614D00442612834873d61d` ‖ proposer
  `0x032D5bd4401047e3A3d9f5e18226bF4E1699097c`.
- No game type 9 entries (the chain had no CANNON_KONA impl). The implementation is unchanged.

#### `0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E` (GIWA Sepolia ProxyAdminOwner, 2-of-2 safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...0d` (13) → **After:** `0x...0e` (14)
  - **Summary:** nonce increment of the safe executing the task. The before-value is the
    nonce state override in [config.toml](./config.toml).
- **Key (DunamuUpgradeSafe path):** `0x0c2b6de081890933fda5e256db216cf9a67c9df350d111c85ec40922a6a08239`
- **Key (GIWASecurityCouncil path):** `0x2b4299ff8ff04b274b360c673f7a5db7ac74579f1948b93a721a28c9424b2a9d`
  - **Before:** `0x00...00` → **After:** `0x00...01`
  - **Summary:** `approvedHashes[<child safe>][<root safe tx hash>] = 1`, the child safe's
    approval of the task.

##### `0x3d58888b6903B87bD030b93F6FD37cb843b92DB7` (DunamuUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...01` (1) → **After:** `0x...02` (2)
  - **Summary:** nonce increment of the approving child safe.

##### `0x37FF75B6545F0747b21c43EEB95744b791d1bf1C` (GIWASecurityCouncil)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...02` (2) → **After:** `0x...03` (3)
  - **Summary:** nonce increment of the approving child safe.

Not listed: the L1CrossDomainMessenger, L1StandardBridge, L1ERC721Bridge,
OptimismMintableERC20Factory and DelayedWETH proxies are untouched, since their implementations
did not change between v7.1.17 and v8.0.0. The chain has no ETHLockbox. Tenderly also shows
`Nonce N → N+1` (no storage key) on the account used as the simulation's sender. That is its
protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
ASR=0x6DaB826f3cF6932FB8614D00442612834873d61d; DGF=0x37347caB2afaa49B776372279143D71ad1f354F6

cast call $ASR "respectedGameType()(uint32)" -r $RPC                  # 5
cast call $ASR "getAnchorRoot()(bytes32,uint256)" -r $RPC             # 0x6afd2378…5be6, 1793858551 (until the first game 5 is anchored)
cast call $ASR "retirementTimestamp()(uint64)" -r $RPC                # 1762930392 (unchanged)
cast call $DGF "gameImpls(uint32)(address)" 5 -r $RPC                 # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691
cast call $DGF "gameArgs(uint32)(bytes)" 5 -r $RPC                    # 0x6dab826f…d61d032d5bd4…097c
cast call $DGF "initBonds(uint32)(uint256)" 5 -r $RPC                 # 0
cast call $DGF "gameImpls(uint32)(address)" 1 -r $RPC                 # 0x0000000000000000000000000000000000000000
cast call $DGF "gameImpls(uint32)(address)" 9 -r $RPC                 # 0x0000000000000000000000000000000000000000
cast call 0x8352825bA56C32d816Dd906Ad4A392B5BC9eC984 "version()(string)" -r $RPC   # 4.0.0
cast call 0x956962C34687A954e611A83619ABaA37Ce6bC78A "version()(string)" -r $RPC   # 5.8.0
cast call 0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d "version()(string)" -r $RPC   # 2.4.3

# Unchanged: owners and guardian
cast call $DGF "owner()(address)" -r $RPC                                          # 0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E
cast call 0x8352825bA56C32d816Dd906Ad4A392B5BC9eC984 "owner()(address)" -r $RPC   # 0x3d58888b6903B87bD030b93F6FD37cb843b92DB7
cast call 0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d "guardian()(address)" -r $RPC # 0xb033baF85ad00af475154a15c35FC00eda6f98A0
```
