# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)

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
> - Message Hash: `0x2b9983a6999685875490d9bd1cd78a6874d0cad24df19d3638968a1ffcb4ce27`
>
> ### Foundation Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x2b9983a6999685875490d9bd1cd78a6874d0cad24df19d3638968a1ffcb4ce27`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x9dcdb9f783102d6df1ab95c794b9d5b27ee7e7a653edc5b66be297e3b2ccadfd`

## Understanding Task Calldata

Calldata:
```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000140000000000000000000000000658656a14afdf9c507096ac406564497d13ec754000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004414f6b1a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087690676786cdc8cca75a472e483af7c8f2f0f57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000004414f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) file.

### Task State Changes

### [`0x24424336F04440b1c28685a38303aC33C9D14a25`](https://github.com/ethereum-optimism/superchain-ops/blob/2b33763cbae24bf5af1467f510e66a31b1b98b4a/NESTED-VALIDATION.md?plain=1#L106) (LivenessGuard)

> [!IMPORTANT]
> Security Council Only

**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

The details are explained in [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md#liveness-guard).

### [`0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a`](https://github.com/ethereum-optimism/superchain-registry/blob/6b65f330434d46e24abc9ef78852ac3fa1cba4ec/superchain/configs/mainnet/arena-z.toml#L45) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 10
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `19`
  - **After:** `20` - `cast --to-hex 20` -> `0x14`
  - **Summary:** Nonce
  - **Detail:** Updates the nonce of the ProxyAdminOwner
  
  > [!IMPORTANT]
> Foundation Only

If signer is on foundation safe: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`:

- **Key:**      `0xfd73007b8981c1342ce804a711868bf6d24283a024d36b42ae2b1ac02e8857f3`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation. This step isn't shown in the local simulation because the parent multisig is invoked directly, bypassing the <i>approveHash</i> calls. This slot change reflects an update to the approvedHashes mapping.
    Specifically, this simulation was ran as the nested safe `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`. To verify the slot yourself, run:
    - `res=$(cast index address 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 8)`
    - `cast index bytes32 0xe363a9ec4f2fb8a4274d2958a53940c58743a8d44f5e4c4471b335f15412ee26 $res`
    - Please note: the `0xe363a9ec4f2fb8a4274d2958a53940c58743a8d44f5e4c4471b335f15412ee26` value is taken from the Terminal output and this is the transaction hash of the `approveHash` call.

> [!IMPORTANT]
> Security Council Only

OR if signer is on council safe: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`:

- **Key:**      `0x1332ec349970e7dac6a7c3e93747b3146adf905251294c81ee0a55996d67a2b6`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation. This step isn't shown in the local simulation because the parent multisig is invoked directly, bypassing the <i>approveHash</i> calls. This slot change reflects an update to the approvedHashes mapping.
    Specifically, this simulation was ran as the nested safe `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`. To verify the slot yourself, run:
    - `res=$(cast index address 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 8)`
    - `cast index bytes32 0xe363a9ec4f2fb8a4274d2958a53940c58743a8d44f5e4c4471b335f15412ee26 $res`
    - Please note: the `0xe363a9ec4f2fb8a4274d2958a53940c58743a8d44f5e4c4471b335f15412ee26` value is taken from the Terminal output and this is the transaction hash of the `approveHash` call.
  

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council Safe (GnosisSafe)) - Chain ID: 10
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `31`
  - **After:** `32`
  - **Summary:** Nonce
  - **Detail:** Updates the nonce of the Security Council Safe

### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Safe (GnosisSafe)) - Chain ID: 10
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `31`
  - **After:** `32`
  - **Summary:** Nonce
  - **Detail:** Updates the nonce of the Foundation Safe
  
### [`0x658656a14afdf9c507096ac406564497d13ec754`](https://github.com/ethereum-optimism/superchain-registry/blob/6b65f330434d46e24abc9ef78852ac3fa1cba4ec/superchain/configs/mainnet/arena-z.toml#L64) (DisputeGameFactory) - Chain ID: 7897
  
- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:** `0x000000000000000000000000733a80ce3baec1f27869b6e4c8bc0e358c121045`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** FaultDisputeGame Implementation
  - **Detail:** Resets the FDG implementation on Arena-Z Mainnet DisputeGameFactory to the zero address
  - **Detail:** Resets the FDG implementation on Arena-Z Mainnet DisputeGameFactory to the zero address. You can verify the current implementation with `cast call 0x658656a14afdf9c507096ac406564497d13ec754 "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
### [`0x87690676786cdc8cca75a472e483af7c8f2f0f57`](https://github.com/ethereum-optimism/superchain-registry/blob/6b65f330434d46e24abc9ef78852ac3fa1cba4ec/superchain/configs/mainnet/swell.toml#L61) (DisputeGameFactory) - Chain ID: 1923
  
- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:** `0x0000000000000000000000002dabff87a9a634f6c769b983afbbf4d856add0bf`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** FaultDisputeGame Implementation
  - **Detail:** Resets the FDG implementation on Swell Mainnet DisputeGameFactory to the zero address. You can verify the current implementation with `cast call 0x87690676786cdc8cca75a472e483af7c8f2f0f57 "gameImpls(uint32)(address)" 0`, where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
