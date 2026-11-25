# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonces in [config.toml](./config.toml) (ProxyAdminOwner 14, DunamuUpgradeSafe 2,
GIWASecurityCouncil 3) and move only if one of those nonces moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### DunamuUpgradeSafe (`0x3d58888b6903B87bD030b93F6FD37cb843b92DB7`)
>
> - Domain Hash:  `0x7facc7260bdbe9daf48f963a4cc37c2f6c572f111108f5098f7a812765fb69ae`
> - Message Hash: `0x49fee6720b215fb5430ba3d2afa3a62221f82c16d9d609fd1abf91051bee827c`
>
> ### GIWASecurityCouncil (`0x37FF75B6545F0747b21c43EEB95744b791d1bf1C`)
>
> - Domain Hash:  `0xd40b6fd43756c32be619cfaf561fa03ebd664df652dbadab1cb5160c47ea115b`
> - Message Hash: `0x5daede5f1396379ae4ee98b701ad97b0109e6adf1f55a41f2f12878ac0986902`

Root GIWA Sepolia ProxyAdminOwner (`0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E`) safe
transaction hash (identical on both signing paths):
`0x04dc6f06d2e0cd5c881c95d0dd3eac0e16b8b526e3af64beab6d79ab189cab4e`

Child safe transaction hashes (the value each owner signs, `keccak256(0x1901 ‖ domain ‖ message)`):

- DunamuUpgradeSafe: `0xa28ba589d1ee84e97f76f4a5d018cf649fe3542743e176fee0c99d544e64d6e8`
- GIWASecurityCouncil: `0xab6c13b9303f84524e608cc0f5f11a19b23b152f929f75ae18807b552ef1e68b`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/126-U21-giwa-sepolia
just simulate-stack sep 126-U21-giwa-sepolia DunamuUpgradeSafe   # or GIWASecurityCouncil
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the `0x6a761202…` hex the simulation
   prints under "Insert the following hex into the 'Raw input data' field" into the **Raw input
   data** field and simulate; the contracts touched must be the ones listed in
   [Task State Changes](#task-state-changes), and nothing else.
3. The decoded `upgrade` input shows `startingRespectedGameType = 5`, game 9 disabled and
   `PermittedProxyDeployment = ETHLockbox`.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers: the raw
calldata and its breakdown, the pre-execution checks and execution commands, the expected
state changes and the post-execution checks. Signers only need the two sections above.

### Task Calldata

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000160000000000000000000000000160f0fe4dc1b3f4026687e8dd4b7f800879939cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000008486fe1c660000000000000000000000000000000000000000000000000000000000000020000000000000000000000000ef3a8c9ec7873c3acee4e6153fb66072cde9032d0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000160f0fe4dc1b3f4026687e8dd4b7f800879939cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000007448a847e2e00000000000000000000000000000000000000000000000000000000000000200000000000000000000000008352825ba56c32d816dd906ad4a392b5bc9ec98400000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000520000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002a00000000000000000000000000000000000000000000000000000000000000360000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000032d5bd4401047e3a3d9f5e18226bf4e1699097c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000276f76657272696465732e6366672e7374617274696e6752657370656374656447616d655479706500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000185065726d697474656450726f78794465706c6f796d656e740000000000000000000000000000000000000000000000000000000000000000000000000000000a4554484c6f636b626f780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3` from the ProxyAdminOwner (selector
`0x82ad56cb`, the first four bytes above) containing **2** delegatecalls, both to the OPCM
`0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc` with `allowFailure = false`:

| # | Function | Selector | Payload |
|---|---|---|---|
| 1 | `upgradeSuperchain((address,(string,bytes)[]))` | `0x86fe1c66` | GIWA SuperchainConfig `0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d`, no extra instructions |
| 2 | `upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))` | `0x8a847e2e` | GIWA Sepolia Testnet |

The `upgrade` call carries the chain's `SystemConfigProxy`, six game configs in the fixed order
0, 1, 8, 5, 9, 10 and two extra instructions: `overrides.cfg.startingRespectedGameType`
(ABI-encoded `5`) and `PermittedProxyDeployment` (raw `ETHLockbox`, `0x4554484c6f636b626f78`).
Game types 0, 1, 8, 9 and 10 are disabled (`enabled = false`, zero bond, empty args).

| Chain | SystemConfigProxy | Game 5 args (proposer), bond | Game 9 | `startingRespectedGameType` |
|---|---|---|---|---|
| GIWA Sepolia Testnet | `0x8352825bA56C32d816Dd906Ad4A392B5BC9eC984` | `0x032D5bd4401047e3A3d9f5e18226bF4E1699097c`, 0 | disabled (no SUPER_CANNON_KONA impl) | 5 |

The proposer is the chain's registry `Proposer` role
([addresses.json](https://github.com/ethereum-optimism/superchain-registry/blob/308e08f7a0508e46c28686c9538fec39985b73c6/superchain/extra/addresses/addresses.json)), the same address the current
SUPER_PERMISSIONED game args carry. The `cannonKonaPrestate` in [config.toml](./config.toml) is
not encoded anywhere in the calldata.

To verify the fingerprint of call 1:

```bash
cast calldata "upgradeSuperchain((address,(string,bytes)[]))" "(0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d,[])"
# Expected: 0x86fe1c660000000000000000000000000000000000000000000000000000000000000020000000000000000000000000ef3a8c9ec7873c3acee4e6153fb66072cde9032d00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000
```

To decode the calldata back into the two calls and the `upgrade` input:

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

# Nonces must equal the pins (14 / 2 / 3); if not, re-simulate and regenerate the hashes.
cast call 0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E "nonce()(uint256)" -r $RPC   # ProxyAdminOwner
cast call 0x3d58888b6903B87bD030b93F6FD37cb843b92DB7 "nonce()(uint256)" -r $RPC   # DunamuUpgradeSafe
cast call 0x37FF75B6545F0747b21c43EEB95744b791d1bf1C "nonce()(uint256)" -r $RPC   # GIWASecurityCouncil

# No ETHLockbox yet; the portal holds the ETH that moves.
cast call 0x956962C34687A954e611A83619ABaA37Ce6bC78A "ethLockbox()(address)" -r $RPC   # 0x0000000000000000000000000000000000000000
cast balance 0x956962C34687A954e611A83619ABaA37Ce6bC78A -r $RPC                       # moves to the lockbox in full
```

