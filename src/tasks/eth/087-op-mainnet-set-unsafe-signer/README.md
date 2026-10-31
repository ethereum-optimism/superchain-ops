# 087-op-mainnet-set-unsafe-signer

Status: [DRAFT, NOT READY TO SIGN]

## Objective

OP Mainnet OP Enterprise key rotation, part 3 of 3: sets the OP Enterprise unsafe block signer on the OP Mainnet `SystemConfigProxy`, signed by the [FoundationUpgradeSafe](../../../addresses.toml#L6).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| OP Mainnet | 10 | [`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L51) | `unsafeBlockSigner()` | `0xAAAA45d9549EDA09E70937013520214382Ffc4A2` → `0x2BF56397f5cAD2e9d432c18283Acb991Ea7063C5` |

Depends on eth/081 (batcher). A standalone `just simulate` would also rotate the batcher, so sign only from `just simulate-stack`.

## Simulation & Signing

Single-safe task. Check the output against [VALIDATION.md](./VALIDATION.md) before signing.

```bash
cd src/tasks/eth/087-op-mainnet-set-unsafe-signer

just simulate-stack eth 087-op-mainnet-set-unsafe-signer

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 087-op-mainnet-set-unsafe-signer
```
