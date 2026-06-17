# Validation — 059-gas-params-soneium (Soneium, Mainnet)

Validate the inputs and resulting state of the Karst gas-limit reset for Soneium.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first.
>
> ### SystemConfigOwner (Soneium): `0x509182eC226b3B71D36A3255A80EF0b1A9D43033`
>
> - Safe Transaction Hash: `0xbc3e7418379763e87eccc70aa564097089f6a0bd39163caa5552a8621b096964`
> - Domain Hash: `0xfec9c20e9a1f1dc2de8e49ee266be73bafbca115021f1de122ef95419b35297d`
> - Message Hash: `0x8512fec8e0863140e57e8b64618265361b9b5b26f81b5a3e05cd11717013a306`

## Task Calldata

Both calls target the Soneium SystemConfig
[`0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml).

- `setGasLimit(uint64)` `40000000` → `0xb40a817c0000000000000000000000000000000000000000000000000000000002625a00`
- `setEIP1559Params(uint32,uint32)` `250, 10` → `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa000000000000000000000000000000000000000000000000000000000000000a`

## State Changes

Soneium already has these exact gas params on chain, so the values are **re-set to their
current values** — there is no net change to the SystemConfig storage. The mitigation works
via the re-emitted `ConfigUpdate` event.

- `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (SystemConfig): no net storage change
  (`gasLimit` stays 40000000; `eip1559Denominator` stays 250; `eip1559Elasticity` stays 10).
- `0x509182eC226b3B71D36A3255A80EF0b1A9D43033` (SystemConfigOwner): nonce (slot `0x05`) +1.

No other state changes. Verify in Tenderly that only these contracts/slots appear.
