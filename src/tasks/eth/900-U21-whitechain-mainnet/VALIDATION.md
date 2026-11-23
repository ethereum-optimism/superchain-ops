# Validation — 900-U21-whitechain-mainnet

Simulated 2026-11-23 against live Ethereum mainnet state (fork block 26478088), PAO Safe nonce 0.
The chain was deployed directly at op-contracts/v8.0.0, so U21 is its **first governance task** and
the first transaction this Safe will ever execute.

## Expected hashes

```
Safe Hash:      0x24d8aee729c76d5a071cd0a414f8f260d76b622918aa39f750c90ddb5a3b2c01
Domain Hash:    0x50b02df597a21632c928b4883a52199b35b1b84c87611d7ccdae6c71aac5f641
Message Hash:   0x35b89690ada726c2f6127d0cac88787c059b34204d8cbf598904678dda951542
```

Data to sign (`0x1901 || domain || message`):

```
0x190150b02df597a21632c928b4883a52199b35b1b84c87611d7ccdae6c71aac5f64135b89690ada726c2f6127d0cac88787c059b34204d8cbf598904678dda951542
```

The Safe transaction hash was confirmed against the live Safe at nonce 0. The task calldata
(2436 bytes) is in [u21-task-calldata.txt](./u21-task-calldata.txt):

```bash
cast call 0x568440132075d4E1c3E42111EF561636f4956eAd \
  "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)(bytes32)" \
  0x93dc480940585D9961bfcEab58124ffD3d60f76a 0 "$(cat u21-task-calldata.txt)" 1 0 0 0 \
  0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 0 \
  --rpc-url "$MAINNET_RPC"
# 0x24d8aee729c76d5a071cd0a414f8f260d76b622918aa39f750c90ddb5a3b2c01
```

**These hashes are valid only at nonce 0.** If the Safe signs anything else first, regenerate.

The Safe is v1.5.0 (3-of-5) and all five owners are plain EOAs: no EIP-7702 delegations, so the
testnet's `MultisigTask.sol` patch is not needed here (it is inert if present).

## State changes

**8 accounts, 17 storage slots.** No balance changes. One new contract is deployed: an ETHLockbox
proxy, predicted at `0x85f1ce8C641Bdd333bffFe0aC095a3229A9f73f7`. `0x3608…2bbc` is the ERC-1967
implementation slot, `0xb531…6103` the ERC-1967 admin slot.

Every implementation address below is byte-identical to the Whitechain Sepolia U21 task (sep/902,
executed 2026-11-23 in tx `0xb8d6155cc51b36020911d04ff59582086003e08c9b7f5bb0b342364af1f8bb6b`):
the v9 implementations are deployed deterministically on both networks.

### `0x85f1ce8C641Bdd333bffFe0aC095a3229A9f73f7` — the NEW ETHLockbox proxy

The OPCM deploys it because `portal.ethLockbox()` is zero. Confirm the address from
`portal.ethLockbox()` after execution. The portal holds 0 ETH (custom gas token chain), so nothing
moves. NOTE: the original chain deployment left an **unwired** ETHLockbox proxy at
`0xBEDFe5233e7A57Ef396ba7B4292BE32A7782097D` (version 1.3.1). The OPCM only reads
`portal.ethLockbox()`, so that proxy is ignored, stays unreferenced, and does not appear in this
diff.

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x…00` | `0x0` | `0x1` | initialized |
| `0x…03` | `0x0` | `0x35aB61eE…D886` | `superchainConfig` → the chain's SuperchainConfig |
| `0x3608…2bbc` | `0x0` | `0xDF75E6b0…0aFe` | implementation → ETHLockbox 2.0.0 |
| `0xe45fe94c…e652` | `0x0` | `0x1` | `authorizedPortals[portal]` = true |
| `0xb531…6103` | `0x0` | `0x9419a571…96c7` | admin → the chain's ProxyAdmin |

```bash
cast index address 0x0665f74e013b7FCcfDa6dAF8951bAf3C982a3864 1   # 0xe45fe94c…e652
```

### `0x1D761826ad3098D10f6dDfbd143957Aaf2b6e50C` — SystemConfigProxy

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x3608…2bbc` | `0x670b850A…71fA` | `0xADe27248…4377` | implementation → SystemConfig 4.3.0 |
| `0x58e88e94…d806` | `0x0` | `0x1` | `isFeatureEnabled[ETH_LOCKBOX]` = true |
| `0x99f45962…ff42` | `0xc19cbd02…1277` | `0x2d91e6F2…331f` | `systemconfig.opcm` → the v9 OPCM (before: the v8 OPCM the chain was deployed with) |

