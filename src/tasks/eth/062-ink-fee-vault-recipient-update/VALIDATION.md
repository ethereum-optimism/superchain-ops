# Validation

This document can be used to validate the inputs and result of the execution of the transaction
which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Simulating the L2 effect before signing](#simulating-the-l2-effect-before-signing)
4. [Verifying the state changes](#task-state-changes)
5. [L2 post-execution validation](#l2-post-execution-validation)

> [!IMPORTANT]
> The nonce state overrides in [config.toml](./config.toml) pin the signer-safe nonces to the
> values **expected at signing time**, i.e. after `eth/061-ink-proposer-rotation` executes:
> L1PAO = 37, Foundation Upgrade Safe = 63, Security Council = 61 (live values read 2026-07-20
> were 36 / 62 / 60). If any live nonce differs from the pinned value when you sign, STOP —
> update the overrides, re-simulate, and regenerate every hash in this file.

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the
values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x33e97bb82645ae814d0b490ce83ab75de96f3a9b63fcb2e52973df0721f95074`
>
> ### Security Council Safe (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xfb1c3d4927a76c7caf6f6a5fa432da55ca6b26b3e38a95f4a4a926a7abc5842a`

Root L1PAO (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) safe transaction hash (identical on
both signing paths):
`0x42c33279472d79c8ebedcde3259fbbd5dcbb5eab53ed0d0f2002f1e6d673735f`

## Understanding Task Calldata

The task is a single `Multicall3.aggregate3Value` from the L1PAO containing **4**
`depositTransaction` calls on the Ink Mainnet `OptimismPortal`
(`0x5d66C1782664115999C47c9fA5cd031f495D3e4F`). Each deposit executes on Ink L2 (chainId 57073)
with the **aliased L1PAO** (`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`) as sender — the Ink L2
ProxyAdmin owner that the fee-vault setters authorize against. Every deposit has `value = 0`,
`gasLimit = 150000` (`0x249f0`), `isCreation = false`.

**Call 1 — `L1FeeVault.setRecipient(costRecipient)`**

- To (L2): `0x420000000000000000000000000000000000001a` (L1FeeVault)
- Inner calldata: `setRecipient(address)` selector `0x3bbed4a0`, arg
  `0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9`

**Call 2 — `L1FeeVault.setMinWithdrawalAmount(0)`**

- To (L2): `0x420000000000000000000000000000000000001a` (L1FeeVault)
- Inner calldata: `setMinWithdrawalAmount(uint256)` selector `0x85b5b14d`, arg `0`
  (was 2 ETH — cost-recipient sweeps become possible at any accrued balance)

**Call 3 — `OperatorFeeVault.setRecipient(costRecipient)`**

- To (L2): `0x420000000000000000000000000000000000001b` (OperatorFeeVault)
- Inner calldata: `setRecipient(address)` selector `0x3bbed4a0`, arg
  `0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9`

**Call 4 — `OperatorFeeVault.setWithdrawalNetwork(L1)`**

- To (L2): `0x420000000000000000000000000000000000001b` (OperatorFeeVault)
- Inner calldata: `setWithdrawalNetwork(uint8)` selector `0x307f2962`, arg `0`
  (`WithdrawalNetwork.L1`)

Beyond these four writes nothing changes: `L1FeeVault`'s withdrawal network is already L1,
`OperatorFeeVault`'s minimum is already 0, and `SequencerFeeVault` / `BaseFeeVault` are untouched.

The full task calldata is:

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000005c00000000000000000000000005d66c1782664115999c47c9fa5cd031f495d3e4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000243bbed4a00000000000000000000000001eb630b2e7409597d462dd5f3d21e305fc56b8c900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005d66c1782664115999c47c9fa5cd031f495d3e4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000002485b5b14d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005d66c1782664115999c47c9fa5cd031f495d3e4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000243bbed4a00000000000000000000000001eb630b2e7409597d462dd5f3d21e305fc56b8c900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005d66c1782664115999c47c9fa5cd031f495d3e4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024307f296200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Simulating the L2 effect before signing

Two layers exist here — one automatic, one you can run yourself:

**Automatic (runs inside `just simulate`):** the template's mandatory pre-flight forks Ink via the
config's `l2RpcUrls`, asserts the L2 ProxyAdmin owner is the aliased L1PAO, version-gates each
vault, and **dry-runs every setter call as the aliased owner** — so if any of the four L2 writes
could revert, the simulation itself fails loudly before any signature is collected.

**Manual replay (recommended independent check):** reproduce exactly what the four deposits will
do on Ink and inspect the resulting state, on a local fork:

```bash
# 1. Fork Ink Mainnet locally
anvil --fork-url https://rpc-gel.inkonchain.com --port 9545

# 2. Impersonate the deposits' L2 sender — the aliased L1PAO (= Ink's L2 ProxyAdmin owner)
L2RPC=http://127.0.0.1:9545
ALIASED=0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
cast rpc anvil_impersonateAccount $ALIASED --rpc-url $L2RPC
cast rpc anvil_setBalance $ALIASED 0xDE0B6B3A7640000 --rpc-url $L2RPC

# 3. Send the exact inner calls the deposits carry (cross-check the calldata bytes above)
cast send 0x420000000000000000000000000000000000001a "setRecipient(address)" \
  0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9 --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 150000
cast send 0x420000000000000000000000000000000000001a "setMinWithdrawalAmount(uint256)" 0 \
  --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 150000
cast send 0x420000000000000000000000000000000000001b "setRecipient(address)" \
  0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9 --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 150000
cast send 0x420000000000000000000000000000000000001b "setWithdrawalNetwork(uint8)" 0 \
  --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 150000

# 4. Run the same read-backs as the post-execution section below against $L2RPC and
#    confirm the changed/unchanged expectations, then kill anvil.
```

This replay was executed during task preparation: all four calls succeed within the 150k deposit
gas limit (40.6k-45.7k gas each, >3x headroom), produce exactly the expected end state with the
untouched vaults byte-identical, and the same setters revert with
`ProxyAdminOwnedBase_NotProxyAdminOwner()` when sent from any other address.

## Task State Changes

The L1 state changes are the signer-safe bookkeeping (root L1PAO nonce, the approving child
safe's nonce, and the child's `approvedHashes` entry on the root) plus the Ink `OptimismPortal`'s
resource metering write (touched on every deposit). The fee-vault config changes themselves happen
on Ink L2 once the deposits are relayed — validate them with the
[L2 post-execution validation](#l2-post-execution-validation) section below.

### Signer safes

`ProxyAdminOwner` nonce increments `37` → `38`; `Security Council` (61) and `Foundation Upgrade
Safe` (63) nonces increment by 1 (nested execution through the L1 ProxyAdminOwner
`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`). During each child safe's approve step, the root
L1PAO also gains an `approvedHashes[<child safe>][0x42c33279472d79c8ebedcde3259fbbd5dcbb5eab53ed0d0f2002f1e6d673735f] = 1`
storage write — expect it in the Tenderly state diff of the approval transactions.

---

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (ProxyAdminOwner (GnosisSafe)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `37`
  - **After:** `38`
  - **Summary:** nonce
  - **Detail:** Nonce increment of the L1 ProxyAdminOwner Safe executing this task. The
    before-value reflects the nonce state override in [config.toml](./config.toml) (pinned to
    the post-`eth/061` value).

---

### `0x5d66c1782664115999c47c9fa5cd031f495d3e4f` (OptimismPortal2) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Decoded Kind:** `struct ResourceMetering.ResourceParams`
  - **Before:** ``
  - **After:** ``
  - **Summary:** params
  - **Detail:** `ResourceMetering` bookkeeping (`prevBoughtGas` / `prevBlockNum`) updated by the
    Ink Mainnet `OptimismPortal` as a side effect of the four `depositTransaction` calls. The
    exact packed value depends on the block the transaction lands in; only this slot of the
    portal should change.

## L2 post-execution validation

The vault config changes land on Ink L2 (chainId 57073) once the four deposits are relayed —
typically within a few minutes of L1 execution. **The L1 transaction succeeding does NOT prove the
L2 writes happened** (a deposit that reverts on L2 leaves the L1 tx successful), so validate the
end state directly on Ink:

```bash
RPC=https://rpc-gel.inkonchain.com

# Changed by this task:
cast call 0x420000000000000000000000000000000000001a "recipient()(address)" -r $RPC
# → 0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9
cast call 0x420000000000000000000000000000000000001a "minWithdrawalAmount()(uint256)" -r $RPC
# → 0   (was 2000000000000000000 / 2 ETH)
cast call 0x420000000000000000000000000000000000001b "recipient()(address)" -r $RPC
# → 0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9
cast call 0x420000000000000000000000000000000000001b "withdrawalNetwork()(uint8)" -r $RPC
# → 0   (L1 — was 1/L2)

# Must be UNCHANGED:
cast call 0x420000000000000000000000000000000000001a "withdrawalNetwork()(uint8)" -r $RPC      # 0
cast call 0x420000000000000000000000000000000000001b "minWithdrawalAmount()(uint256)" -r $RPC  # 0
cast call 0x4200000000000000000000000000000000000011 "recipient()(address)" -r $RPC            # 0xa6f0F94C13C4255231958079E7331694205F6c93
cast call 0x4200000000000000000000000000000000000019 "recipient()(address)" -r $RPC            # 0xa6f0F94C13C4255231958079E7331694205F6c93
```

If any "changed" value did not update, the deposit reverted on L2 while the L1 tx still shows
success: inspect the relayed L2 transactions sent from the aliased L1PAO
(`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`) on an Ink explorer, and re-run `just simulate` —
the template's mandatory pre-flight reproduces L2-side failures loudly at simulation time.
