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
> - Message Hash: `0x3782b1a3742eb3fbe987441873dc1023b9ff058a67dbf558f0025a992b511aaa`

Safe transaction hash (root safe): `0x72e58d48142b7142ccf74a01f3190b919e5b8e30aa6c5a51277bf10c132cd860`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/127-U22-staging-devnet-6-opcm-upgrade-v1000
just simulate-stack sep 127-U22-staging-devnet-6-opcm-upgrade-v1000
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
