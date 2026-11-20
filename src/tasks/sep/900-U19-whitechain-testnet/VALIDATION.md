# Validation — 900-U19-whitechain-testnet

Simulated 2026-11-06 against live Sepolia state at fork block 12078035, PAO Safe nonce 4.

## Expected hashes

```
Safe Address:   0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85
Safe Hash:      0x120d87a1ffa4dbd4e3e4029203de13597872d65ea721834aced2ee8d23486ecc
Domain Hash:    0x51f29ca0551362b92587cd685e062d74d8f6189c847da73569ffd14f97ab1552
Message Hash:   0x4381f63f2235d72237eed5eb4f9ccf465233b55e99b2860542e84498b1318a06
```

Data to sign (`0x1901 || domain || message`):

```
0x190151f29ca0551362b92587cd685e062d74d8f6189c847da73569ffd14f97ab15524381f63f2235d72237eed5eb4f9ccf465233b55e99b2860542e84498b1318a06
```

Recompute the domain hash, which depends only on the Safe address and chain id:

```bash
cast keccak $(cast abi-encode "f(bytes32,uint256,address)" \
  $(cast keccak "EIP712Domain(uint256 chainId,address verifyingContract)") \
  11155111 0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85)
# 0x51f29ca0551362b92587cd685e062d74d8f6189c847da73569ffd14f97ab1552
```

The Safe transaction hash was confirmed against the live Safe at nonce 4:

```bash
cast call 0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85 \
  "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)(bytes32)" \
  0x93dc480940585D9961bfcEab58124ffD3d60f76a 0 "$(cat u19-task-calldata.txt)" 1 0 0 0 \
  0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 4 \
  --rpc-url "$SEPOLIA_RPC"
# 0x120d87a1ffa4dbd4e3e4029203de13597872d65ea721834aced2ee8d23486ecc
```

**These hashes are valid only at nonce 4.** If the Safe signs anything else first, regenerate.

## Signer checks before signing

| Check | Expected | Target |
|---|---|---|
| Safe nonce | 4 | `0x044a91B1…cCb85` |
| Safe threshold / owners | 1 / `[0xEAd4fe6b892e00763D715095eE4A880637179f3D]` | `0x044a91B1…cCb85` |
| Owner has no code | `0x` | `0xEAd4fe6b…9f3D` |
| OPCM version | `7.1.17` | `0x44e19705…8297` |
| SystemConfig version | `3.13.1`, the required starting point | `0x9328Ea86…181c` |
| respectedGameType | 1 | `0xFF9b597b…D0C3` |
| CGT enabled | `true` | `0x9328Ea86…181c` |
| ProxyAdmin owner | `0x044a91B1…cCb85` | `0x1E46b85e…3a7A` |

## Transaction structure

| Field | Value |
|---|---|
| `to` | `0x93dc480940585D9961bfcEab58124ffD3d60f76a` (Multicall3Delegatecall) |
| `value` / `operation` | `0` / `1` (DELEGATECALL) |
| `safeTxGas` / `baseGas` / `gasPrice` | `0` / `0` / `0` |
| `gasToken` / `refundReceiver` | `address(0)` / `address(0)` |
| `nonce` | `4` |

Task calldata is `aggregate3((address,bool,bytes)[])`, selector `0x82ad56cb`, 2,691 bytes, in
[u19-task-calldata.txt](./u19-task-calldata.txt). Two calls, both to the OPCM, both
`allowFailure = false`:

| # | Selector | Function | Argument |
|---|---|---|---|
| 1 | `0x86fe1c66` | `upgradeSuperchain(...)` | SuperchainConfig `0x11854D31…426E` |
| 2 | `0x8a847e2e` | `upgrade(...)` | SystemConfig `0x9328Ea86…181c`, game configs, extra instructions |

## Expected state changes

**11 accounts, 20 storage slots.** No balance changes. One new contract is deployed: a DelayedWETH
proxy at `0x2e02e6cB6A632ff1c83CC5F3596342299b8117fe`.

