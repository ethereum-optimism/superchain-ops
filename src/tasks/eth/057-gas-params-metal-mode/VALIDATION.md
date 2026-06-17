# Validation — 057-gas-params-metal-mode (Metal L2 + Mode, Mainnet)

Validate the inputs and resulting state of the bundled Karst gas-limit reset for Metal L2
and Mode.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the hashes below match what is shown on your Ledger and in the
> `op-txverify` output. Re-verify the SystemConfigOwner Safe live nonce first.
>
> ### SystemConfigOwner (Metal + Mode): `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746`
>
> - Safe Transaction Hash: `0x11b33724d84fc997f4bbddca29bd85518202f044773ac78ac8d5aceca5aadd3e`
> - Domain Hash: `0x0f634ad56005ddbd68dc52233931a858f740b8ab706671c42b055efef561257e`
> - Message Hash: `0xbdac40dc91c0119263f1887472f7a38db9ca675151e41cf77e94b80fd403b8a5`

## Task Calldata

The task issues four calls (two per chain), wrapped in `Multicall3DelegateCall.aggregate3Value`:

### Metal L2 — SystemConfig [`0x7BD909970B0EEdcF078De6Aeff23ce571663b8aA`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/metal.toml)
- `setGasLimit(uint64)` `30000000` → `0xb40a817c0000000000000000000000000000000000000000000000000000000001c9c380`
- `setEIP1559Params(uint32,uint32)` `250, 6` → `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000006`

### Mode — SystemConfig [`0x5e6432F18Bc5d497B1Ab2288a025Fbf9D69E2221`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/mode.toml)
- `setGasLimit(uint64)` `30000000` → `0xb40a817c0000000000000000000000000000000000000000000000000000000001c9c380`
- `setEIP1559Params(uint32,uint32)` `250, 6` → `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000006`

## State Changes

Metal and Mode have `gasLimit = 30000000` already, and have never set EIP-1559 params on
chain (getters return 0). The task re-sets the gas limit (no net change) and writes the
genesis/Canyon EIP-1559 params explicitly.

- SystemConfig `0x7BD9…b8aA` (Metal) and `0x5e64…2221` (Mode):
  - `gasLimit`: stays 30000000 (no net change).
  - `eip1559Denominator`: 0 → 250; `eip1559Elasticity`: 0 → 6 (shared storage slot `0x6a`).
    This makes the implicit genesis params explicit — a behavioral no-op (the chains already
    run on denominator 250 / elasticity 6 post-Canyon).
- `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` (SystemConfigOwner): nonce (slot `0x05`) +1.

No other state changes. Verify in Tenderly that only these contracts/slots appear.
