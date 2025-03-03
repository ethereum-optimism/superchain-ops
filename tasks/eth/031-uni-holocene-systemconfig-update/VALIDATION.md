# Validation

This document can be used to validate the state diff resulting from the execution of the FP upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.


## State Changes

### `0xc407398d063f942feBbcC6F80a156b47F3f1BDA6` (`SystemConfigProxy`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000066`
  **Before**: `0x00000000000000000000000000000000000000000000000000000000000dbba0`
  **After**: `0x010000000000000000000000000000000000000000000000000dbba0000007d0`
  **Meaning**: Updates the scalar slot to reflect a scalar version of 1. This transaction bundles a change to the `blobBaseFeeScalar` from 0 to 900000. This is done to correct for the fact that Unichain did not set `blobBaseFeeScalar` in their previous deployment of the contracts.  The verification system expects the `blobBaseFeeScalar` to remain unchanged, however, we use an override flag to enable this change. 

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000001c9c380`
  **After**: `0x00000000000000000000000000000000000dbba0000007d00000000001c9c380`
  **Meaning**: Updates the `basefeeScalar` and `blobbasefeeScalar` storage variables to `2000` (`cast td 0x7d0`) and `900000` (`cast td 0xdbba0`) respectively. These share a slot with the `gasLimit` which remains at `30000000` (`cast td 0x0000000001c9c380`).

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000f56d96b2535b932656d3c04ebf51babff241d886`
  **After**: `0x000000000000000000000000ab9d6cb7a427c0765163a7f45bb91cafe5f2d375`
  **Meaning**: Updates the implementation address of the Proxy to the [standard SystemConfig implementation at op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/superchain-registry/blob/e2d3490729b20a649281899c2c286e6e12db57f3/validation/standard/standard-versions-mainnet.toml#L9).



### Nonce increments

The following nonce increments, and no others, must happen (key `0x05` on Safes):
- All simulations: PAO 3/3 `0x6d5B183F538ABB8572F5cD17109c617b994D5833`: `1` -> `2`
- `council` simulation: SC Safe `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`: `18` -> `19`
  - and a nonce increment for the owner EOA or Safe chosen for simulation, e.g. `0x07dC0893cAfbF810e3E72505041f2865726Fd073` for default index 0.
- `foundation` simulation: Fnd Safe `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`: `16` -> `17`
  - and a nonce increment for the owner EOA or Safe chosen for simulation, e.g. `0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64` for default index 0.
- `chain-governor` simulation: Uni Safe `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`: `7` -> `8`
  - and a nonce increment for the owner EOA or Safe chosen for simulation, e.g. `0xf89C1b6e5D65e97c69fbc792f1BcdcB56DcCde91` for default index 0.
