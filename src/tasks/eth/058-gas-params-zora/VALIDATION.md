# Validation — 058-gas-params-zora (Zora, Mainnet)

Validate the inputs and resulting state of the Karst gas-limit reset for Zora.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first.
>
> ### SystemConfigOwner (Zora): `0xC72aE5c7cc9a332699305E29F68Be66c73b60542`
>
> - Safe Transaction Hash: `0x3a5e5fc6d8494a36a22ae854f5cfaf6ccb3c7325522da79776f2ca3666b0b5b1`
> - Domain Hash: `0x04d8b03931757beb3d5d2234a3218674c5274d5c0532403b2f9d22ee0cecb958`
> - Message Hash: `0x78a954c6a6f0bb94cf6bc64bbc1166d32d331aeeb77064e3290761428f01a19f`

## Task Calldata

Both calls target the Zora SystemConfig
[`0xA3cAB0126d5F504B071b81a3e8A2BBBF17930d86`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/zora.toml).

- `setGasLimit(uint64)` `30000000` → `0xb40a817c0000000000000000000000000000000000000000000000000000000001c9c380`
- `setEIP1559Params(uint32,uint32)` `250, 6` → `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000006`

## State Changes

Zora has `gasLimit = 30000000` already and has never set EIP-1559 params on chain (getters
return 0). The task re-sets the gas limit (no net change) and writes the genesis/Canyon
EIP-1559 params explicitly.

- SystemConfig `0xA3cAB0126d5F504B071b81a3e8A2BBBF17930d86`:
  - `gasLimit`: stays 30000000 (no net change).
  - `eip1559Denominator`: 0 → 250; `eip1559Elasticity`: 0 → 6 (shared storage slot `0x6a`) —
    a behavioral no-op (Zora already runs on denominator 250 / elasticity 6 post-Canyon).
- `0xC72aE5c7cc9a332699305E29F68Be66c73b60542` (SystemConfigOwner): nonce (slot `0x05`) +1.

No other state changes. Verify in Tenderly that only these contracts/slots appear.
