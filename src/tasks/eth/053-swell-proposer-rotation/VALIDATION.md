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
> - Message Hash: `0x79d8f2288e3e3b86b23b79e4db676909c252550d4b2e8946f1215607a83fa0f0`
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xf7956ff2edfbffacd5b77c51e11b17b82b5d3ce9a14842f99463df4b79b42b89`

## Task Calldata

The task calls `setImplementation` on the Swellchain Mainnet DisputeGameFactory (`0x87690676786cDc8cCA75A472e483AF7C8F2f0F57`)
to update the PDG (game type 1) gameArgs with the new proposer address (`0xdFe6834AC8B97c2d9Bf9df330E55b51c849111FC`).

The PDG implementation contract remains unchanged at `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`.

`0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000087690676786cdc8cca75a472e483af7c8f2f0f570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000144b1070957000000000000000000000000000000000000000000000000000000000000000100000000000000000000000058bf355c5d4edfc723ef89d99582eccfd143266a000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4033c000916b4a88cfffeceddd6cf0f4be3897a89195941e5a7c3f8209b4dbb6e6463dee3828677f6270d83d45408044fc5edb908511fb9e172f8a180735acf9c2beeb208cd0061acdd525e7e8fa35345d30e88018c9925f3c28761070000000000000000000000000000000000000000000000000000000000000783dfe6834ac8b97c2d9bf9df330e55b51c849111fc9ba6e03d8b90de867373db8cf1a58d2f7f006b3a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

### Decoding the Calldata

The substantive call is a single `setImplementation(gameType, impl, gameArgs)`:

- **Function selector:** `b1070957` (`setImplementation`)
- **gameType:** `1` (PERMISSIONED_CANNON)
- **impl:** `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A` (PDG implementation, unchanged)
- **gameArgs:** 164 bytes encoding the PDG constructor arguments

The new proposer address (`0xdFe6834AC8B97c2d9Bf9df330E55b51c849111FC`) is embedded in the
gameArgs bytes. You can decode the inner `setImplementation` calldata to verify all three arguments:

```bash
cast calldata-decode "setImplementation(uint32,address,bytes)" \
  0xb1070957000000000000000000000000000000000000000000000000000000000000000100000000000000000000000058bf355c5d4edfc723ef89d99582eccfd143266a000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4033c000916b4a88cfffeceddd6cf0f4be3897a89195941e5a7c3f8209b4dbb6e6463dee3828677f6270d83d45408044fc5edb908511fb9e172f8a180735acf9c2beeb208cd0061acdd525e7e8fa35345d30e88018c9925f3c28761070000000000000000000000000000000000000000000000000000000000000783dfe6834ac8b97c2d9bf9df330e55b51c849111fc9ba6e03d8b90de867373db8cf1a58d2f7f006b3a00000000000000000000000000000000000000000000000000000000
```

Expected output:
```
1
0x58bf355C5d4EdFc723eF89d99582ECCfd143266A
0x033c000916b4a88cfffeceddd6cf0f4be3897a89195941e5a7c3f8209b4dbb6e6463dee3828677f6270d83d45408044fc5edb908511fb9e172f8a180735acf9c2beeb208cd0061acdd525e7e8fa35345d30e88018c9925f3c28761070000000000000000000000000000000000000000000000000000000000000783dfe6834ac8b97c2d9bf9df330e55b51c849111fc9ba6e03d8b90de867373db8cf1a58d2f7f006b3a
```

The three decoded fields are:
- **gameType:** `1` (PERMISSIONED_CANNON)
- **impl:** `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A` (unchanged)
- **gameArgs:** the bytes above — note the new proposer `dfe6834ac8b97c2d9bf9df330e55b51c849111fc` is visible within them

## State Changes

### [`0x87690676786cDc8cCA75A472e483AF7C8F2f0F57`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/swell.toml) (DisputeGameFactoryProxy) - Chain ID: 1923

The `gameArgs` for game type 1 (PERMISSIONED_CANNON) are updated to include the new proposer address.
The proposer changes from `0xA2Acb8142b64fabda103DA19b0075aBB56d29FbD` to `0xdFe6834AC8B97c2d9Bf9df330E55b51c849111FC`.

### [`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/swell.toml) (ProxyAdminOwner)

- Nonce incremented from `35` to `36`.
