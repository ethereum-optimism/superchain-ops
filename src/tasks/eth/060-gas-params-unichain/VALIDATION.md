# Validation — 060-gas-params-unichain (Unichain, Mainnet)

Validate the inputs and resulting state of the Karst gas-limit reset for Unichain.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first.
>
> ### SystemConfigOwner (Unichain): `0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1`
>
> - Safe Transaction Hash: `0xdfbfea594ad7ca499d70a292b42a78b5ee0632afb9ac837bf6ca6ad0b9fe0dbc`
> - Domain Hash: `0xbea15583997db2831ec7dea58be331771c073bea8444c2b48ded663621f2260e`
> - Message Hash: `0x5156f00617db7643144c0f6c19cded92f33622f430e2d817a2ece507925288ab`

## Task Calldata

Both calls target the Unichain SystemConfig
[`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml).

- `setGasLimit(uint64)` `60000000` → `0xb40a817c0000000000000000000000000000000000000000000000000000000003938700`
- `setEIP1559Params(uint32,uint32)` `250, 12` → `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa000000000000000000000000000000000000000000000000000000000000000c`

## State Changes

Unichain already has these exact gas params on chain, so the values are **re-set to their
current values** — there is no net change to the SystemConfig storage. The mitigation works
via the re-emitted `ConfigUpdate` event.

- `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` (SystemConfig): no net storage change
  (`gasLimit` stays 60000000; `eip1559Denominator` stays 250; `eip1559Elasticity` stays 12).
- `0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1` (SystemConfigOwner): nonce (slot `0x05`) +1.

No other state changes. Verify in Tenderly that only these contracts/slots appear.
