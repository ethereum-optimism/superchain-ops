# Validation — 104-gas-params-soneium-minato (Soneium Testnet Minato, Sepolia)

Validate the inputs and resulting state of the Karst gas-limit reset for Soneium Minato.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first.
>
> ### SystemConfigOwner (Soneium Minato): `0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65`
>
> - Safe Transaction Hash: `0x1bf38b25352a4fd808c7b8dbdd9a5c8587bac37c501f6b19f1f3097d421654fe`
> - Domain Hash: `0xd5ef838177141b76f2edb19b4bb90f1d5526d11264faa809879995be7cb8a3d5`
> - Message Hash: `0xe883d6eb1dfaf2b4a26a8f51db0e14e6b22b35f387798e32d9e0b6918e5192f6`

## Task Calldata

Both calls target the Soneium Minato SystemConfig
[`0x4Ca9608Fef202216bc21D543798ec854539bAAd3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml).

- `setGasLimit(uint64)` `40000000` → `0xb40a817c0000000000000000000000000000000000000000000000000000000002625a00`
- `setEIP1559Params(uint32,uint32)` `250, 10` → `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa000000000000000000000000000000000000000000000000000000000000000a`

## State Changes

Soneium Minato already has these exact gas params on chain, so the values are **re-set to
their current values** — there is no net change to the SystemConfig storage. The mitigation
works via the re-emitted `ConfigUpdate` event.

- `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` (SystemConfig): no net storage change
  (`gasLimit` stays 40000000; `eip1559Denominator` stays 250; `eip1559Elasticity` stays 10).
- `0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65` (SystemConfigOwner): nonce (slot `0x05`) +1.

No other state changes. Verify in Tenderly that only these contracts/slots appear.
