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
> - Message Hash: `0x2532bea82d7e491c73350a13f9e10f9917ff80890971c536381d77048574402f`
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x65979c0f5e1b9f7a429ee99cee71ef210a708db61c5b058650d003ee8cb21747`

Safe transaction hash (root safe): `0x6c327dbb3d4084dd6b5233cb262bfbdea036cbd9b1c22d3d5c89df54f172e740`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/096-U22-op-uni-zk-v1000
just simulate-stack eth 096-U22-op-uni-zk-v1000 council   # or foundation
```

## Calldata

TODO: decoded calldata breakdown.

## State Changes

TODO: expected state changes from the simulation.
