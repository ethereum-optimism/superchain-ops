# 105-mmzd-l1-ownership-transfers

Status: [READY TO SIGN]

## Objective

Transfers L1 ownership — `ProxyAdmin` and `DisputeGameFactory` — of **Metal
Sepolia** (chainId 1740), **Mode Sepolia** (919), **Zora Sepolia** (999999999)
and **Dust Testnet** (55377) from the L1 ProxyAdminOwner Safe to the chain
operator's Safe `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2`, in a single task.
This is the Sepolia counterpart of
[eth/067-mmzd-l1-ownership-transfers](../../eth/067-mmzd-l1-ownership-transfers/README.md)
and the L1 half of the handover; the L2 half is
[106-mmzd-l2pao-transfer](../106-mmzd-l2pao-transfer/README.md), which executes
after this task.

| Chain | Contract | Current owner | New owner |
|---|---|---|---|
| Metal Sepolia | ProxyAdmin `0xF7Bc4b3a78C7Dd8bE9B69B3128EEB0D6776Ce18A` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Metal Sepolia | DisputeGameFactoryProxy `0xd9A68F90B2d2DEbe18a916859B672D70f79eEbe3` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Mode Sepolia | ProxyAdmin `0xE7413127F29E050Df65ac3FC9335F85bB10091AE` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Mode Sepolia | DisputeGameFactoryProxy `0x7Bb634B42373A87712Da14064deD13Db8b8b14f4` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Zora Sepolia | ProxyAdmin `0xE17071F4C216Eb189437fbDBCc16Bb79c4efD9c2` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Zora Sepolia | DisputeGameFactoryProxy `0xA983A71253Eb74e5E86A4E4eD9F37113FC25f2BF` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Dust Testnet | ProxyAdmin `0x068881bd385BD917DdD9370f0DBFa19C969340D4` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |
| Dust Testnet | DisputeGameFactoryProxy `0x157814873342A0f4D6758D69fdF11C4C40c01ed5` | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO) | `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2` |

The receiving Safe is a 1-of-1 Gnosis Safe v1.3.0 on Sepolia (sole owner
`0x23BA22Dd7923F3a3f2495bB32a6f3c9b9CD1EC6C`) — weaker than the mainnet
receiving Safe's 4-of-10, as expected for a testnet. It was designated by the
chain operator (Conduit), confirmed through an authenticated channel during
task preparation (operator address document plus email record), and already
owns the Metal, Mode, Zora and Dust `SystemConfigProxy` contracts on Sepolia.
Ownership transfers are irreversible.

There is no DelayedWETH transfer on any chain (the contracts are v1.5.0 and not
ownable) and no SuperchainConfig or SystemConfig change — those are for the
operator to execute once it holds the ProxyAdmin.

## Simulation & Signing

Nested task: run each command with the child safe you sign through.

```bash
cd src/tasks/sep/105-mmzd-l1-ownership-transfers

just simulate-stack sep 105-mmzd-l1-ownership-transfers council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 105-mmzd-l1-ownership-transfers council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the
calldata breakdown, the expected state changes and the post-execution checks.
