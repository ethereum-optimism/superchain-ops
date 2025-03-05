# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the below hashes match what is on your ledger.
> ### Security Council
> - Domain hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message hash: `0x430741c0c80d12ad39f01c3367791e3ee59c73e2ff0f565add075f935fe875d6`
> ### Optimism Foundation
> - Domain hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message hash: `0xf4dfba4d97fb21d884a38ef84cc2219e544e5e2b3c0ba6b28779d770995e60f0`
> ### Chain-Governor
> - Domain hash: `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message hash: `0x49d5cebc73fad795ba2ece47ea8df2bb7ec20f654e78d7974bd17b82b1018f21`

## Verify new absolute prestate

Please verify that the new absolute prestate is set correctly to `0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd`. See [Petra notice](https://docs.optimism.io/notices/pectra-changes#verify-the-new-absolute-prestate) in docs for more details. 

You can verify this absolute prestate by running the following [command](https://github.com/ethereum-optimism/optimism/blob/6819d8a4e787df2adcd09305bc3057e2ca4e58d9/Makefile#L133-L135) in the root of the monorepo:

```bash
make reproducible-prestate
```

You should expect the following output at the end of the command:

```bash
Cannon Absolute prestate hash: 
0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd
Cannon64 Absolute prestate hash: 
0x03a7d967025dc434a9ca65154acdb88a7b658147b9b049f0b2f5ecfb9179b0fe
CannonInterop Absolute prestate hash: 
0x0379d61de1833af6766f07b4ed931d85b3f6282508bbcbf9f4637398d97b61c1
```
## State Overrides
Note: The changes listed below do not include threshold and number of owners overrides or liveness guard related changes, these changes are listed in the [NESTED-VALIDATION.md](../../../NESTED-VALIDATION.md) file.

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Council Safe)
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000014` <br/>
  **Meaning:** Override the nonce value of the `Security Council` by increasing from 18 to 20.


### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Upgrade Safe)
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000012` <br/>
  **Meaning:** Override the nonce value of the Foundation Upgrade Safe by increasing from 16 to 18.

## State Changes

### `0x2F12d621a16e2d3285929C9996f478508951dFe4` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x00000000000000000000000008f0f8f4e792d21e16289db7a80759323c446f61` <br/>
  **After**: `0x000000000000000000000000171dE4f3ea4fBbf233aA9649dCf1b1d6fD70f542` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the new implementation is set using
  `cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 0`.

### `0x2F12d621a16e2d3285929C9996f478508951dFe4` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000c457172937ffa9306099ec4f2317903254bf7223` <br/>
  **After**: `0x0000000000000000000000003aFdc7cCF8a1c0d351E3E5F220AF056ea2c07733` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the new implementation is set using
  `cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 1`.
### Liveness Guards

Liveness Guard related changes are listed [here](../../../NESTED-VALIDATION.md#liveness-guard-security-council-safe-or-unichain-operation-safe-only) file.





