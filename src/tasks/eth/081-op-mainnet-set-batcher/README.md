# 081-op-mainnet-set-batcher

Status: [DRAFT, NOT READY TO SIGN]

## Objective

OP Mainnet OP Enterprise key rotation, part 1 of 3: sets the OP Enterprise batcher on the OP Mainnet `SystemConfigProxy`, signed by the [FoundationUpgradeSafe](../../../addresses.toml#L6).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| OP Mainnet | 10 | [`0x229047fed2591dbec1eF1118d64F7aF3dB9EB290`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L51) | `batcherHash()` | `0x6887246668a3b87F54DeB3b94Ba47a6f63F32985` → `0xcDF8af38e013fCC1B2D0b7D00Fb7671523D4B825` |

Batcher key source: [`op-signer` configmap](https://github.com/ethereum-optimism/k8s-netchef-prod/blob/6862432f96e9fe4891d2b728dfc38a9b3a3417e3/kustomize/op-signer/oplabs-prod-ent-mainnet-eu/mn-op-mainnet-0-op-signer/configmap.yaml#L10-L13). The unsafe block signer is rotated separately in eth/087.

## Simulation & Signing

Single-safe task. Check the output against [VALIDATION.md](./VALIDATION.md) before signing.

```bash
cd src/tasks/eth/081-op-mainnet-set-batcher

just simulate-stack eth 081-op-mainnet-set-batcher

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 081-op-mainnet-set-batcher
```
