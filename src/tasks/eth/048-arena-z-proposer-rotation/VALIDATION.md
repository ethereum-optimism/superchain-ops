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
> ### Security Council Safe (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xe59c9eedb54000fe69ce7bf45b57876cf0cf9a7b2662243847c49cd45f33ed71`
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xf5b401f8e8f0fa6e93c1cd00e4dc21c89779317d80b332d95a020703c17c73d5`

## Task Calldata

The task calls `setImplementation` on the Arena-Z Mainnet DisputeGameFactory (`0x658656A14AFdf9c507096aC406564497d13EC754`)
to update the PDG (game type 1) gameArgs with the new AltLayer proposer address (`0xDA89371d5C940233B200f9a235bF0Ea8AB9fAe96`).

The PDG implementation contract remains unchanged at `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`.

`0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000658656a14afdf9c507096ac406564497d13ec7540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000144b1070957000000000000000000000000000000000000000000000000000000000000000100000000000000000000000058bf355c5d4edfc723ef89d99582eccfd143266a000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4033c000916b4a88cfffeceddd6cf0f4be3897a89195941e5a7c3f8209b4dbb6e6463dee3828677f6270d83d45408044fc5edb9080c9ff654bcd0769142fe70951b0634c5ae19ba3c1d21c2535154d5d0337eda61df9c07f306aa17f70000000000000000000000000000000000000000000000000000000000001ed9da89371d5c940233b200f9a235bf0ea8ab9fae969ba6e03d8b90de867373db8cf1a58d2f7f006b3a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

## State Changes

### [`0x658656A14AFdf9c507096aC406564497d13EC754`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/arena-z.toml) (DisputeGameFactoryProxy) - Chain ID: 7897

The `gameArgs` for game type 1 (PERMISSIONED_CANNON) are updated to include the new proposer address.
The proposer changes from `0x5f16e66d8736b689a430564a31c8d887ca357cd8` to `0xDA89371d5C940233B200f9a235bF0Ea8AB9fAe96`.

### [`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/arena-z.toml) (ProxyAdminOwner)

- Nonce incremented from `33` to `34`.
