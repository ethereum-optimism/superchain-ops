# Validation — 103-gas-limit-ink-sep (Ink Sepolia)

Validate the inputs and resulting state of the Karst gas-limit reset for Ink Sepolia.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first.
>
> ### SystemConfigOwner (OPE Safe): `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`
>
> - Safe Transaction Hash: `0xdf5d0ff78cb610d1dccc283a7614b908812f638df261aa21e81b834528cc3523`
> - Domain Hash: `0xe84ad8db37faa1651b140c17c70e4c48eaa47a635e0db097ddf4ce1cc14b9ecb`
> - Message Hash: `0xf4fddea105e1f0287eb83015219ba617495b1c68b85b52c0a0fc968d3c9bad57`

## Task Calldata

The call targets the Ink Sepolia SystemConfig
[`0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml).

### `SystemConfig.setGasLimit(uint64 _gasLimit)` — `_gasLimit = 30000000`

```bash
cast calldata "setGasLimit(uint64)" 30000000
# 0xb40a817c0000000000000000000000000000000000000000000000000000000001c9c380
```

This call is wrapped in a `Multicall3DelegateCall.aggregate3Value` and executed by the root
safe. The full aggregated calldata is printed by `just simulate-stack` and shown in the
Tenderly simulation.

## State Changes

Ink Sepolia already has `gasLimit = 30000000` on chain, so the storage value is re-set to
its current value — there is no net change to the SystemConfig storage. The mitigation works
via the re-emitted `ConfigUpdate` event, not a storage change.

- `0x05C993e60179f28bF649a2Bb5b00b5F4283bD525` (SystemConfig): no net storage change
  (`gasLimit` stays 30000000).
- `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (OPE SystemConfigOwner Safe): nonce
  (slot `0x05`) increments by 1.

No other state changes (besides the Tenderly sender nonce). Verify in Tenderly that only
these contracts/slots appear.
