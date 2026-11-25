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
> - Message Hash: `0xbd733fd7883c56b37fdb53e59f772e6f87b52d45d340991428869dad2bb9d160`
>
> ### Security Council (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x384ca8f1be59219b35c3a937ad09dd096dc10494caabb44f21a80ae283398c35`

Safe transaction hash (root safe): `0xea61f5227af364d31d66bdc5e6ac2c20ffa028046d49d761118798ee62f473f7`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/131-U22-op-uni-opcm-migrate-v1000
just simulate-stack sep 131-U22-op-uni-opcm-migrate-v1000 council   # or foundation
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