`0x3608…2bbc` is the ERC-1967 implementation slot, `0xb531…6103` the ERC-1967 admin slot.

### `0x2e02e6cB6A632ff1c83CC5F3596342299b8117fe` — the NEW DelayedWETHProxy

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x…00` | `0x0` | `0x1` | initialized |
| `0x…04` | `0x0` | `0x9328ea86…181c` | SystemConfig wired in |
| `0x3608…2bbc` | `0x0` | `0xE440CC08…630e` | implementation → DelayedWETH 1.5.1 |
| `0xb531…6103` | `0x0` | `0x1E46b85e…3a7A` | admin → the chain's ProxyAdmin |

The pre-U19 proxy `0xDD01A989…e437` is left untouched and unreferenced. **This is the address that
must be propagated into sep/901 and sep/902 after execution.**

### `0xfaa2fAA8912C069c01abc169c33713c79027c833` — DisputeGameFactoryProxy

`gameImpls` is mapping slot `0x65`, `gameArgs` slot `0x69`, with long byte strings at
`keccak256(slot)` onward.

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x3608…2bbc` | `0xc040F392…5e2c` | `0x72B97171…393b` | implementation → DisputeGameFactory 1.6.1 |
| `0x4d5a9bd2…5f9e` | `0x9d955E57…f7DA` | `0xe1dFFCBE…b87e` | `gameImpls[1]` → v7 PermissionedDisputeGame 2.4.0 |
| `0x9afb513d…fa7c` | `0x038512e0…d54c` | `0xdead0000…0000` | `gameArgs[1]` word 0 — prestate replaced by the placeholder |
| `0x9afb513d…fa7d` | `0x60d4d6fe…f338` | `0xacc005dc…f338` | `gameArgs[1]` word 1 — MIPS → `0xaCc005DC…5cfa` (1.10.1), ASR prefix unchanged |
| `0x9afb513d…fa7e` | `0xb7a1df41…dd01a989…` | `0xb7a1df41…2e02e6cb…` | `gameArgs[1]` word 2 — **DelayedWETH repointed from the old proxy to the new one** |

Derivations:

```bash
cast index uint32 1 0x65          # 0x4d5a9bd2…5f9e
cast keccak $(cast index uint32 1 0x69)   # 0x9afb513d…fa7c
```

### `0x9328Ea869949f33c57B7b680B6EdB58769e2181c` — SystemConfigProxy

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x3608…2bbc` | `0xd392c27B…32d2` | `0x42Ad0173…4db9` | implementation → SystemConfig 3.14.2 |
| `0x5154…58ff` | `0x0` | `0x2e02e6cb…17fe` | `systemconfig.delayedweth` → the new proxy |
| `0x99f4…ff42` | `0x0` | `0x44e19705…8297` | `systemconfig.opcm` → the v7 OPCM |

```bash
cast keccak systemconfig.delayedweth   # 0x5154…5900, minus 1 = 0x5154…58ff
cast keccak systemconfig.opcm          # 0x99f4…ff43, minus 1 = 0x99f4…ff42
```

**`minBaseFee` in slot `0x6c` is not touched.** Its `storageCodeExceptions` entry exists only so
the code-presence check does not misread the packed slot; see [config.toml](./config.toml).

### Implementation-only changes

| Account | Before → After | Version |
|---|---|---|
| `0xFF9b597b…D0C3` OptimismPortalProxy | `0xccD52507…5BcE` → `0xe89F13c5…D3C2` | OptimismPortal2 5.6.1 |
| `0x4Da16596…A32c` AnchorStateRegistryProxy | `0xe804ed4d…3c23` → `0x8F40Cc98…B281` | AnchorStateRegistry 3.9.0 |
| `0x11854D31…426E` SuperchainConfig | `0xb08Cc720…a957` → `0xE4F9779a…D550` | SuperchainConfig 2.4.2 |
| `0x0c50bE53…9DED` L1StandardBridgeProxy | `0x61525Eaa…f62A` → `0xB37a11Aa…A891` | L1StandardBridge 2.8.2 |
| `0x1e419Fc5…0C5B` L1ERC721BridgeProxy | `0x74f1aC50…ecf9` → `0x9F164f1d…Cb2e` | L1ERC721Bridge 2.9.1 |
| `0x5898f6c3…2B9B` OptimismMintableERC20FactoryProxy | `0x8ee6fB13…eabB` → `0xaAbEA75D…9b12` | Factory 1.11.0 |

### `0xa848d05c539B0E03AfAB6E4DB5C4e02568689e41` — AddressManager

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x5152…385e` | `0xb686f13a…9fe0` | `0x59d49753…86f0` | `OVM_L1CrossDomainMessenger` → L1CrossDomainMessenger 2.11.1 |

