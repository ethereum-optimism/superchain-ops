# 104-reca-standard-game-types

Status: DRAFT, NOT READY TO SIGN

## Objective

Configure the Standard non-super-root dispute-game shape for Recyclefarm Carbon Network
Sepolia (`chainId = 82696765`) through the Sepolia L1 ProxyAdminOwner.

The task calls the Sepolia `op-contracts/v7.1.17` OPCMv2 and:

- installs `CANNON` (game type 0) with the Standard Cannon prestate;
- rewires `PERMISSIONED_CANNON` (game type 1) with the same prestate and RECA proposer;
- installs `CANNON_KONA` (game type 8) with the Standard Kona prestate;
- leaves super-root and ZK game types 4, 5, 9, and 10 disabled;
- sets a 0.08 ETH initial bond for each enabled game type; and
- preserves `PERMISSIONED_CANNON` (1) as the respected game type.

This is intentionally a staged configuration. It does **not** rotate the respected game
type. The rotation is a separate Guardian action and must wait until the currently proven
withdrawals finalize and both valid- and invalid-claim challenger tests pass.

> [!IMPORTANT]
> The current U19 default for permissionless chains is Kona (8) with legacy Cannon (0)
> disabled. This task retains Cannon (0) because the submitted RECA acceptance plan asks
> reviewers to validate both proof paths before a later respected-game decision. Foundation
> and Security Council reviewers should explicitly approve or reject that exception.

RECA is not yet in the public Superchain Registry, so the task uses a checked-in fallback
address file sourced from its deployment artifacts and live L1 getters.

## Expected state changes

The OPCMv2 upgrade path re-runs the current v7.1.17 initializers across the RECA L1 stack.
Core implementation addresses and loaded configuration values remain unchanged. The material
changes are limited to the DisputeGameFactory. The already-deployed shared DelayedWETH at
`0x12cc5e5ecfacb64aa427e6d707431e5d5a67ad79` is reused and has no net storage change:

| Field | Before | After |
|---|---:|---:|
| `gameImpls(0)` | zero | v7.1.17 FaultDisputeGame implementation |
| `gameImpls(1)` | v7.1.17 PermissionedDisputeGame | rewired with Standard Cannon prestate |
| `gameImpls(8)` | zero | v7.1.17 CannonKona implementation |
| `initBonds(0)` | 0 | 0.08 ETH |
| `initBonds(1)` | 0.08 ETH | 0.08 ETH |
| `initBonds(8)` | 0 | 0.08 ETH |
| `AnchorStateRegistry.respectedGameType()` | 1 | 1 |

Existing dispute-game instances are not modified.

The pinned fork produces exactly 15 DisputeGameFactory slot changes plus the expected root
Safe nonce increment. `VALIDATION.md` maps every raw slot to its logical field and value.

## Simulation & signing

```bash
# Simulate the root L1PAO transaction.
just simulate-stack sep 104-reca-standard-game-types

# Review/sign through either owner path after independent validation.
just simulate-stack sep 104-reca-standard-game-types council
just simulate-stack sep 104-reca-standard-game-types foundation
```

Do not sign or execute until the live L1PAO, Security Council, and Foundation Safe nonces
have been re-checked and the hashes in `VALIDATION.md` have been regenerated.
