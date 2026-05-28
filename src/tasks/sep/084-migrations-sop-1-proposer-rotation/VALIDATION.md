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
> - Message Hash: `0x6629c5b729a9903a99f67e79fa002eeeaeff67ed1f3fac97bdf95b49dc3e7cac`
> - Safe Hash:    `0x26733d20f595e4d7cd84578daac497adb5c02e21d93f7b9cb5670732fa19ce7b`
>
> _Hashes generated via `just simulate` at latest block, PAO Safe nonce override = 105 (current on-chain). Tasks 080+081 are canceled; 082+083 hit different safes, so 084 signs at the live PAO nonce. Re-run `just simulate` and replace if the override changes._

## Task Calldata

The task calls `setImplementation(gameType=1, impl, gameArgs)` on the `migrations-sop-1` DisputeGameFactory (`0xD22e520F9005402a80715A3C2A60a6271B823A23`). The PDG implementation contract remains unchanged at `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`; only the `gameArgs` bytes change.

> **Note:** The effective changes vs current on-chain state are:
> - prestate: `0x038512e0…d54c` → `0x0355d19a…6aed` (op-program/v1.9.0-rc.1 Cannon64)
> - proposer: `0x31f018d0…f7c8` → `0x5e9eE0Aa…eB71` (`migrated-sop-1` receiving infra)
> - challenger: `0x55744b68…602c` → `0x9805e797…80D0` (`migrated-sop-1` receiving infra)

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000d22e520f9005402a80715a3c2a60a6271b823a230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000144b1070957000000000000000000000000000000000000000000000000000000000000000100000000000000000000000058bf355c5d4edfc723ef89d99582eccfd143266a000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a40355d19a9da58fccf469c60293543f95f520ef38c055a23502ee0bace5f06aed6463dee3828677f6270d83d45408044fc5edb9088faf920fad8138debf666949b9e41ff71cce1c5a4ca719de2459ccf0a3194b2265f8870df7bcf16900000000000000000000000000000000000000000000000000000000190a862e5e9ee0aa455425aad2b55742077f95113fbaeb719805e7976880e6e48ce765118846078b877d80d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

EIP-712 digest (Safe v1.4.1):
```
0x190107e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e6629c5b729a9903a99f67e79fa002eeeaeff67ed1f3fac97bdf95b49dc3e7cac
```

### Decoding the calldata

```bash
cast calldata-decode "setImplementation(uint32,address,bytes)" <inner_calldata>
```

Expected output (excerpt):
- **gameType:** `1` (PERMISSIONED_CANNON)
- **impl:** `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A` (unchanged)
- **gameArgs:** the 164-byte blob — the new proposer `5e9ee0aa455425aad2b55742077f95113fbaeb71` and challenger `9805e7976880e6e48ce765118846078b877d80d0` should be visible within it

## State Changes

### `0xD22e520F9005402a80715A3C2A60a6271B823A23` (DisputeGameFactoryProxy) — Chain ID 420120110

`gameArgs` for game type 1 (PERMISSIONED_CANNON) updated to embed the new `migrated-sop-1` proposer (`0x5e9eE0Aa455425AaD2B55742077F95113FbaeB71`) and challenger (`0x9805e7976880e6e48Ce765118846078B877d80D0`), plus the new prestate. Implementation address unchanged.

### `0xe934Dc97E347C6aCef74364B50125bb8689c40ff` (ProxyAdminOwner)

Nonce increments by 1.