```bash
cast index bytes32 $(cast keccak OVM_L1CrossDomainMessenger) 1
# 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e
```

### `0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85` — ProxyAdminOwner Safe

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x…05` | `4` | `5` | Safe nonce increment |

### What must NOT appear

- Any change to `respectedGameType`: it stays 1.
- Any change to the anchor root or sequence number.
- Any change to `isCustomGasToken` or `minBaseFee`.
- Any DisputeGameFactory **owner** write. Whitechain's DGF owner is already the PAO Safe, unlike the
  replica's, where an owner write did appear.
- Any balance change.

## Expected validator errors

Assert-only; they do not affect the calldata. The config declares:

```
OVERRIDES-L1PAOMULTISIG,OVERRIDES-CHALLENGER,SYSCON-130,CKDG-NOSHAPE,PLDG-10,CKDG-10
```

| Code | Why |
|---|---|
| `OVERRIDES-L1PAOMULTISIG`, `OVERRIDES-CHALLENGER` | chain-specific PAO Safe and challenger, not the standard Sepolia ones |
| `SYSCON-130` | the chain runs its own SuperchainConfig |
| `CKDG-NOSHAPE`, `CKDG-10` | no CANNON_KONA game, correct for a permissioned-only chain |
| `PLDG-10` | the CANNON (0) slot is zeroed by the V700 OPCM |

The template reverts with `Unexpected errors` if the set differs, so a clean simulation is itself
the confirmation.

## Post-execution checks

```bash
RPC="$SEPOLIA_RPC"
SC=0x9328Ea869949f33c57B7b680B6EdB58769e2181c
DGF=0xfaa2fAA8912C069c01abc169c33713c79027c833

cast call $SC "version()(string)" --rpc-url $RPC                         # 3.14.2
cast call 0xFF9b597b0781457ae6aa7256Ca5ed5839bF7D0C3 "version()(string)" --rpc-url $RPC  # 5.6.1
cast call 0x4Da165963420dEeb0788f338b7A1Df41e535A32c "version()(string)" --rpc-url $RPC  # 3.9.0
cast call $DGF "version()(string)" --rpc-url $RPC                        # 1.6.1
cast call 0x11854D3146a460D095943C3231F2755ba342426E "version()(string)" --rpc-url $RPC  # 2.4.2

# unchanged by design
cast call $SC "isCustomGasToken()(bool)" --rpc-url $RPC                  # true
cast call $SC "minBaseFee()(uint64)" --rpc-url $RPC                      # 5000000000
cast call 0xFF9b597b0781457ae6aa7256Ca5ed5839bF7D0C3 "respectedGameType()(uint32)" --rpc-url $RPC  # 1
cast call $DGF "gameImpls(uint32)(address)" 1 --rpc-url $RPC             # 0xe1dFFCBE…b87e

cast call 0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85 "nonce()(uint256)" --rpc-url $RPC  # 5
```

**Then read the new DelayedWETH proxy and propagate it:**

```bash
cast call $SC "delayedWETH()(address)" --rpc-url $RPC
# expected 0x2e02e6cB6A632ff1c83CC5F3596342299b8117fe, but confirm rather than assume
```

Update `DelayedWETHProxy`, `PermissionedWETH` and `PermissionedDelayedWETHProxy` in
`sep/901-U20-whitechain-testnet/addresses.json` and
`sep/902-U21-whitechain-testnet/addresses.json` before simulating either of them.
