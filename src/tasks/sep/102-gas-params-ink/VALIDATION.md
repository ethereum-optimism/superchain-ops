# Validation — 102-gas-params-ink (Ink Sepolia)

Validate the inputs and resulting state of the Karst gas-limit reset for Ink Sepolia.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first.
>
> ### SystemConfigOwner (Ink Sepolia): `0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`
>
> - Safe Transaction Hash: `0x492666692475879559d5820343abe8ea888fcca761f8848a7454aa4da46b79f8`
> - Domain Hash: `0xc06101531f2357f3ba430a815de8fdd45dd0ddabefc271fa233980142b45a43e`
> - Message Hash: `0xd96da5c591dc94429957508c6a882f62404a5543cedecf471afd9cdda6ed50e9`

## Task Calldata

Both calls target the Ink Sepolia SystemConfig
[`0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml).

- `setGasLimit(uint64)` `30000000` → `0xb40a817c0000000000000000000000000000000000000000000000000000000001c9c380`
- `setEIP1559Params(uint32,uint32)` `250, 6` → `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000006`

## State Changes

Ink Sepolia has `gasLimit = 30000000` already and has never set EIP-1559 params on chain
(getters return 0). The task re-sets the gas limit (no net change) and writes the
genesis/Canyon EIP-1559 params explicitly.

- SystemConfig `0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`:
  - `gasLimit`: stays 30000000 (no net change).
  - `eip1559Denominator`: 0 → 250; `eip1559Elasticity`: 0 → 6 (shared storage slot `0x6a`) —
    a behavioral no-op (Ink already runs on denominator 250 / elasticity 6 post-Canyon).
- `0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb` (SystemConfigOwner): nonce (slot `0x05`) +1.

No other state changes. Verify in Tenderly that only these contracts/slots appear.
