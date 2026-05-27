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
> - Domain Hash:  `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0x96b31d0608bc29c01646f8794b3ddc69af2276324f5c230508704628f0326961`
> - Safe Hash:    `0x2ac6e9400ba234f6b39f0f03ab3a22146a0b784797a7058cf46428ef17aca3bd`
>
> _Hashes generated with PAO Safe nonce stateOverride = 98 (stacked after 080 & 081). For standalone simulation use 96; re-run `just simulate` and replace before signing._

## Task Calldata

The task calls `setImplementation(gameType=1, impl, gameArgs)` on the `migrations-sop-1` DisputeGameFactory (`0xD22e520F9005402a80715A3C2A60a6271B823A23`). The PDG implementation contract remains unchanged at `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`; only the `gameArgs` bytes change.

> **Note:** On-chain inspection (`gameArgs(1)`) shows the proposer is **already** `0x31f018d0…f7c8` (OP) and challenger is **already** `0x55744b68…602c` (OP). The only effective change vs current state is the prestate, which moves from `0x038512e0…d54c` → `0x0355d19a…6aed` (op-program/v1.9.0-rc.1 Cannon64).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000d22e520f9005402a80715a3c2a60a6271b823a230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000144b1070957000000000000000000000000000000000000000000000000000000000000000100000000000000000000000058bf355c5d4edfc723ef89d99582eccfd143266a000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a40355d19a9da58fccf469c60293543f95f520ef38c055a23502ee0bace5f06aed6463dee3828677f6270d83d45408044fc5edb9088faf920fad8138debf666949b9e41ff71cce1c5a4ca719de2459ccf0a3194b2265f8870df7bcf16900000000000000000000000000000000000000000000000000000000190a862e31f018d02be7a6e89b8933bd28a05780a6ecf7c855744b685bd143385d118fc1f413d2b93758602c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

EIP-712 digest (Safe v1.4.1):
```
0x190107e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e96b31d0608bc29c01646f8794b3ddc69af2276324f5c230508704628f0326961
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
