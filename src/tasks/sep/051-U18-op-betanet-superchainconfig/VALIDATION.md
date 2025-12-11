## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> ### Betanet EOA (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash: `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: ``

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v6.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgradeSuperchainConfig()`

The `opcm.upgradeSuperchainConfig()` function is called with a 2 inputs:

- SuperchainConfig: [0xBC64837fbFC57946F11a4148EBa89C48812c8dF4](https://github.com/ethereum-optimism/devnets/blob/b17e1b29699914d3458f9e7f5e5fb65c1f4c1b2f/betanets/u18-beta/u18-beta-1/chain.yaml#L8C29-L8C71)
- SuperchainConfigProxyAdmin: [0x0D6A1A07193B222C938C568b0B9A3C691C809760](https://github.com/ethereum-optimism/devnets/blob/b17e1b29699914d3458f9e7f5e5fb65c1f4c1b2f/betanets/u18-beta/u18-beta-1/chain.yaml#L7C32-L7C74)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgradeSuperchainConfig(address,address)' "0xBC64837fbFC57946F11a4148EBa89C48812c8dF4" "0x0D6A1A07193B222C938C568b0B9A3C691C809760"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [OPCMv600address](source) - Sepolia OPContractsManager v6.0.0
- `allowFailure`: false
- `callData`: `0xb0b807eb000000000000000000000000bc64837fbfc57946f11a4148eba89c48812c8df40000000000000000000000000d6a1a07193b222c938c568b0b9a3c691c809760` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x3bb6437aba031afbf9cb3538fa064161e2bf2d78,false,0xb0b807eb000000000000000000000000bc64837fbfc57946f11a4148eba89c48812c8df40000000000000000000000000d6a1a07193b222c938c568b0b9a3c691c809760)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```

```
