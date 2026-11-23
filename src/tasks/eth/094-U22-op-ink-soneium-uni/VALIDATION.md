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
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `TODO_DOMAIN_HASH`
> - Message Hash: `TODO_MESSAGE_HASH`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `TODO_DOMAIN_HASH`
> - Message Hash: `TODO_MESSAGE_HASH`

Safe transaction hash (root safe): `TODO_SAFE_TX_HASH`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/094-U22-op-ink-soneium-uni
just simulate-stack eth 094-U22-op-ink-soneium-uni council   # or foundation
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
