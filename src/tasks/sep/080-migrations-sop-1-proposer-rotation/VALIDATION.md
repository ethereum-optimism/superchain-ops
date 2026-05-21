# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's _validate block includes assertions to confirm the task ran correctly. State Changes can also be manually reviewed in Tenderly, using the link shown in the terminal during simulation.

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Migrations-sop-1 1/1 Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `<TBD_DOMAIN_HASH>`
> - Message Hash: `<TBD_MESSAGE_HASH>`

## Task Calldata

The task calls `setImplementation(gameType=1, impl, gameArgs)` on the `migrations-sop-1` DisputeGameFactory (`0xD22e520F9005402a80715A3C2A60a6271B823A23`). The PDG implementation contract remains unchanged at `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`; only the `gameArgs` bytes change to embed the new OP proposer (`0x31f018d02be7a6e89b8933bd28a05780a6ecf7c8`).

```
<TBD_CALLDATA>
```

### Decoding the calldata

```bash
cast calldata-decode "setImplementation(uint32,address,bytes)" <inner_calldata>
```

Expected output (excerpt):
- **gameType:** `1` (PERMISSIONED_CANNON)
- **impl:** `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A` (unchanged)
- **gameArgs:** the 164-byte blob — the new proposer `31f018d02be7a6e89b8933bd28a05780a6ecf7c8` should be visible within it

## State Changes

### `0xD22e520F9005402a80715A3C2A60a6271B823A23` (DisputeGameFactoryProxy) — Chain ID 420120110

`gameArgs` for game type 1 (PERMISSIONED_CANNON) updated to embed the new OP proposer address (`0x31f018d02be7a6e89b8933bd28a05780a6ecf7c8`). Implementation address unchanged.

### `0xe934Dc97E347C6aCef74364B50125bb8689c40ff` (ProxyAdminOwner)

Nonce increments by 1.
