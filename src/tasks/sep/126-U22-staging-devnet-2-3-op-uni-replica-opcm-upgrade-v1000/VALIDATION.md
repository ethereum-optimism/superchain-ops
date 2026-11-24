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
> - Message Hash: `0x0d312d4c331fce5d7e6e0e7bbe9e83dd2d4d1352654bfdc87d6e6ed8dea1e6eb`

Safe transaction hash (root safe): `0xad284871a176343348bd25f505c461be81c3304a5958bdda12fca39f158e2c47`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000
just simulate-stack sep 126-U22-staging-devnet-2-3-op-uni-replica-opcm-upgrade-v1000
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
