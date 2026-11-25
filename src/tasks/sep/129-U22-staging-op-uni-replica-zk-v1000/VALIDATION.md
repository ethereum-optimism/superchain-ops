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
> ### Staging ProxyAdminOwner (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0xc7fa7df0aa52ad1d951d9061107e28ee0298f090be8c723682b8d57f3eceaccf`

Safe transaction hash (root safe): `0x51c07f1d306dff707eca6e6b70cf681c8de1f1e457205c0d9f9841c4246ada0f`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/129-U22-staging-op-uni-replica-zk-v1000
just simulate-stack sep 129-U22-staging-op-uni-replica-zk-v1000
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
