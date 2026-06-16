# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's `_validate` block asserts the new `gameArgs(1)` and unchanged `gameImpls(1)`. State changes can also be reviewed in Tenderly via the link printed during simulation.

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task. This is a **nested** task signed by the L1 ProxyAdminOwner's two owner safes; verify the hashes for whichever safe you are signing with.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xae806acb180adb11d7ce6c5c328691792dd100cacdc5dc7d433fd5e9192eba4e`
>
> ### Foundation Upgrade Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x1cf251b69f75f413647639cc61bcfeb83fced74f2d30f4b76e63e343a79306a0`
>
> _The Domain Hashes are deterministic for these safes on Sepolia (chainId 11155111) and were computed independently: `keccak256(abi.encode(0x47e7…9218, 11155111, <safe>))`. The Message hashes were generated against live Sepolia state on 2026-06-16 (signer-safe nonces L1PAO=53 / Foundation=73 / Security Council=67, pre-U19 prestate). They are **provisional** — re-run `just simulate` and replace them before signing: they change after U19 (2026-06-17 bumps the live prestate and therefore the gameArgs blob) and whenever the signer-safe nonces advance._

## Understanding Task Calldata

The task calls `setImplementation` **once** on the Ink Sepolia DisputeGameFactory (`0x860e626c700AF381133D9f4aF31412A2d1DB3D5d`), for PDG (game type 1). The implementation address does not change (`0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`); only the `gameArgs` blob changes, and within it **only the proposer**.

The new 164-byte `gameArgs(1)` blob, byte layout `prestate(32) | vm(20) | ASR(20) | delayedWETH(20) | chainId(32) | proposer(20) | challenger(20)`, computed from the **live** (pre-U19) on-chain values with the proposer swapped:

```
0x033c000916b4a88cfffeceddd6cf0f4be3897a89195941e5a7c3f8209b4dbb6e\
6463dee3828677f6270d83d45408044fc5edb908\
299d7ea9f0b584cfaf2a5341d151b44967594ca9\
52d5bdc07f4ac131c21f09ffda1440f0152a8ac6\
00000000000000000000000000000000000000000000000000000000000ba5ed\
2282d49d805333d8cd6ddda52b32ac07d6e4e51b\
fd1d2e729ae8eee2e146c033bf4400fe75284301
```

```bash
# Selector + head (gameType = 1, impl = 0x58bf355C…266A):
# 0xb1070957 0000…0001 0000…0058bf355C…266A 0000…0060 0000…00a4 <164-byte blob>
cast calldata "setImplementation(uint32,address,bytes)" 1 0x58bf355C5d4EdFc723eF89d99582ECCfd143266A 0x033c000916b4a88cfffeceddd6cf0f4be3897a89195941e5a7c3f8209b4dbb6e6463dee3828677f6270d83d45408044fc5edb908299d7ea9f0b584cfaf2a5341d151b44967594ca952d5bdc07f4ac131c21f09ffda1440f0152a8ac600000000000000000000000000000000000000000000000000000000000ba5ed2282d49d805333d8cd6ddda52b32ac07d6e4e51bfd1d2e729ae8eee2e146c033bf4400fe75284301
```

> [!IMPORTANT]
> The blob above reflects the **pre-U19** live state. U19 (2026-06-17) may bump the permissioned prestate (bytes 0–32). `SetDisputeGameArgs` reads `gameArgs(1)` live, so the actual blob is recomputed at sign time — **re-run `just simulate` after U19** and re-verify the proposer bytes (124–144) are `2282d49d805333d8cd6ddda52b32ac07d6e4e51b` and the challenger bytes (144–164) are `fd1d2e729ae8eee2e146c033bf4400fe75284301`.

The outer Multicall3 blob is assembled by the framework and printed during simulation; confirm it contains only the single `setImplementation` call above.

## Task State Changes

### `0x860e626c700AF381133D9f4aF31412A2d1DB3D5d` (DisputeGameFactoryProxy) — Chain ID 763373

- `gameArgs(1)` (PERMISSIONED_CANNON) proposer updated `0xb15d79…4543` (Gelato) → `0x2282d49d805333D8cd6ddda52B32aC07d6e4e51B` (OPE). Challenger (`0xfd1d2e…4301`), prestate, vm, ASR, delayedWETH, chainId, and the implementation address (`0x58bf355C…266A`) are unchanged.
- Game types 0 (CANNON) and 8 (CANNON_KONA) are untouched.

### Signer safes

`Security Council` and `Foundation Upgrade Safe` nonces increment by 1 (nested execution through the L1 ProxyAdminOwner `0x1Eb2fF…56E2`).

## Post-execution verification

```bash
cast call 0x860e626c700AF381133D9f4aF31412A2d1DB3D5d "gameArgs(uint32)(bytes)" 1 --rpc-url <SEPOLIA_RPC>
# Bytes 124..144 (proposer)  must equal 2282d49d805333d8cd6ddda52b32ac07d6e4e51b
# Bytes 144..164 (challenger) must equal fd1d2e729ae8eee2e146c033bf4400fe75284301
```
