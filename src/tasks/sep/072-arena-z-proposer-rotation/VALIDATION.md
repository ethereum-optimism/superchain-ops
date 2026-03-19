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
> ### Security Council Safe (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xe41063970d132c7bd99a79ca4b7f5e63ecc2bf58759e5b753fdbd46186fcbb8e`
>
> ### Foundation Upgrade Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x0fb415b196b1cc2520377998fa86d71e6e68473223c6b342bbe0b87448bb85ad`

## Task Calldata

The task calls `setImplementation` on the Arena-Z Sepolia DisputeGameFactory (`0xd02dd46b73ff5f3eC3970f9A12f08Ad703c103df`)
to update the PDG (game type 1) gameArgs with the new AltLayer proposer address (`0x5D7481c68Eb61da46b2F4eF81B9FD988d97527E0`).

The PDG implementation contract remains unchanged at `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`.

`0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000d02dd46b73ff5f3ec3970f9a12f08ad703c103df0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000144b1070957000000000000000000000000000000000000000000000000000000000000000100000000000000000000000058bf355c5d4edfc723ef89d99582eccfd143266a000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4033c000916b4a88cfffeceddd6cf0f4be3897a89195941e5a7c3f8209b4dbb6e6463dee3828677f6270d83d45408044fc5edb908ca89d6e09024334188aa219fe1c994361dd76e21b496a0c00e7a3ca9d1746015d7c6ed6dc5293a1900000000000000000000000000000000000000000000000000000000000026ab5d7481c68eb61da46b2f4ef81b9fd988d97527e0fd1d2e729ae8eee2e146c033bf4400fe752843010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

## State Changes

### [`0xd02dd46b73ff5f3eC3970f9A12f08Ad703c103df`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/arena-z.toml) (DisputeGameFactoryProxy) - Chain ID: 9899

The `gameArgs` for game type 1 (PERMISSIONED_CANNON) are updated to include the new proposer address.
The proposer changes from `0xc97ffcb0953e60995b5d06755ded41b78a3c8b48` to `0x5D7481c68Eb61da46b2F4eF81B9FD988d97527E0`.

### [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/arena-z.toml) (ProxyAdminOwner)

- Nonce incremented from `48` to `49`.
