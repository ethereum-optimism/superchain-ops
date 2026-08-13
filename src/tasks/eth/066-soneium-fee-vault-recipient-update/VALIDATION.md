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
> values **expected at signing time**: L1PAO = 40, Foundation Upgrade Safe = 66, Security
> Council = 64 (the live values read 2026-08-13 — `eth/065`, which executes before this task,
> is signed by the Foundation Operations Safe and does not touch these). If any live nonce
> differs from the pinned value when you sign, STOP — update the overrides, re-simulate, and
> regenerate every hash in this file.

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
> - Message Hash: `0xfce7945ef3ed0f350de4d08226a244a98979c448858ad53f7dbb129d840078fa`
>
> ### Security Council Safe (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x71dae5e5b200dac4f7a44aca40ff4d877faddc5e1f79970a129a71c0c18b66c7`

Root L1PAO (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) safe transaction hash (identical on
both signing paths):
`0xa3f754b8931c98c779b9bf5c0e4e9c8b2754674e6d952f11e16cf3d64ee4a55e`

## Understanding Task Calldata

The task is a single `Multicall3.aggregate3Value` from the L1PAO containing **4**
`depositTransaction` calls on the Soneium Mainnet `OptimismPortal`
(`0x88e529A6ccd302c948689Cd5156C83D4614FAE92`). Each deposit executes on Soneium L2
(chainId 1868) with the **aliased L1PAO** (`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`) as
sender — the Soneium L2 ProxyAdmin owner that the fee-vault setters authorize against. Every
deposit has `value = 0`, `gasLimit = 150000` (`0x249f0`), `isCreation = false`, and carries the
same inner calldata — `setRecipient(address)` selector `0x3bbed4a0` with argument
`0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`:

**Call 1 — `SequencerFeeVault.setRecipient(newRecipient)`**

- To (L2): `0x4200000000000000000000000000000000000011` (SequencerFeeVault)

**Call 2 — `BaseFeeVault.setRecipient(newRecipient)`**

- To (L2): `0x4200000000000000000000000000000000000019` (BaseFeeVault)

**Call 3 — `L1FeeVault.setRecipient(newRecipient)`**

- To (L2): `0x420000000000000000000000000000000000001a` (L1FeeVault)

**Call 4 — `OperatorFeeVault.setRecipient(newRecipient)`**

- To (L2): `0x420000000000000000000000000000000000001b` (OperatorFeeVault)

Verify the inner calldata fingerprint:

```bash
cast calldata "setRecipient(address)" 0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260
# Expected: 0x3bbed4a000000000000000000000000034fff1a1cb3c054e9ed1bbd36883b14a66e6c260
```

Beyond these four writes nothing changes: every vault's withdrawal network (L2) and minimum
withdrawal amount (10 ETH on Sequencer/Base/L1, 0 on Operator) already equal the configured
values, so the template's per-field skip-unchanged emits no deposit for them.

The full task calldata is:

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000005c000000000000000000000000088e529a6ccd302c948689cd5156c83d4614fae920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c420000000000000000000000004200000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000243bbed4a000000000000000000000000034fff1a1cb3c054e9ed1bbd36883b14a66e6c260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088e529a6ccd302c948689cd5156c83d4614fae920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c420000000000000000000000004200000000000000000000000000000000000019000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000243bbed4a000000000000000000000000034fff1a1cb3c054e9ed1bbd36883b14a66e6c260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088e529a6ccd302c948689cd5156c83d4614fae920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000243bbed4a000000000000000000000000034fff1a1cb3c054e9ed1bbd36883b14a66e6c260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088e529a6ccd302c948689cd5156c83d4614fae920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000243bbed4a000000000000000000000000034fff1a1cb3c054e9ed1bbd36883b14a66e6c2600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Simulating the L2 effect before signing

Two layers exist here — one automatic, one you can run yourself:

**Automatic (runs inside `just simulate`):** the template's mandatory pre-flight forks Soneium via
the config's `l2RpcUrls`, asserts the L2 ProxyAdmin owner is the aliased L1PAO, version-gates each
vault, and **dry-runs every setter call as the aliased owner** — so if any of the four L2 writes
could revert, the simulation itself fails loudly before any signature is collected.

**Manual replay (recommended independent check):** reproduce exactly what the four deposits will
do on Soneium and inspect the resulting state, on a local fork:

```bash
# 1. Fork Soneium Mainnet locally
anvil --fork-url https://rpc.soneium.org --port 9545

# 2. Impersonate the deposits' L2 sender — the aliased L1PAO (= Soneium's L2 ProxyAdmin owner)
L2RPC=http://127.0.0.1:9545
ALIASED=0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
cast rpc anvil_impersonateAccount $ALIASED --rpc-url $L2RPC
cast rpc anvil_setBalance $ALIASED 0xDE0B6B3A7640000 --rpc-url $L2RPC

# 3. Send the exact inner calls the deposits carry (cross-check the calldata bytes above)
NEW=0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260
cast send 0x4200000000000000000000000000000000000011 "setRecipient(address)" $NEW \
  --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 150000
cast send 0x4200000000000000000000000000000000000019 "setRecipient(address)" $NEW \
  --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 150000
cast send 0x420000000000000000000000000000000000001a "setRecipient(address)" $NEW \
  --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 150000
cast send 0x420000000000000000000000000000000000001b "setRecipient(address)" $NEW \
  --from $ALIASED --unlocked --rpc-url $L2RPC --gas-limit 150000

# 4. Run the same read-backs as the post-execution section below against $L2RPC and
#    confirm the changed/unchanged expectations, then kill anvil.
```

