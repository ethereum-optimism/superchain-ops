# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x53214e04e1efe0a4bfc4cdeb55f2913ff92db5b02b676796df5f7c86f70cd1e7`
>
> ### Security Council Safe (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x56d63c87dc7f7b8ed7c9229fac66291e7629342f8d8c660522c3a131977a425a`

## Understanding Task Calldata

This task updates the fee vault recipient for Arena-Z Testnet (Chain ID: 9899) from
`0x9648CF2B93DdBbe120812a567294B2954bCc8568` to `0xE75f598754A552841E65f43197C85028874A96a4`.

Since fee vaults have immutable recipients baked into constructor bytecode, the update requires:

For each of the three fee vaults (SequencerFeeVault, BaseFeeVault, L1FeeVault):
1. Deploy a new implementation via CREATE2 on L2 (through OptimismPortal deposit transaction)
2. Upgrade the vault proxy via L2 ProxyAdmin (through OptimismPortal deposit transaction)

This results in 5 L1→L2 deposit transactions total:
- 2 CREATE2 deployments (SequencerFeeVault impl + default FeeVault impl shared by BaseFeeVault and L1FeeVault)
- 3 proxy upgrades (SequencerFeeVault, BaseFeeVault, L1FeeVault)

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../docs/NESTED-VALIDATION.md) file.

### Task State Changes

### [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/arena-z.toml) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 11155420

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `48`
  - **After:** `49`
  - **Summary:** Nonce increment for the ProxyAdminOwner Safe.
  - **Detail:** The Safe nonce is incremented from 48 to 49 after executing the transaction.

> [!IMPORTANT]
> Foundation Only

If signer is on Foundation Safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`:

- **Key:**          `0x2dd5ae8bbc99659191ef69b30925ad0517b654cc4d934c4660f4613649e58549`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `approveHash(bytes32)` called on ProxyAdminOwner by Foundation Safe.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** This slot change reflects the Foundation Safe calling `approveHash` on the ProxyAdminOwner as part of the nested multisig execution flow. The slot is `approvedHashes[0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B][0xd6c04a5a37d6e8024bf6bdab9c3b4dc365168b954de287f1ebcd940b9bdff24d]` (mapping at slot 8). To verify:
    - `res=$(cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8)`
    - `cast index bytes32 0xd6c04a5a37d6e8024bf6bdab9c3b4dc365168b954de287f1ebcd940b9bdff24d $res`

> [!IMPORTANT]
> Security Council Only

If signer is on Security Council Safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`:

- **Key:**          `0x99c18ca5eb1a62034274410cfb42524de1b801d3e02dc93c475ffb86563ca8e7`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `approveHash(bytes32)` called on ProxyAdminOwner by Security Council Safe.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** This slot change reflects the Security Council Safe calling `approveHash` on the ProxyAdminOwner as part of the nested multisig execution flow. The slot is `approvedHashes[0xf64bc17485f0B4Ea5F06A96514182FC4cB561977][0xd6c04a5a37d6e8024bf6bdab9c3b4dc365168b954de287f1ebcd940b9bdff24d]` (mapping at slot 8). To verify:
    - `res=$(cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8)`
    - `cast index bytes32 0xd6c04a5a37d6e8024bf6bdab9c3b4dc365168b954de287f1ebcd940b9bdff24d $res`

> [!IMPORTANT]
> Security Council Only

### [`0xc26977310bC89DAee5823C2e2a73195E85382cC7`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol) (LivenessGuard)
**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

- **Key:**          `0x8b832b208e2b85d2569164b1655368f5b5eddb1c56f6c1acf41053cac08f5141`
  - **Before:**     `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:**      Updated to `block.timestamp` at time of execution.
  - **Summary:**    LivenessGuard timestamp update.
  - **Detail:**     **THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**
                    When the security council safe executes a transaction, the liveness timestamps are updated.
                    This is updating at the moment when the transaction is submitted (`block.timestamp`) into the [`lastLive`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol#L41) mapping located at the slot 0.

