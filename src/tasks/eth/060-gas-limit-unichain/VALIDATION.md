# Validation — 060-gas-limit-unichain (Unichain, Mainnet)

Validate the inputs and resulting state of the Karst gas-limit reset for Unichain.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first.
>
> ### SystemConfigOwner (Unichain): `0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1`
>
> - Safe Transaction Hash: `0xd2216bf4cd503db35c94904eb17ea673a8575d57fa0350a0b497382297b5bcb3`
> - Domain Hash: `0xbea15583997db2831ec7dea58be331771c073bea8444c2b48ded663621f2260e`
> - Message Hash: `0x75dff3d44a962650393d5db7f286f88530d245b8937808862c9d83b55db04f29`

## Task Calldata

The call targets the Unichain SystemConfig
[`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml).

### `SystemConfig.setGasLimit(uint64 _gasLimit)` — `_gasLimit = 60000000`

```bash
cast calldata "setGasLimit(uint64)" 60000000
# 0xb40a817c0000000000000000000000000000000000000000000000000000000003938700
```

This call is wrapped in a `Multicall3DelegateCall.aggregate3Value` and executed by the root
safe. The full aggregated calldata is printed by `just simulate-stack` and shown in the
Tenderly simulation.

## State Changes

Unichain already has `gasLimit = 60000000` on chain, so the storage value is re-set to
its current value — there is no net change to the SystemConfig storage. The mitigation works
via the re-emitted `ConfigUpdate` event, not a storage change.

- `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` (SystemConfig): no net storage change
  (`gasLimit` stays 60000000).
- `0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1` (SystemConfigOwner): nonce (slot `0x05`)
  increments by 1.

No other state changes. Verify in Tenderly that only these contracts/slots appear.
