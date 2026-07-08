# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's `_validate` block asserts the new `gameArgs(1)` and unchanged `gameImpls(1)`.

## Expected Domain and Message Hashes

This is a **nested** task signed by the L1 ProxyAdminOwner's two owner safes; verify the hashes for whichever safe you are signing with.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `TODO — regenerate with just simulate council`
> - Message Hash: `TODO`
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `TODO — regenerate with just simulate foundation`
> - Message Hash: `TODO`

## Understanding Task Calldata

The task calls `setImplementation` once on the Ink mainnet DisputeGameFactory (`0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`, v1.6.1) for PDG (game type 1). The implementation address does not change; only the `gameArgs` blob changes, and within it **only the proposer** (restored to the Gelato value).

The 164-byte `gameArgs(1)` blob layout is `prestate(32) | vm(20) | ASR(20) | delayedWETH(20) | chainId(32) | proposer(20) | challenger(20)`. Rebuild from the live blob with the proposer replaced:

```bash
cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameArgs(uint32)(bytes)" 1 --rpc-url mainnet
cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameImpls(uint32)(address)" 1 --rpc-url mainnet
cast calldata "setImplementation(uint32,address,bytes)" 1 <LIVE_IMPL> <NEW_BLOB>
# selector: 0xb1070957
```

## Task State Changes

### `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD` (DisputeGameFactoryProxy) — Chain ID 57073

- `gameArgs(1)` proposer reverts from the OPE proposer → pre-migration Gelato proposer. Challenger (`0x9ba6e03d…006b3a`) and all other fields unchanged.
- Game types 0 (CANNON) and 8 (CANNON_KONA) are untouched.

The exact packed storage keys and before/after values are printed by `just simulate` — capture them here once generated.

### Signer safes

`Security Council` and `Foundation Upgrade Safe` nonces increment by 1 (nested execution through the L1 ProxyAdminOwner `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`).

## Post-execution verification

```bash
cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameArgs(uint32)(bytes)" 1 --rpc-url mainnet
# Bytes 124..144 (proposer)  must equal <Gelato proposer>
# Bytes 144..164 (challenger) must equal 9ba6e03d8b90de867373db8cf1a58d2f7f006b3a (unchanged)
```
