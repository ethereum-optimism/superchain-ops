# Validation — 059-gas-limit-op (OP Mainnet)

Validate the inputs and resulting state of the Karst gas-limit reset for OP Mainnet.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. The FUS nonce override is set to 61 (post-055/056 rotation);
> re-verify the live nonce — if it differs, these hashes will differ.
>
> ### SystemConfigOwner = FoundationUpgradeSafe: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
>
> - Safe Transaction Hash: `0x84bc66bb2f7c6c7d87d6c49a957bc74356ac97299aabbad48eebc6ef10e91f2d`
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x608b874772357d27dd8d7ea67561c723885fcd4fc2c3517825175c93d39a989a`

## Task Calldata

The call targets the OP Mainnet SystemConfig
[`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml).

### `SystemConfig.setGasLimit(uint64 _gasLimit)` — `_gasLimit = 40000000`

```bash
cast calldata "setGasLimit(uint64)" 40000000
# 0xb40a817c0000000000000000000000000000000000000000000000000000000002625a00
```

This call is wrapped in a `Multicall3DelegateCall.aggregate3Value` and executed by the root
safe. The full aggregated calldata is printed by `just simulate-stack` and shown in the
Tenderly simulation.

## State Changes

OP Mainnet already has `gasLimit = 40000000` on chain, so the storage value is re-set to
its current value — there is no net change to the SystemConfig storage. The mitigation works
via the re-emitted `ConfigUpdate` event, not a storage change.

- `0x229047fed2591dbec1eF1118d64F7aF3dB9EB290` (SystemConfig): no net storage change
  (`gasLimit` stays 40000000).
- `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe): nonce (slot `0x05`)
  increments by 1.

No other state changes (besides the Tenderly sender nonce). Verify in Tenderly that no
unexpected contracts or slots appear in the diff.
