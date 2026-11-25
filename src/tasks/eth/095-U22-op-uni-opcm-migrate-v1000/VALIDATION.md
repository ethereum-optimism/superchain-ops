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
> - Message Hash: `0x98191f7a69a4142188bfc9fc3b744da29e9782336d6879495b2ecc5ae45a389d`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x0d96e76838e03d99d447c9f82823166046e286f39a4d65fb9fd76c2cff0822db`

Safe transaction hash (root safe): `0x7c6c0b781f9c73f403d4ca5d0f67d88cb639ecfdf1918003252356bdb4a101b1`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/095-U22-op-uni-opcm-migrate-v1000
just simulate-stack eth 095-U22-op-uni-opcm-migrate-v1000 council   # or foundation
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
