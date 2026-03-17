# Validation

This document can be used to validate the inputs and result of the execution of the upgrade
transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the
values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `TODO`
> - Message Hash: `TODO`
>
> ### Security Council Safe (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `TODO`
> - Message Hash: `TODO`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to
in the state diff audit report. As a signer, you are responsible for verifying that this hash is
correct. Please compare the hash below with the one in the audit report. If no audit report is
available for this task, you must still ensure that the normalized state diff hash matches the
output in your terminal.

**Normalized hash:** `TODO`

## Understanding Task Calldata

The task calls `depositTransaction` on the Arena-Z Mainnet `OptimismPortal`
(`0xB20f99b598E8d888d1887715439851BC68806b22`) three times, each targeting the L2
`ProxyAdmin` (`0x4200000000000000000000000000000000000018`) to upgrade one fee vault proxy.

**Call 1 — Upgrade SequencerFeeVault**
- Portal: `0xB20f99b598E8d888d1887715439851BC68806b22`
- L2 target: `0x4200000000000000000000000000000000000018` (ProxyAdmin)
- L2 calldata: `ProxyAdmin.upgrade(0x4200000000000000000000000000000000000011, 0x6B0660A3be44da5e37A7A9Be4D384a43D2596ea4)`

**Call 2 — Upgrade BaseFeeVault**
- Portal: `0xB20f99b598E8d888d1887715439851BC68806b22`
- L2 target: `0x4200000000000000000000000000000000000018` (ProxyAdmin)
- L2 calldata: `ProxyAdmin.upgrade(0x4200000000000000000000000000000000000019, 0xD7e148FEc0d8F59a672B3EE3e1e3Ba5C82Bdf015)`

**Call 3 — Upgrade L1FeeVault**
- Portal: `0xB20f99b598E8d888d1887715439851BC68806b22`
- L2 target: `0x4200000000000000000000000000000000000018` (ProxyAdmin)
- L2 calldata: `ProxyAdmin.upgrade(0x420000000000000000000000000000000000001A, 0xD7e148FEc0d8F59a672B3EE3e1e3Ba5C82Bdf015)`

### Task Calldata

```
TODO
```

## Task State Changes

### L1 State Changes

The ProxyAdminOwner safe (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) nonce increments
by 1 after the transaction executes.

The Foundation (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`) and Security Council
(`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`) safe nonces each increment by 1 as they
approve the nested transaction.

### L2 State Changes (post-deposit relay)

Once the three deposit transactions are included in an L2 block, the following changes
occur on Arena-Z Mainnet (Chain ID 7897):

- `SequencerFeeVault` (`0x4200000000000000000000000000000000000011`) implementation slot
  updated to `0x6B0660A3be44da5e37A7A9Be4D384a43D2596ea4`
- `BaseFeeVault` (`0x4200000000000000000000000000000000000019`) implementation slot
  updated to `0xD7e148FEc0d8F59a672B3EE3e1e3Ba5C82Bdf015`
- `L1FeeVault` (`0x420000000000000000000000000000000000001A`) implementation slot
  updated to `0xD7e148FEc0d8F59a672B3EE3e1e3Ba5C82Bdf015`

### Verify pre-deployed implementations on L2

Verify the implementations are deployed on Arena-Z Mainnet before signing:

```bash
# Check SequencerFeeVault implementation has code
cast code 0x6B0660A3be44da5e37A7A9Be4D384a43D2596ea4 \
  --rpc-url https://rpc.arena-z.gg

# Check BaseFeeVault / L1FeeVault implementation has code
cast code 0xD7e148FEc0d8F59a672B3EE3e1e3Ba5C82Bdf015 \
  --rpc-url https://rpc.arena-z.gg

# Check SequencerFeeVault RECIPIENT() on the new impl
cast call 0x6B0660A3be44da5e37A7A9Be4D384a43D2596ea4 "RECIPIENT()(address)" \
  --rpc-url https://rpc.arena-z.gg

# Check BaseFeeVault / L1FeeVault RECIPIENT() on the new impl
cast call 0xD7e148FEc0d8F59a672B3EE3e1e3Ba5C82Bdf015 "RECIPIENT()(address)" \
  --rpc-url https://rpc.arena-z.gg
```
