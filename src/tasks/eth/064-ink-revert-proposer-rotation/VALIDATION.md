# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's `_validate` block asserts the new `gameArgs(1)` and unchanged `gameImpls(1)`.

> [!IMPORTANT]
> This is an **ARMED break-glass rollback** task (status `CANCELLED` → excluded from the active stack; see [README.md](./README.md)). The L1PAO/FUS/SC nonces are **not** pinned — they are read live at activation — so the **Message and Safe hashes are generated at activation time**, not committed here. Only the Domain Hashes are fixed (they depend solely on chainId + safe address). The DGF `gameArgs(1)` modelling override exists so a pre-activation simulation shows a genuine OPE → Gelato proposer diff; remove it at activation once that state is live on-chain, then run `just simulate council` / `just simulate foundation` and paste the printed Message/Safe hashes below before signing.

## Expected Domain and Message Hashes

This is a **nested** task signed by the L1 ProxyAdminOwner's two owner safes; verify the hashes for whichever safe you are signing with.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `⟨generate at activation — run just simulate council⟩`
> - Safe Hash:    `⟨generate at activation — run just simulate council⟩`
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `⟨generate at activation — run just simulate foundation⟩`
> - Safe Hash:    `⟨generate at activation — run just simulate foundation⟩`

## Understanding Task Calldata

The task calls `setImplementation` once on the Ink mainnet DisputeGameFactory (`0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`, v1.6.1) for PDG (game type 1). The implementation address does not change (live `gameImpls(1)` = `0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e`); only the `gameArgs` blob changes, and within it **only the proposer** (restored to the Gelato value).

The new 164-byte `gameArgs(1)` blob, byte layout `prestate(32) | vm(20) | ASR(20) | delayedWETH(20) | chainId(32) | proposer(20) | challenger(20)`:

```
0xdead000000000000000000000000000000000000000000000000000000000000\
acc005dcd857b401e4732e6f7837135a22825cfa\
ee018baf058227872540ac60efbd38b023d9dae2\
57b4c29daee99a28e6e86778b499361294c134ea\
000000000000000000000000000000000000000000000000000000000000def1\
65436ddcbc026f34118954f229f7f132b696b3b4\
9ba6e03d8b90de867373db8cf1a58d2f7f006b3a
```

```bash
cast calldata "setImplementation(uint32,address,bytes)" 1 0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e 0xdead000000000000000000000000000000000000000000000000000000000000acc005dcd857b401e4732e6f7837135a22825cfaee018baf058227872540ac60efbd38b023d9dae257b4c29daee99a28e6e86778b499361294c134ea000000000000000000000000000000000000000000000000000000000000def165436ddcbc026f34118954f229f7f132b696b3b49ba6e03d8b90de867373db8cf1a58d2f7f006b3a
# selector: 0xb1070957
```

## Task State Changes

### `0x10d7b35078d3baabb96dd45a9143b94be65b12cd` (DisputeGameFactoryProxy) — Chain ID 57073

- `gameArgs(1)` proposer reverts `0x3832bfbeF03173E4C49a00ec0DD178817A02D177` (OPE) → `0x65436DDcBc026F34118954f229F7f132b696B3b4` (Gelato). Challenger (`0x9ba6e03d…006b3a`) and all other fields unchanged.

The proposer spans two packed slots (challenger bytes preserved in both):

- **Key:** `0x9afb513dc3306e3bc370fea0bac86eaae93221c831ccaae670c9d4101fb0fa7f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000def13832bfbe`
  - **After:**  `0x0000000000000000000000000000000000000000000000000000def165436ddc`
- **Key:** `0x9afb513dc3306e3bc370fea0bac86eaae93221c831ccaae670c9d4101fb0fa80`
  - **Before:** `0xf03173e4c49a00ec0dd178817a02d1779ba6e03d8b90de867373db8cf1a58d2f`
  - **After:**  `0xbc026f34118954f229f7f132b696b3b49ba6e03d8b90de867373db8cf1a58d2f`

### Signer safes

`ProxyAdminOwner`, `Security Council`, and `Foundation Upgrade Safe` nonces each increment by 1 (live values read at activation).

> [!NOTE]
> The `gameArgs(1)` **pre-state** (OPE proposer) is a simulation-only override modelling the post-migration state; it is not written by this task. Remove the DGF override at actual rollback time — the real post-migration `gameArgs` will be live on-chain.

## Post-execution verification

```bash
cast call 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD "gameArgs(uint32)(bytes)" 1 --rpc-url mainnet
# Bytes 124..144 (proposer)  must equal 65436ddcbc026f34118954f229f7f132b696b3b4
# Bytes 144..164 (challenger) must equal 9ba6e03d8b90de867373db8cf1a58d2f7f006b3a (unchanged)
```