```bash
cast index bytes32 $(cast format-bytes32-string ETH_LOCKBOX) 0x6d   # 0x58e88e94…d806
```

The L1 `SystemConfig.minBaseFee()` is 0 on this chain, so slot `0x6c` reads as a bare
SuperchainConfig address; it is not touched either way. (The chain's effective 5 gwei base fee
floor lives in the node/genesis config, not in L1 storage; on testnet the 5 gwei was also written
into this slot.)

### Lockbox wired into the portal, AnchorStateRegistry and DelayedWETH

| Account | Key | Before | After | Meaning |
|---|---|---|---|---|
| `0x0665f74e…3864` OptimismPortalProxy | `0x3608…2bbc` | `0x1005217a…6748` | `0xb20B23af…9645` | implementation → OptimismPortal2 6.1.0 |
| | `0x…3f` | `0x0` | `0x85f1ce8c…73f7` | `ethLockbox` → the new lockbox |
| `0x860801a7…B23a` AnchorStateRegistryProxy | `0x3608…2bbc` | `0x8F40Cc98…B281` | `0x2b27299C…52D0` | implementation → AnchorStateRegistry 4.0.0 |
| | `0x…06` | `0x…6adec337 00000005` | `0x85f1ce8c…73f7 00000000 6adec337 00000005` | lockbox packed above the unchanged retirement timestamp (1792983863, the v8 deployment) and `respectedGameType` 5 |
| `0x99BbebAe…46Fe` DelayedWETHProxy | `0x3608…2bbc` | `0xE440CC08…630e` | `0xF024e963…0e15` | implementation → DelayedWETH 2.0.0 |
| | `0x…05` | `0x0` | `0x85f1ce8c…73f7` | `ethLockbox` → the new lockbox |

### Other changes

| Account | Key | Before → After | Meaning |
|---|---|---|---|
| `0x35aB61eE…D886` SuperchainConfig | `0x3608…2bbc` | `0x5570b1f2…7504` → `0xA303a644…01e7` | SuperchainConfig 2.5.0 |
| `0x7b806b8A…eb49` AddressManager | `0x5152…385e` | `0x59d49753…86f0` → `0x7d4ec7fb…9448` | `OVM_L1CrossDomainMessenger` → L1CrossDomainMessenger 2.13.0 |
| `0x56844013…6eAd` ProxyAdminOwner Safe | `0x…05` | `0` → `1` | Safe nonce increment |

The DisputeGameFactory is not written: game type 5 stays registered with the same implementation
and args. The anchor root is not written either.

## After execution

```bash
RPC=<ethereum mainnet rpc>
SC=0x1D761826ad3098D10f6dDfbd143957Aaf2b6e50C
PORTAL=0x0665f74e013b7FCcfDa6dAF8951bAf3C982a3864
ASR=0x860801a7766859B82b0B572f75a56d4D3903B23a
SCC=0x35aB61eE5D1C2319d1822A7bE1b6B3FaE98AD886
SAFE=0x568440132075d4E1c3E42111EF561636f4956eAd

cast call $SC "version()(string)" --rpc-url $RPC                  # 4.3.0
cast call $PORTAL "version()(string)" --rpc-url $RPC              # 6.1.0
cast call $ASR "version()(string)" --rpc-url $RPC                 # 4.0.0
cast call $SCC "version()(string)" --rpc-url $RPC                 # 2.5.0
LOCKBOX=$(cast call $PORTAL "ethLockbox()(address)" --rpc-url $RPC); echo $LOCKBOX   # 0x85f1ce8C641Bdd333bffFe0aC095a3229A9f73f7
cast call $LOCKBOX "version()(string)" --rpc-url $RPC             # 2.0.0
cast call $LOCKBOX "authorizedPortals(address)(bool)" $PORTAL --rpc-url $RPC   # true
cast balance $LOCKBOX --rpc-url $RPC                              # 0
cast call $ASR "respectedGameType()(uint32)" --rpc-url $RPC       # 5
cast call $ASR "getAnchorRoot()(bytes32,uint256)" --rpc-url $RPC  # unchanged
cast call $SC "isCustomGasToken()(bool)" --rpc-url $RPC           # true
cast call $SAFE "nonce()(uint256)" --rpc-url $RPC                 # 1
```

Then update pause tooling to use `$LOCKBOX` as the pause identifier. See
[README.md](./README.md), section "Component changes".
