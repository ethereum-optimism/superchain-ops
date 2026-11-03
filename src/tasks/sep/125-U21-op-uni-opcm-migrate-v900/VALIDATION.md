# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

> [!NOTE]
> Hashes and calldata come from the stacked simulation on task 115 run on 2026-11-03 with the
> super root in [config.toml](./config.toml). They change whenever the super root is refreshed
> before signing; regenerate them from the stacked simulation at that point. The per-slot state
> changes are still to be reviewed in Tenderly.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonces in [config.toml](./config.toml) (L1PAO 60, FoundationUpgradeSafe 83,
SecurityCouncil 74, one above task 115's pins) and move only if those nonces move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Upgrade Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0xe28fbbcb4e8ff2aab58b758c060fd036a0151f4a4d4d935366fbf2d55772bb65`
>
> ### Security Council (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x6564c78028c7e92e4b3d73c0a113c64e71ea838b1608889b60826d9e399b98d3`

Safe transaction hash (root safe):
`0xf2f4f03de7eba47295c8937e9940977fbdef9f1712b256dad98eb0402259126e`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/125-U21-op-uni-opcm-migrate-v900
just simulate-stack sep 125-U21-op-uni-opcm-migrate-v900 council   # or foundation
```

Check:

1. The domain and message hashes printed to the terminal match the ones for your safe at the
   top of this file.
2. In the Tenderly link printed by the simulation: paste the
   [task calldata](#task-calldata) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes),
   and nothing else.
3. The decoded `migrate` input lists the two SystemConfigs in the order Unichain Sepolia
   (`0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D`), OP Sepolia
   (`0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`), the proposer
   `0x9884c33c65111da7bbed0e63cd2392f503b135f5`, the super root and timestamp from
   [config.toml](./config.toml), `startingRespectedGameType = 9`, and game configs 5
   (proposer, no bond) and 9 (prestate `0x03b985…faf59`, 0.08 ETH).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers: the raw
calldata and its breakdown, the pre-execution checks and execution commands, the expected
state changes and the post-execution checks. Signers only need the two sections above.

### Task Calldata

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000160f0fe4dc1b3f4026687e8dd4b7f800879939cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000304ba55287c000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000100382d95f5ca3fa7d44971c9f0b39b0f5b6e931c81b7d5d4ceac4e2e73aa829a08000000000000000000000000000000000000000000000000000000006aea556a00000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000002000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000200000000000000000000000009884c33c65111da7bbed0e63cd2392f503b135f50000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000011c37937e08000000000000000000000000000000000000000000000000000000000000000000090000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002003b985a286da46ca88c0a965a53942daade9ffe1ae6b854a8f2d083df1cfaf5900000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3` from the L1PAO (selector
`0x82ad56cb`) containing **1** delegatecall to the OPCM
`0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc` with `allowFailure = false`:

| # | Function | Selector | Payload |
|---|---|---|---|
| 1 | `migrate((address[],(bool,uint256,uint32,bytes)[],(bytes32,uint256),uint32))` | `0xba55287c` | both SystemConfigs, two game configs, the super root, game type 9 |

To decode it:

```bash
cast calldata-decode "aggregate3((address,bool,bytes)[])" <task calldata>
cast calldata-decode "migrate((address[],(bool,uint256,uint32,bytes)[],(bytes32,uint256),uint32))" <0xba55287c... payload>
```

### Pre-execution checks and execution

Before executing, confirm task 115 has executed on both chains and the live nonces still match
the pins in [config.toml](./config.toml); if not, re-simulate and regenerate the hashes.
Refresh the super root with `check-super-root` if it is older than the chains' current anchors.

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
cast call 0x1Eb2fFc903729a0F03966B917003800b145F56E2 "nonce()(uint256)" -r $RPC   # 60
cast call 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D "lastUsedOPCMVersion()(string)" -r $RPC   # 9.0.3
cast call 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "lastUsedOPCMVersion()(string)" -r $RPC   # 9.0.3

cd ~/optimism && go run ./op-chain-ops/cmd/check-super-root \
  --rpc-endpoints https://sepolia.unichain.org,https://sepolia.optimism.io
```

Then execute with the collected signatures. sep/121, the same call on Jacob's devnet pair,
cost 17.0M gas on Sepolia against a ~4.2M local estimate and needed
`--gas-estimate-multiplier 500`; `TENDERLY_GAS` in [.env](./.env) is set to 30M for the
same reason.

```bash
cd src/tasks/sep/125-U21-op-uni-opcm-migrate-v900

SIGNATURES=0x... just execute-stack sep 125-U21-op-uni-opcm-migrate-v900 council
```

### Task State Changes

Per-slot Tenderly review still to do; descriptive until then. Expected: three
new proxies (shared ETHLockbox, DisputeGameFactory, AnchorStateRegistry) under Unichain
Sepolia's ProxyAdmin; per chain the `SystemConfigProxy` (`INTEROP` feature, `delayedWETH` to
the shared one), `OptimismPortalProxy` (`anchorStateRegistry`, `ethLockbox` to the shared
ones), the chain's old `ETHLockbox` (balance 0), old `DisputeGameFactoryProxy` (games 5 and 9
cleared), old `AnchorStateRegistryProxy` and DelayedWETH (re-pointed at the shared lockbox);
plus the three Safe nonces.

### Post-execution checks

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com
for SC in 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538; do
  P=$(cast call $SC "optimismPortal()(address)" -r $RPC)
  cast call $P "ethLockbox()(address)" -r $RPC             # the same shared lockbox for both
  cast call $P "anchorStateRegistry()(address)" -r $RPC    # the same shared ASR for both
  cast call $P "disputeGameFactory()(address)" -r $RPC     # the same shared DGF for both
  cast call $P "respectedGameType()(uint32)" -r $RPC       # 9
done
```
