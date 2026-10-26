# 082-op-mainnet-proposer-rotation

Status: [DRAFT, NOT READY TO SIGN]

## Objective

OP Mainnet OP Enterprise key rotation, part 1: sets the OP Enterprise proposer in the `SUPER_PERMISSIONED` (5) game args on the OP Mainnet `DisputeGameFactoryProxy`, signed by the L1PAO. The respected game type stays `SUPER_CANNON_KONA` (9), so type 5 is the Guardian fallback.

| Chain | Chain ID | DisputeGameFactoryProxy | `gameArgs(5)` proposer |
|---|---|---|---|
| OP Mainnet | 10 | [`0xe5965Ab5962eDc7477C8520243A95517CD252fA9`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L52) | `0x473300df21D047806A082244b417f96b32f13A33` → `0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0` |

Proposer key source: [`op-signer` configmap](https://github.com/ethereum-optimism/k8s-netchef-prod/blob/6862432f96e9fe4891d2b728dfc38a9b3a3417e3/kustomize/op-signer/oplabs-prod-ent-mainnet-eu/mn-op-mainnet-0-op-signer/configmap.yaml#L14-L17). The impl, anchorStateRegistry and zero init bond are read live and kept.

## Simulation & Signing

Nested task: pass `council` or `foundation` for your child safe. Check the output against [VALIDATION.md](./VALIDATION.md) before signing.

```bash
cd src/tasks/eth/082-op-mainnet-proposer-rotation

just simulate-stack eth 082-op-mainnet-proposer-rotation council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 082-op-mainnet-proposer-rotation council   # or foundation
```
