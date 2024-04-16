# Mainnet MCP L1 Upgrade

Status: DRAFT

## Objective

This is the playbook for executing the OP Sepolia Exit Window changes. These changes bring the OP
Sepolia roles into alignment with our plans for OP Mainnet.

1. The owner of the L1 ProxyAdmin becomes a new Safe. This multisig is a 2 of 2 controlled by two
   Safe contracts.
1. Those two Safe contracts are:
    - `FoundationMockSafe`: this safe is the current ProxyAdmin owner. It will represent the mainnet
      Safe which is controlled by the Optimism Foundation.
    - `SecurityCouncilMockSafe`: A new Safe which will represent the mainnet safe which is
      controlled by the Security Council.
1. Additionally, the `SecurityCouncilMockSafe` will have to modules and a guard ([documented
   here](https://github.com/ethereum-optimism/specs/blob/maur/sc-safe-specs/specs/experimental/security-council-safe.md))
   registered on it to enforce certain security guarantees.

Note that the thresholds for both Safes on Sepolia will be lower than on Mainnet in order to reduce
overhead.

## Signing and execution

Please see the signing and execution instructions in [NESTED.md](../../../NESTED.md).

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Continue signing

At this point you may resume following the signing and execution instructions in section 3.3 of [NESTED.md](../../../NESTED.md).
