# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonces in [config.toml](./config.toml) (L1PAO 49, FoundationUpgradeSafe 81,
SecurityCouncil 76, i.e. after eth/082 and eth/083 execute) and move only if those nonces
move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `TODO`
> - Message Hash: `TODO`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `TODO`
> - Message Hash: `TODO`

Safe transaction hash (root safe): `TODO`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/084-U21-op-ink-soneium-uni
just simulate-stack eth 084-U21-op-ink-soneium-uni council   # or foundation
```

Check:

1. The domain and message hashes printed to the terminal match the ones for your safe at the
   top of this file.
2. In the Tenderly link printed by the simulation: paste the
   [task calldata](#task-calldata) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes),
   and nothing else.
3. The decoded `upgrade` inputs show `startingRespectedGameType = 9` with the prestate
   `0x03b985a286da46ca88c0a965a53942daade9ffe1ae6b854a8f2d083df1cfaf59` for OP Mainnet, Ink
   and Unichain, `startingRespectedGameType = 5` with game 9 disabled for Soneium, and
   `PermittedProxyDeployment = ETHLockbox` on each.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers: the raw
calldata and its breakdown, the pre-execution checks and execution commands, the expected
state changes and the post-execution checks. Signers only need the two sections above.

### Task Calldata

```
TODO
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3` from the L1PAO (selector
`0x82ad56cb`) containing **5** delegatecalls, all to the OPCM
`0x2d91e6f2bcf6cd1df90e1faf9714e18705ea331f` with `allowFailure = false`:

| # | Function | Selector | Payload |
|---|---|---|---|
| 1 | `upgradeSuperchain((address,(string,bytes)[]))` | `0x86fe1c66` | SuperchainConfig `0x95703e0982140D16f8ebA6d158FccEde42f04a4C`, no extra instructions |
| 2 | `upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))` | `0x8a847e2e` | OP Mainnet |
| 3 | `upgrade(...)` | `0x8a847e2e` | Ink |
| 4 | `upgrade(...)` | `0x8a847e2e` | Soneium |
| 5 | `upgrade(...)` | `0x8a847e2e` | Unichain |

Each `upgrade` call carries the chain's `SystemConfigProxy`, six game configs in the fixed
order 0, 1, 8, 5, 9, 10 and two extra instructions: `overrides.cfg.startingRespectedGameType`
(ABI-encoded `9`, or `5` for Soneium) and `PermittedProxyDeployment` (raw `ETHLockbox`; a
no-op here, every chain already has a lockbox). Game types 0, 1, 8 and 10 are disabled
(`enabled = false`, zero bond, empty args). Game 5 is enabled with the chain's registry
`Proposer` as its only argument and no bond; game 9 is enabled with the prestate and a
0.08 ETH bond on OP Mainnet, Ink and Unichain, and disabled on Soneium.

| Chain | SystemConfigProxy | Game 5 args (proposer) | Game 9 |
|---|---|---|---|
| OP Mainnet | `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` | `TODO` | enabled |
| Ink | `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` | `TODO` | enabled |
| Soneium | `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` | `TODO` | disabled |
| Unichain | `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` | `TODO` | enabled |

To verify the fingerprint of call 1:

```bash
cast calldata "upgradeSuperchain((address,(string,bytes)[]))" "(0x95703e0982140D16f8ebA6d158FccEde42f04a4C,[])"
```

Every byte not belonging to the payloads above is standard ABI encoding. The OPCM address
appears exactly 5 times (as target), the `upgrade` selector `8a847e2e` exactly 4 times and the
prestate exactly 3 times (not for Soneium). To decode the calldata back into the five calls and
each `upgrade` input:

```bash
cast calldata-decode "aggregate3((address,bool,bytes)[])" <task calldata>
# then, for each 0x8a847e2e... payload returned above:
cast calldata-decode "upgrade((address,(bool,uint256,uint32,bytes)[],(string,bytes)[]))" <payload>
```

### Pre-execution checks and execution

Before approving, confirm the live state still matches the assumptions in
[config.toml](./config.toml):

```bash
RPC=https://ethereum-rpc.publicnode.com

# eth/082 and eth/083 must have executed. Nonces must equal the pins (49 / 81 / 76); if not,
# re-simulate and regenerate the hashes.
cast call 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A "nonce()(uint256)" -r $RPC   # L1PAO
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # FoundationUpgradeSafe
cast call 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 "nonce()(uint256)" -r $RPC   # SecurityCouncil

# Every chain must still be on the v8 OPCM (8.0.1) and have its lockbox wired.
for sc in 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6; do
  cast call $sc "lastUsedOPCMVersion()(string)" -r $RPC   # 8.0.1
  cast call $(cast call $sc "optimismPortal()(address)" -r $RPC) "ethLockbox()(address)" -r $RPC   # non-zero
done
```

Then approve once per child safe with the collected signatures and execute:

```bash
cd src/tasks/eth/084-U21-op-ink-soneium-uni

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

### Task State Changes

TODO: regenerate from the Tenderly state diff once the hashes are final. Expected, on each
chain: `SystemConfigProxy` (implementation 4.0.0 → 4.3.0, `lastUsedOPCMVersion` 8.0.1 → 9.0.3),
`OptimismPortalProxy` (implementation 5.8.0 → 6.1.0, re-initialized with the same
AnchorStateRegistry and ETHLockbox), `L1CrossDomainMessengerProxy` (implementation 2.11.1 →
2.13.0), `AnchorStateRegistryProxy` (implementation 3.9.0 → 4.0.0, re-initialized with the
carried-forward anchor and the chain's respected game type), `DisputeGameFactoryProxy` (game 5
args re-set on every chain, game 9 args re-set on OP Mainnet, Ink and Unichain; implementation
unchanged), the DelayedWETH proxy (implementation 1.5.1 → 2.0.0) and `EthLockboxProxy`
(implementation 1.3.1 → 2.0.0, re-initialized with the same portal). `L1StandardBridgeProxy`,
`L1ERC721BridgeProxy` and `OptimismMintableERC20FactoryProxy` keep their implementations
(unchanged between v8.0.0 and v9.0.0). Shared: `SuperchainConfig`
`0x95703e0982140D16f8ebA6d158FccEde42f04a4C` (implementation 2.4.3 → 2.5.0), the L1PAO nonce
and `approvedHashes` entry, the approving child safe's nonce, and (council path) the
SecurityCouncil LivenessGuard `lastLive` simulation artifact.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

for sc in 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 0xc407398d063f942feBbcC6F80a156b47F3f1BDA6; do
  echo "== $sc"
  cast call $sc "version()(string)" -r $RPC                     # 4.3.0
  cast call $sc "lastUsedOPCMVersion()(string)" -r $RPC         # 9.0.3
  portal=$(cast call $sc "optimismPortal()(address)" -r $RPC)
  cast call $portal "version()(string)" -r $RPC                 # 6.1.0
  asr=$(cast call $portal "anchorStateRegistry()(address)" -r $RPC)
  cast call $asr "respectedGameType()(uint32)" -r $RPC          # 9 (5 on Soneium)
  dgf=$(cast call $portal "disputeGameFactory()(address)" -r $RPC)
  cast call $dgf "gameImpls(uint32)(address)" 9 -r $RPC         # non-zero (zero on Soneium)
  cast call $dgf "initBonds(uint32)(uint256)" 9 -r $RPC         # 80000000000000000 (0 on Soneium)
done

cast call 0x95703e0982140D16f8ebA6d158FccEde42f04a4C "version()(string)" -r $RPC   # 2.5.0
```
