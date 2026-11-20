# Validation — 902-U21-whitechain-testnet

Simulated 2026-11-20 against live Sepolia state, PAO Safe nonce 7, after U20 (sep/901) executed in
tx `0xa19e8ed99e63ca694fd7ace3cc56d4c0c61fc0f5f38acfdf8d009cb94576de1c`.

## Expected hashes

```
Safe Hash:      0xbbce2066cb93a8ff2f63b3a35227fff4f050437b71a9f84e458d2c860f6776d0
Domain Hash:    0x51f29ca0551362b92587cd685e062d74d8f6189c847da73569ffd14f97ab1552
Message Hash:   0x67e3926e91f72a0a6e85a60e2bce5af2e072d83dbd1c9e16ddee5c218bd94e28
```

Data to sign (`0x1901 || domain || message`):

```
0x190151f29ca0551362b92587cd685e062d74d8f6189c847da73569ffd14f97ab155267e3926e91f72a0a6e85a60e2bce5af2e072d83dbd1c9e16ddee5c218bd94e28
```

The Safe transaction hash was confirmed against the live Safe at nonce 7. The task calldata
(2436 bytes) is in [u21-task-calldata.txt](./u21-task-calldata.txt):

```bash
cast call 0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85 \
  "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)(bytes32)" \
  0x93dc480940585D9961bfcEab58124ffD3d60f76a 0 "$(cat u21-task-calldata.txt)" 1 0 0 0 \
  0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 7 \
  --rpc-url "$SEPOLIA_RPC"
# 0xbbce2066cb93a8ff2f63b3a35227fff4f050437b71a9f84e458d2c860f6776d0
```

**These hashes are valid only at nonce 7.** If the Safe signs anything else first, regenerate.

Two of the three Safe owners carry an EIP-7702 delegation, which `MultisigTask.sol` misreads as a
nested Safe. `just simulate` needs the local patch that treats 23-byte `0xef0100…` code as an EOA.
The patch does not affect the calldata or the hashes; the `cast call` above proves that.

## State changes

**8 accounts, 17 storage slots.** No balance changes. One new contract is deployed: an ETHLockbox
proxy, predicted at `0xa06F6AB459ddd8Ac8dF644F462b7D80c749F7FEE`. `0x3608…2bbc` is the ERC-1967
implementation slot, `0xb531…6103` the ERC-1967 admin slot.

### `0xa06F6AB459ddd8Ac8dF644F462b7D80c749F7FEE` — the NEW ETHLockbox proxy

The OPCM deploys it because `portal.ethLockbox()` is zero. Confirm the address from
`portal.ethLockbox()` after execution. The portal holds 0 ETH (custom gas token chain), so nothing
moves.

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x…00` | `0x0` | `0x1` | initialized |
| `0x…03` | `0x0` | `0x11854d31…426e` | `superchainConfig` → the chain's SuperchainConfig |
| `0x3608…2bbc` | `0x0` | `0xDF75E6b0…0aFe` | implementation → ETHLockbox 2.0.0 |
| `0xac36ba48…1c37` | `0x0` | `0x1` | `authorizedPortals[portal]` = true |
| `0xb531…6103` | `0x0` | `0x1E46b85e…3a7A` | admin → the chain's ProxyAdmin |

```bash
cast index address 0xFF9b597b0781457ae6aa7256Ca5ed5839bF7D0C3 1   # 0xac36ba48…1c37
```

### `0x9328Ea869949f33c57B7b680B6EdB58769e2181c` — SystemConfigProxy

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x3608…2bbc` | `0x670b850A…71fA` | `0xADe27248…4377` | implementation → SystemConfig 4.3.0 |
| `0x58e88e94…d806` | `0x0` | `0x1` | `isFeatureEnabled[ETH_LOCKBOX]` = true |
| `0x99f45962…ff42` | `0x6AbfAbBC…f4Ca` | `0x160f0fe4…39cc` | `systemconfig.opcm` → the v9 OPCM |

```bash
cast index bytes32 $(cast format-bytes32-string ETH_LOCKBOX) 0x6d   # 0x58e88e94…d806
```

`minBaseFee` in slot `0x6c` is not touched.

### Lockbox wired into the portal, AnchorStateRegistry and DelayedWETH

| Account | Key | Before | After | Meaning |
|---|---|---|---|---|
| `0xFF9b597b…D0C3` OptimismPortalProxy | `0x3608…2bbc` | `0x1005217a…6748` | `0xb20B23af…9645` | implementation → OptimismPortal2 6.1.0 |
| | `0x…3f` | `0x0` | `0xa06f6ab4…7fee` | `ethLockbox` → the new lockbox |
| `0x4Da16596…A32c` AnchorStateRegistryProxy | `0x3608…2bbc` | `0x8F40Cc98…B281` | `0x2b27299C…52D0` | implementation → AnchorStateRegistry 4.0.0 |
| | `0x…06` | `0x…6a3100d0 00000005` | `0xa06f6ab4…7fee 00000000 6a3100d0 00000005` | lockbox packed above the unchanged retirement timestamp and `respectedGameType` 5 |
| `0x2e02e6cB…17fe` DelayedWETHProxy | `0x3608…2bbc` | `0xE440CC08…630e` | `0xF024e963…0e15` | implementation → DelayedWETH 2.0.0 |
| | `0x…05` | `0x0` | `0xa06f6ab4…7fee` | `ethLockbox` → the new lockbox |

### Other changes

| Account | Key | Before → After | Meaning |
|---|---|---|---|
| `0x11854D31…426E` SuperchainConfig | `0x3608…2bbc` | `0x5570b1f2…7504` → `0xA303a644…01e7` | SuperchainConfig 2.5.0 |
| `0xa848d05c…9e41` AddressManager | `0x5152…385e` | `0x59d49753…86f0` → `0x7D4ec7fB…9448` | `OVM_L1CrossDomainMessenger` → L1CrossDomainMessenger 2.13.0 |
| `0x044a91B1…cCb85` ProxyAdminOwner Safe | `0x…05` | `7` → `8` | Safe nonce increment |

The DisputeGameFactory is not written: game type 5 stays registered with the same implementation
and args. The anchor root is not written either.

## After execution

```bash
cast call $SC "version()(string)" --rpc-url $RPC                  # 4.3.0
cast call $PORTAL "version()(string)" --rpc-url $RPC              # 6.1.0
cast call $ASR "version()(string)" --rpc-url $RPC                 # 4.0.0
cast call $SCC "version()(string)" --rpc-url $RPC                 # 2.5.0
LOCKBOX=$(cast call $PORTAL "ethLockbox()(address)" --rpc-url $RPC); echo $LOCKBOX   # 0xa06F6AB459ddd8Ac8dF644F462b7D80c749F7FEE
cast call $LOCKBOX "version()(string)" --rpc-url $RPC             # 2.0.0
cast call $LOCKBOX "authorizedPortals(address)(bool)" $PORTAL --rpc-url $RPC   # true
cast balance $LOCKBOX --rpc-url $RPC                              # 0
cast call $ASR "respectedGameType()(uint32)" --rpc-url $RPC       # 5
cast call $ASR "getAnchorRoot()(bytes32,uint256)" --rpc-url $RPC  # unchanged from U20
cast call $SC "isCustomGasToken()(bool)" --rpc-url $RPC           # true
cast call $SC "minBaseFee()(uint64)" --rpc-url $RPC               # 5000000000
cast call $SAFE "nonce()(uint256)" --rpc-url $RPC                 # 8
```

Then update pause tooling to use `$LOCKBOX` as the pause identifier. See
[README.md](./README.md), section "Component changes".
