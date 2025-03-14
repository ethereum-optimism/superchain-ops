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
> - Message hash: `0x3a8ae85d16128fedabb4d6d57fb721bbf635902c9d7a290b5a88512e2157d52a`
> ### Optimism Foundation
> - Domain hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message hash: `0x07467136b768d1c8954249fc5699f64e37a8ca3f9e981cc912a3600ae59865a6`
> ### Chain-Governor
> - Domain hash: `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message hash: `0x5b9598300e5a438cde2fe20605c55d4d5932af294e9faf58b4c5004efbf1a255`

## Verify new absolute prestate

Please verify that the new absolute prestate is set correctly to `0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01
`. See [Petra notice](https://docs.optimism.io/notices/pectra-changes#verify-the-new-absolute-prestate) in docs for more details. 

You can verify this absolute prestate by running the following [command](https://github.com/ethereum-optimism/optimism/blob/6819d8a4e787df2adcd09305bc3057e2ca4e58d9/Makefile#L133-L135) in the root of the monorepo:

```bash
make reproducible-prestate
```

You should expect the following output at the end of the command:

```bash
Cannon Absolute prestate hash: 
0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01
Cannon64 Absolute prestate hash: 
0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405
CannonInterop Absolute prestate hash: 
0x03673e05a48799e6613325a3f194114c0427d5889cefc8f423eed02dfb881f23
```


## State Overrides
Note: The changes listed below do not include threshold and number of owners overrides or liveness guard related changes, these changes are listed in the [NESTED-VALIDATION.md](../../../NESTED-VALIDATION.md) file.

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Council Safe)
 | **Key** | `0x0000000000000000000000000000000000000000000000000000000000000005` |
 |---------|----------------------------------------------------------------------------------|
 | **After** | `0x0000000000000000000000000000000000000000000000000000000000000014` |

**Meaning:** Override the nonce value of the `Security Council` by increasing from 18 to 20.


### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Upgrade Safe)
 | **Key** | `0x0000000000000000000000000000000000000000000000000000000000000005` |
 |---------|----------------------------------------------------------------------------------|
 | **After** | `0x0000000000000000000000000000000000000000000000000000000000000012` |

**Meaning:** Override the nonce value of the Foundation Upgrade Safe by increasing from 16 to 18.

### `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC` (Chain Governor Safe)
 | **Key** | `0x0000000000000000000000000000000000000000000000000000000000000005` |
 |---------|----------------------------------------------------------------------------------|
 | **After** | `0x0000000000000000000000000000000000000000000000000000000000000008` |

**Meaning:** Override the nonce value of the Chain Governor Safe by increasing from 7 to 8.

### `0x6d5B183F538ABB8572F5cD17109c617b994D5833` (Unichain Owner Safe)
 | **Key** | `0x0000000000000000000000000000000000000000000000000000000000000005` |
 |---------|----------------------------------------------------------------------------------|
 | **After** | `0x0000000000000000000000000000000000000000000000000000000000000002` |

**Meaning:** Override the nonce value of the Unichain Owner Safe by increasing from 1 to 2.


## State Changes

### `0x2F12d621a16e2d3285929C9996f478508951dFe4` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x00000000000000000000000008f0f8f4e792d21e16289db7a80759323c446f61` <br/>
  **After**: `0x00000000000000000000000077034d8F7C0c9B01065514b15ba8b2F13AbE5e43` <br/>
  **Meaning**: Updates the implementation for game type 0. Verify that the new implementation is set using
  `cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 0`.


### `0x2F12d621a16e2d3285929C9996f478508951dFe4` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000c457172937ffa9306099ec4f2317903254bf7223` <br/>
  **After**: `0x0000000000000000000000009D254e2b925516bD201d726189dfd0eeA6786c58` <br/>
  **Meaning**: Updates the implementation for game type 1. Verify that the new implementation is set using
  `cast call 0x2F12d621a16e2d3285929C9996f478508951dFe4 "gameImpls(uint32)(address)" 1`.

### Liveness Guards

Liveness Guard related changes are listed [here](../../../NESTED-VALIDATION.md#liveness-guard-security-council-safe-or-unichain-operation-safe-only) file.





