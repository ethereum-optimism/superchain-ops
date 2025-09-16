## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Nested Safe 1 (Foundation): `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
>
> - Domain Hash: ``
> - Message Hash: ``
> ### Nested Safe 2 (Security Council): `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
>
> - Domain Hash: ``
> - Message Hash: ``

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** ``


## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.1.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

1. OP Mainnet:

- SystemConfigProxy: []()
- ProxyAdmin: []()
- AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

2. Ink:

- SystemConfigProxy: []()
- ProxyAdmin: []()
- AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

3. Soneium:

- SystemConfigProxy: []()
- ProxyAdmin: []()
- AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

Thus, the command to encode the calldata is:

```bash 
cast calldata 'upgrade((address,address,bytes32)[])' "[(,,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8),(,,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8),(,,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: []() - Sepolia OPContractsManager v4.1.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(,false,)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```

```