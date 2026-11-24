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
> - Message Hash: `0xe9601ff28f4a948ea8922f2082684005f8ea1facc0437fd1bccc440b0fead645`

Safe transaction hash (root safe): `0xd58d233b0f63ea1ce709cfe311be7589fd72fcb132fca2741e8c40b4245f8878`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/127-U22-staging-op-uni-replica-opcm-migrate-v1000
just simulate-stack sep 127-U22-staging-op-uni-replica-opcm-migrate-v1000
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
