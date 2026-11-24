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
> - Message Hash: `0xfdcf03f4440b732ed1daa1f80fa85e3b0e23326cf066ba21f32271afdaeeb380`

Safe transaction hash (root safe): `0x4674fa9970a5deb2b742d2ea9016b919e765be32712f18ed5b8b87b26c4cb619`

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
