# Validation — 103-gas-params-metal-mode-zora (Metal + Mode + Zora, Sepolia)

Validate the inputs and resulting state of the bundled Karst gas-limit reset for Metal,
Mode, and Zora Sepolia.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first (these hashes
> are computed at nonce 833).
>
> ### SystemConfigOwner (Metal + Mode + Zora): `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2`
>
> - Safe Transaction Hash: `0xb1b3122293df7a0721e760a7e849004949d09562b8684505c6b05fd48c0b6773`
> - Domain Hash: `0x5fa5f23e8066a0bc420f5a558f370b5d437030fdca8f52a91c13ca535e25a639`
> - Message Hash: `0x906a66ef53bb004f63f5bef44e40aa526aa00a53756ff014075100670f8a9dc6`

## Task Calldata

The task issues six calls (two per chain), wrapped in `Multicall3DelegateCall.aggregate3Value`.
For each chain: `setGasLimit(uint64) 30000000` → `0xb40a817c0000000000000000000000000000000000000000000000000000000001c9c380`
and `setEIP1559Params(uint32,uint32) 250, 6` → `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000006`.

Target SystemConfigs:
- Metal L2 Testnet: [`0x5D63A8Dc2737cE771aa4a6510D063b6Ba2c4f6F2`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/metal.toml)
- Mode Testnet: [`0x15cd4f6e0CE3B4832B33cB9c6f6Fe6fc246754c2`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/mode.toml)
- Zora Sepolia Testnet: [`0xB54c7BFC223058773CF9b739cC5bd4095184Fb08`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/zora.toml)

## State Changes

All three chains have `gasLimit = 30000000` already and have never set EIP-1559 params on
chain (getters return 0). The task re-sets the gas limit (no net change) and writes the
genesis/Canyon EIP-1559 params explicitly.

- SystemConfigs `0x5D63…f6F2` (Metal), `0x15cd…54c2` (Mode), `0xB54c…Fb08` (Zora):
  - `gasLimit`: stays 30000000 (no net change).
  - `eip1559Denominator`: 0 → 250; `eip1559Elasticity`: 0 → 6 (shared storage slot `0x6a`) —
    a behavioral no-op (the chains already run on denominator 250 / elasticity 6 post-Canyon).
- `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` (SystemConfigOwner): nonce (slot `0x05`) +1.

No other state changes. Verify in Tenderly that only these contracts/slots appear.
