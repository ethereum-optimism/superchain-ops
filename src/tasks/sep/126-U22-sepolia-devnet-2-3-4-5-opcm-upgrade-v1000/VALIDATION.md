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
> - Domain Hash:  `TODO_DOMAIN_HASH`
> - Message Hash: `TODO_MESSAGE_HASH`

Safe transaction hash (root safe): `TODO_SAFE_TX_HASH`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/126-U22-sepolia-devnet-2-3-4-5-opcm-upgrade-v1000
just simulate-stack sep 126-U22-sepolia-devnet-2-3-4-5-opcm-upgrade-v1000
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
