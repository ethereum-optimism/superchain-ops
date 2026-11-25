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
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xd3f20f0f81f12e5ce4e954b6dcb31b8174e7e1bd7b2914bafb2cdccf57807f59`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x327e5bf6e2381da7deb4e1826b9ed5dcc4ff8988d6ba764a7fe2361d2b926d00`

Safe transaction hash (root safe): `0x849b3f28822e8bb9c6554e0398f4997d3f1b1d1b581aeaf37fada866e87e8f0a`

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
