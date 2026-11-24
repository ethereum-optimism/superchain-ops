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
> - Message Hash: `0xa4e7cf68057fac219f618606e29af63bc808ff67605dbdc605ccc86ccb7a6b31`

Safe transaction hash (root safe): `0x29f6efc2ff26e7e4bafc1c3639d756ad20c78613a571bdb0937fae132b976f6d`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/128-U22-staging-op-uni-replica-opcm-migrate-v1000
just simulate-stack sep 128-U22-staging-op-uni-replica-opcm-migrate-v1000
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