This replay was executed during task preparation (2026-08-13): all four calls succeed within the
150k deposit gas limit (45,656 gas each — a warm single-slot recipient write — leaving >3.2x
headroom), produce exactly the expected end state (all four recipients =
`0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; networks and minimums byte-identical to before),
and the same setter reverts with `ProxyAdminOwnedBase_NotProxyAdminOwner()` (`0x7f12c64b`) when
sent from any other address.

## Task State Changes

The L1 state changes are the signer-safe bookkeeping (root L1PAO nonce, the approving child
safe's nonce, and the child's `approvedHashes` entry on the root) plus the Soneium
`OptimismPortal`'s resource metering write (touched on every deposit). The fee-vault config
changes themselves happen on Soneium L2 once the deposits are relayed — validate them with the
[L2 post-execution validation](#l2-post-execution-validation) section below.

### Signer safes

`ProxyAdminOwner` nonce increments `40` → `41`; the approving child safe's nonce increments by 1
(`Security Council` 64 → 65, `Foundation Upgrade Safe` 66 → 67 — nested execution through the L1
ProxyAdminOwner `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`). During each child safe's approve
step, the root L1PAO also gains an
`approvedHashes[<child safe>][0xa3f754b8931c98c779b9bf5c0e4e9c8b2754674e6d952f11e16cf3d64ee4a55e] = 1`
storage write — expect it in the Tenderly state diff of the approval transactions.

---

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (ProxyAdminOwner (GnosisSafe)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `40`
  - **After:** `41`
  - **Summary:** nonce
  - **Detail:** Nonce increment of the L1 ProxyAdminOwner Safe executing this task. The
    before-value reflects the nonce state override in [config.toml](./config.toml) (pinned to
    the live value read 2026-08-13; `eth/065` does not affect it).

---

### `0x88e529a6ccd302c948689cd5156c83d4614fae92` (OptimismPortal2) - Chain ID: 1868

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Decoded Kind:** `struct ResourceMetering.ResourceParams`
  - **Before:** ``
  - **After:** ``
  - **Summary:** params
  - **Detail:** `ResourceMetering` bookkeeping (`prevBoughtGas` / `prevBlockNum`) updated by the
    Soneium Mainnet `OptimismPortal` as a side effect of the four `depositTransaction` calls.
    The exact packed value depends on the block the transaction lands in; only this slot of the
    portal should change.

## L2 post-execution validation

The vault config changes land on Soneium L2 (chainId 1868) once the four deposits are relayed —
typically within a few minutes of L1 execution. **The L1 transaction succeeding does NOT prove the
L2 writes happened** (a deposit that reverts on L2 leaves the L1 tx successful), so validate the
end state directly on Soneium:

```bash
RPC=https://rpc.soneium.org

# Changed by this task:
cast call 0x4200000000000000000000000000000000000011 "recipient()(address)" -r $RPC
# → 0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260   (was 0xF07b3169ffF67A8AECdBb18d9761AEeE34591112)
cast call 0x4200000000000000000000000000000000000019 "recipient()(address)" -r $RPC
# → 0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260   (was 0xF07b3169ffF67A8AECdBb18d9761AEeE34591112)
cast call 0x420000000000000000000000000000000000001a "recipient()(address)" -r $RPC
# → 0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260   (was 0xF07b3169ffF67A8AECdBb18d9761AEeE34591112)
cast call 0x420000000000000000000000000000000000001b "recipient()(address)" -r $RPC
# → 0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260   (was 0x4200000000000000000000000000000000000019, the BaseFeeVault)

# Must be UNCHANGED:
cast call 0x4200000000000000000000000000000000000011 "withdrawalNetwork()(uint8)" -r $RPC        # 1 (L2)
cast call 0x4200000000000000000000000000000000000019 "withdrawalNetwork()(uint8)" -r $RPC        # 1 (L2)
cast call 0x420000000000000000000000000000000000001a "withdrawalNetwork()(uint8)" -r $RPC        # 1 (L2)
cast call 0x420000000000000000000000000000000000001b "withdrawalNetwork()(uint8)" -r $RPC        # 1 (L2)
cast call 0x4200000000000000000000000000000000000011 "minWithdrawalAmount()(uint256)" -r $RPC    # 10000000000000000000 (10 ETH)
cast call 0x4200000000000000000000000000000000000019 "minWithdrawalAmount()(uint256)" -r $RPC    # 10000000000000000000 (10 ETH)
cast call 0x420000000000000000000000000000000000001a "minWithdrawalAmount()(uint256)" -r $RPC    # 10000000000000000000 (10 ETH)
cast call 0x420000000000000000000000000000000000001b "minWithdrawalAmount()(uint256)" -r $RPC    # 0
```

If any "changed" value did not update, the deposit reverted on L2 while the L1 tx still shows
success: inspect the relayed L2 transactions sent from the aliased L1PAO
(`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`) on a Soneium explorer, and re-run `just simulate` —
the template's mandatory pre-flight reproduces L2-side failures loudly at simulation time.
