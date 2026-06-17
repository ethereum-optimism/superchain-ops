# Validation — 105-gas-params-unichain (Unichain Sepolia)

Validate the inputs and resulting state of the Karst gas-limit reset for Unichain Sepolia.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first.
>
> ### SystemConfigOwner (Unichain Sepolia): `0x325B777f8F0bC71fb6b617Bc41A8703CA7077891`
>
> - Safe Transaction Hash: `0xc7b7b6e67b899edc837a2b3c1757f3af4e5b8388da4d95352d07ebbc1011560a`
> - Domain Hash: `0x188054e16f4c64a2629fcef891da5d49e9d67d03d6fbedc906cc4f1de70ad8f8`
> - Message Hash: `0xa19506326c27155e2a72e4dbb5c8c8b24cba4f686a852fd146dc6982f893b735`

## Task Calldata

Both calls target the Unichain Sepolia SystemConfig
[`0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml).

- `setGasLimit(uint64)` `60000000` → `0xb40a817c0000000000000000000000000000000000000000000000000000000003938700`
- `setEIP1559Params(uint32,uint32)` `50, 12` → `0xc0fd4b410000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000c`

## State Changes

Unichain Sepolia already has these exact gas params on chain (note: `eip1559Denominator` is
**50**, not 250), so the values are **re-set to their current values** — there is no net
change to the SystemConfig storage. The mitigation works via the re-emitted `ConfigUpdate`
event.

- `0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D` (SystemConfig): no net storage change
  (`gasLimit` stays 60000000; `eip1559Denominator` stays 50; `eip1559Elasticity` stays 12).
- `0x325B777f8F0bC71fb6b617Bc41A8703CA7077891` (SystemConfigOwner): nonce (slot `0x05`) +1.

No other state changes. Verify in Tenderly that only these contracts/slots appear.
