# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

> [!WARNING]
> Scaffold only. Every value below is a placeholder until the open items in
> [README.md](./README.md) are resolved and the task is simulated.

## Expected Domain and Message Hashes

The hashes assume the pinned nonces in [config.toml](./config.toml) and move if those nonces or
the calldata change.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Upgrade Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0xd5124c83005238ad58fa482543b741bdd41716c6dbfd06f1a300daac760c7608`
>
> ### Security Council (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xd1bad105e81b744254d3a4672406461490016e64b0fbabca3cad461615042885`

Safe transaction hash (root safe): `0xed47b5dc1778b50a6e8d9321fe8fc1430e7e47dc6c14631b9f02340a31a5f371`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/132-U22-op-uni-zk-v1000
just simulate-stack sep 132-U22-op-uni-zk-v1000 council   # or foundation
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
