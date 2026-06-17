# Validation — 055-gas-params-op (OP Mainnet)

Validate the inputs and resulting state of the Karst gas-limit reset for OP Mainnet.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. The FUS nonce override is set to 59 (post-U19); re-verify the live
> nonce — if it differs, these hashes will differ.
>
> ### SystemConfigOwner = FoundationUpgradeSafe: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
>
> - Safe Transaction Hash: `0xa34f22c1cc8e2cba986c8569916c4b25e0124494b5737ed123655086f01c4165`
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x508714872ea03af8ac8d411a068cba49fc626e3e1820ea5f7eadf7491543950d`

## Task Calldata

Both calls target the OP Mainnet SystemConfig
[`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml).

### `SystemConfig.setGasLimit(uint64 _gasLimit)` — `_gasLimit = 40000000`
```bash
cast calldata "setGasLimit(uint64)" 40000000
# 0xb40a817c0000000000000000000000000000000000000000000000000000000002625a00
```

### `SystemConfig.setEIP1559Params(uint32 _denominator, uint32 _elasticity)` — `250, 2`
```bash
cast calldata "setEIP1559Params(uint32,uint32)" 250 2
# 0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000002
```

These two calls are wrapped in a `Multicall3DelegateCall.aggregate3Value` and executed by
the root safe. The full aggregated calldata is printed by `just simulate-stack` and shown in
the Tenderly simulation.

## State Changes

OP Mainnet already has these exact gas params on chain, so the values are **re-set to their
current values** — there is no net change to the SystemConfig storage. The mitigation works
via the re-emitted `ConfigUpdate` event, not a storage change.

- `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (SystemConfig): no net storage change
  (`gasLimit` stays 40000000; `eip1559Denominator` stays 250; `eip1559Elasticity` stays 2).
- `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe): nonce (slot `0x05`)
  increments by 1.

No other state changes (besides the Tenderly sender nonce). Verify in Tenderly that no
unexpected contracts or slots appear in the diff.
