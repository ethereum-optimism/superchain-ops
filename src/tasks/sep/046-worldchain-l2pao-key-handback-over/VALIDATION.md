# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.

The steps are:
1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Standard L2 Proxy Admin Owner (Unaliased)
  ### Worldchain has their L2PAO transferred to the standard address but retained control of their L1PAO
(`0x1Eb2fFc903729a0F03966B917003800b145F56E2`)

>### Security Council Safe (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x90174dd31d5ba63b20aa1e5df91fe03c6166a323a17dcea11d6e5e92b744033e`
>
> ### Foundation Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x3156bd84f93074952b43af3368d798328835200f04aa6c6c092cc9fcf0af4d79`


## Understanding Task Calldata

The transaction initiates a deposit transaction via the OptimismPortal on L1 Sepolia, which will be executed on L2 (Worldchain Sepolia) to transfer the L2 ProxyAdmin ownership to an EOA.

### Decoding the depositTransaction call:
```bash
# The outer multicall to OptimismPortal
cast calldata-decode "depositTransaction(address,uint256,uint64,bool,bytes)" \
   0xe9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000e78a0a96c5d6ae6c606418ed4a9ced378cb030a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

Returns:
- `_to`: `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)
- `_value`: `0` (no ETH sent)
- `_gasLimit`: `200000` (gas for L2 execution)
- `_isCreation`: `false` (not a contract creation)
- `_data`: `0xf2fde38b000000000000000000000000e78a0a96c5d6ae6c606418ed4a9ced378cb030a0`

### Decoding the inner transferOwnership call:
```bash
cast calldata-decode "transferOwnership(address)" \
  0xf2fde38b000000000000000000000000e78a0a96c5d6ae6c606418ed4a9ced378cb030a0
```

Returns:
- `newOwnerEOA`: `0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0` (the target EOA)

# State Validations

For a complete walkthrough of validating the state changes on L1 and L2 follow [the steps in this doc](https://github.com/ethereum-optimism/superchain-ops/blob/main/src/doc/simulate-l2-ownership-transfer.md)

## Manual L2 Verification Steps

After the L1 transaction is executed, you must verify that the L2 deposit transaction successfully transfers ownership:

1. **Find the L2 deposit transaction**: Look for a transaction on Worldchain Sepolia from the L1 caller to the L2 ProxyAdmin at `0x4200000000000000000000000000000000000018`.

2. **Verify the OwnershipTransferred event**: Confirm that the event shows:
   - `previousOwner`: `0x2FC3ffc903729a0f03966b917003800B145F67F3` (aliased 2/2 safe)
   - `newOwnerEOA`: `0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0` (target EOA)

3. **Verify final state**: Call `owner()` on the L2 ProxyAdmin to confirm it returns `0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0`.

```bash
# After L2 execution, verify the new owner
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url worldchain-sepolia
# Should return: 0xe78a0A96C5D6aE6C606418ED4A9Ced378cb030A0
```

## Task Calldata

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000ff6eba109271fe6d4237eeed4bab1dd9a77dd1a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000e78a0a96c5d6ae6c606418ed4a9ced378cb030a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```