# Validation — 060-gas-limit-soneium (Soneium)

Validate the inputs and resulting state of the Karst gas-limit reset for Soneium.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. The SystemConfigOwner nonce override is set to 12; re-verify the
> live nonce — if it differs, these hashes will differ.
>
> ```bash
> cast call 0x509182eC226b3B71D36A3255A80EF0b1A9D43033 "nonce()(uint256)" --rpc-url mainnet
> ```
>
> ### SystemConfigOwner = Soneium 3-of-6 Safe: `0x509182eC226b3B71D36A3255A80EF0b1A9D43033`
>
> - Safe Transaction Hash: `0xdfa85e8c98d2eae9dbb68ab72a21b46b716e5c4c0322b15193955514e29bf21f`
> - Domain Hash: `0xfec9c20e9a1f1dc2de8e49ee266be73bafbca115021f1de122ef95419b35297d`
> - Message Hash: `0x35a76c6159a5d47e23814a06010b26c169b2a24da6afa1a842172a9e3c5d67a7`

## Task Calldata

The call targets the Soneium SystemConfig
[`0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml).

### `SystemConfig.setGasLimit(uint64 _gasLimit)` — `_gasLimit = 40000000`

```bash
cast calldata "setGasLimit(uint64)" 40000000
# 0xb40a817c0000000000000000000000000000000000000000000000000000000002625a00
```

This call is wrapped in a `Multicall3DelegateCall.aggregate3Value` and executed by the root
safe. The full aggregated calldata is printed by `just simulate-stack` and shown in the
Tenderly simulation.

## State Changes

Soneium already has `gasLimit = 40000000` on chain, so the storage value is re-set to its
current value — there is no net change to the SystemConfig storage. The mitigation works via
the re-emitted `ConfigUpdate` event, not a storage change.

- `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (SystemConfig): no net storage change
  (`gasLimit` stays 40000000).
- `0x509182eC226b3B71D36A3255A80EF0b1A9D43033` (SystemConfigOwner Safe): nonce (slot `0x05`)
  increments by 1 (12 -> 13).

No other state changes (besides the Tenderly sender nonce). Verify in Tenderly that no
unexpected contracts or slots appear in the diff.
