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
> - Message Hash: `0x10a595779a35f8b951157519f5b669723cebec78ec680b565b4f595b610fc765`
>
> ### Security Council (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x160cb97285d90cb08b46713b40345e8dd9e7bb48cfdac4a8eba9e2b23c6c5634`

Safe transaction hash (root safe): `0x341d9ea0ad20a8c1833ffbce259841e358d9d785ff6afeccdf4860096678e8f5`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/130-U22-op-ink-soneium-uni
just simulate-stack sep 130-U22-op-ink-soneium-uni council   # or foundation
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