Then approve once per child safe with the collected signatures and execute. Pass
`TENDERLY_GAS` explicitly (forge's own estimate leaves the inner Safe call short of gas):

```bash
cd src/tasks/sep/126-U21-giwa-sepolia

TENDERLY_GAS=10000000 SIGNATURES=0x... just approve DunamuUpgradeSafe
TENDERLY_GAS=10000000 SIGNATURES=0x... just approve GIWASecurityCouncil
TENDERLY_GAS=10000000 just execute
```

### Task State Changes

Tenderly lists the contracts below and nothing else, on either signing path. Chain addresses
are the registry entries in [addresses.json](https://github.com/ethereum-optimism/superchain-registry/blob/308e08f7a0508e46c28686c9538fec39985b73c6/superchain/extra/addresses/addresses.json);
storage slots follow the `op-contracts/v9.0.0` storage layout snapshots.

#### Task Transfers

- **From:** `0x956962C34687A954e611A83619ABaA37Ce6bC78A` (OptimismPortalProxy)
- **To:** `0x7E3eFCDC2CccfA6aC0DBD29Da74003C693cd2CbC` (new ETHLockbox proxy)
- **Value:** the portal's whole ETH balance (`130190007972444890200481` wei at simulation time,
  ~130,190 ETH; the exact value is the balance at execution).

#### `0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d` (GIWA SuperchainConfig)

- ERC-1967 implementation `0x5570b1f2b97B1E35b5C6f9Ee76f6cf02c9917504` (2.4.3) →
  `0xA303a644cfbC0c34f6a9dBEaFdebA4C967EA01e7` (2.5.0), written by `upgradeSuperchain`.

#### `0x8352825bA56C32d816Dd906Ad4A392B5BC9eC984` (SystemConfigProxy)

- ERC-1967 implementation `0x670b850A235A6fA98cD7a195eB139D0277E471fA` (4.0.0) →
  `0xADe27248542c0F3E89b49e4eB76155e267F14377` (4.3.0).
- `isFeatureEnabled[ETH_LOCKBOX]` (slot 109 mapping,
  `0x58e88e949bd180ff86d6c072735c3d8d5a05a543c16130176ec0bc0adf3fd806`) false → true.
- Recorded OPCM slot `0x99f45962df4bc30de8d4c3c6d1ffc0f100edce16e80c7a5768b6d55ca463ff42`
  (`keccak256("systemconfig.opcm") - 1`) `0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca` (8.0.1) →
  `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc` (9.0.3).

#### `0x956962C34687A954e611A83619ABaA37Ce6bC78A` (OptimismPortalProxy)

- ERC-1967 implementation `0x1005217ad392DC64CEf501FA1777A27D42166748` (5.8.0) →
  `0xb20B23af6071405C37dDDA0C0640e8eBb7899645` (6.1.0).
- Slot `0x3f` `ethLockbox` zero → `0x7E3eFCDC2CccfA6aC0DBD29Da74003C693cd2CbC`.
- ETH balance → 0 (see [Task Transfers](#task-transfers)).

#### `0x7E3eFCDC2CccfA6aC0DBD29Da74003C693cd2CbC` (ETHLockbox proxy, created)

Deployed with CREATE2 from the ProxyAdminOwner context (salt =
`keccak256(abi.encode(91342, saltMixer, "ETHLockbox"))`), so the address is fixed.

- ERC-1967 implementation zero → `0xDF75E6b07E98873E36BA5c05508F80c1454e0aFe` (ETHLockbox 2.0.0).
- ERC-1967 admin zero → `0x6AdB900DC56F7028D5E7943638897C8103cf0da5` (GIWA L1 ProxyAdmin).
- Slot `0x00` `_initialized` 0 → 1.
- Slot `0x03` `superchainConfig` zero → `0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d`.
- `authorizedPortals[OptimismPortalProxy]` (slot 1 mapping,
  `0x6eeeb8100bc802da9c6dd3efcf89663298203652c4fd15923ae44c07c1d80092`) false → true.
- ETH balance 0 → the portal's balance.

#### `0x6DaB826f3cF6932FB8614D00442612834873d61d` (AnchorStateRegistryProxy)

- ERC-1967 implementation `0x8F40Cc98D694AB986F026C5383A181FCc9B6B281` (3.9.0) →
  `0x2b27299C577d4720100e2735b652444DcEa652D0` (4.0.0).
- Slot `0x06` packs `respectedGameType` (offset 0, 5, unchanged), `retirementTimestamp`
  (offset 4, `0x69142ed8` = 1762930392, unchanged) and the new 4.0.0 `ethLockbox` field (offset
  12) zero → `0x7E3eFCDC2CccfA6aC0DBD29Da74003C693cd2CbC`. The anchor is unchanged.

#### `0x11adA074A88066119DC95e9eFE706736a82233B2` (DelayedWETH proxy)

The DelayedWETH of the retired PERMISSIONED_CANNON game, not in the registry (the simulation
prints "Target address not found in superchain-registry" for it). Balance 0.

- ERC-1967 implementation `0xE440CC08A71694C8229323803F59024E3144630e` (1.5.1) →
  `0xF024e96317907C3b8d8CB346B9FD9034c8640e15` (2.0.0).
- Slot `0x05` `ethLockbox` zero → `0x7E3eFCDC2CccfA6aC0DBD29Da74003C693cd2CbC` (its pause
  identifier in 2.0.0).

#### `0xfb81df377572C9907119Ee087dDcb1Fae3fD752C` (AddressManager)

- `addresses[keccak256("OVM_L1CrossDomainMessenger")]` (slot 1 mapping,
  `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`)
  `0x59d497530b00062f40950ba8eab88868bf7f86f0` (L1CrossDomainMessenger 2.11.1) →
  `0x7d4ec7fb1a1b9e6d61c04d5e21e3d68cff639448` (2.13.0). The messenger proxy itself is a
  `ResolvedDelegateProxy` and has no storage change.

#### `0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E` (GIWA Sepolia ProxyAdminOwner, 2-of-2 safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...0e` (14) → **After:** `0x...0f` (15)
  - **Summary:** nonce increment of the safe executing the task. The before-value is the
    nonce state override in [config.toml](./config.toml).
- **Key (DunamuUpgradeSafe path):** `0xe73f3c0fca9b630af061893518a14ceeb38105bb50c028ebc8b14dfde39ba7c3`
- **Key (GIWASecurityCouncil path):** `0x47da5215539a20b9f79d844988f156823695c8561069d0f7db7654c3365eee6e`
  - **Before:** `0x00...00` → **After:** `0x00...01`
  - **Summary:** `approvedHashes[<child safe>][<root safe tx hash>] = 1`, the child safe's
    approval of the task.

##### `0x3d58888b6903B87bD030b93F6FD37cb843b92DB7` (DunamuUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...02` (2) → **After:** `0x...03` (3)
  - **Summary:** nonce increment of the approving child safe.

##### `0x37FF75B6545F0747b21c43EEB95744b791d1bf1C` (GIWASecurityCouncil)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `0x...03` (3) → **After:** `0x...04` (4)
  - **Summary:** nonce increment of the approving child safe.

Not listed: the DisputeGameFactory (implementation 1.6.1 and the SUPER_PERMISSIONED game
implementation, args and bond are already the v9 values), the L1StandardBridge, L1ERC721Bridge
and OptimismMintableERC20Factory proxies (implementations unchanged between v8.0.0 and v9.0.0).
Tenderly also shows `Nonce N → N+1` (no storage key) on the account used as the simulation's
sender. That is its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
SC=0x8352825bA56C32d816Dd906Ad4A392B5BC9eC984; P=0x956962C34687A954e611A83619ABaA37Ce6bC78A
LB=0x7E3eFCDC2CccfA6aC0DBD29Da74003C693cd2CbC; ASR=0x6DaB826f3cF6932FB8614D00442612834873d61d
DGF=0x37347caB2afaa49B776372279143D71ad1f354F6

cast call $SC "version()(string)" -r $RPC                                # 4.3.0
cast call $SC "lastUsedOPCMVersion()(string)" -r $RPC                    # 9.0.3
cast call $SC "isFeatureEnabled(bytes32)(bool)" $(cast format-bytes32-string ETH_LOCKBOX) -r $RPC   # true
cast call $P "version()(string)" -r $RPC                                 # 6.1.0
cast call $P "ethLockbox()(address)" -r $RPC                             # $LB
cast balance $P -r $RPC                                                  # 0
cast balance $LB -r $RPC                                                 # the portal's balance before execution
cast call $LB "authorizedPortals(address)(bool)" $P -r $RPC             # true
cast call $P "paused()(bool)" -r $RPC                                    # false
cast call $ASR "version()(string)" -r $RPC                               # 4.0.0
cast call $ASR "respectedGameType()(uint32)" -r $RPC                     # 5
cast call $DGF "gameImpls(uint32)(address)" 5 -r $RPC                    # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691
cast call $DGF "gameArgs(uint32)(bytes)" 5 -r $RPC                       # 0x6dab826f…d61d032d5bd4…097c
cast call 0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d "version()(string)" -r $RPC   # 2.5.0
cast call 0x23ce19ED800fbbC964B9350b01B9113a8508D3F1 "version()(string)" -r $RPC   # 2.13.0 (L1CrossDomainMessenger)

# Unchanged: owners and guardian
cast call $DGF "owner()(address)" -r $RPC                                          # 0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E
cast call $SC "owner()(address)" -r $RPC                                           # 0x3d58888b6903B87bD030b93F6FD37cb843b92DB7
cast call 0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d "guardian()(address)" -r $RPC # 0xb033baF85ad00af475154a15c35FC00eda6f98A0
```
