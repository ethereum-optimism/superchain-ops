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
> - Domain Hash:  `TODO_DOMAIN_HASH`
> - Message Hash: `TODO_MESSAGE_HASH`
>
> ### Security Council (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `TODO_DOMAIN_HASH`
> - Message Hash: `TODO_MESSAGE_HASH`

Safe transaction hash (root safe): `TODO_SAFE_TX_HASH`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/130-U22-op-uni-opcm-migrate-v1000
just simulate-stack sep 130-U22-op-uni-opcm-migrate-v1000 council   # or foundation
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
