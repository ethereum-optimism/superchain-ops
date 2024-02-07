# Technical Process for Superchain L1 Contract Changes

## Goal

The goal of this document is to outline the techinical process to
perform Superchain L1 contract changes.

## Non-goals

There are non-techinical components in the Superchain L1 Contract
change process, such as govenance voting. We will mention some of them
in this document if needed for techinical completeness and clarity,
but we will not specify any details about them, or not mentioned them
at all if they are irrelevant to the techinical process.

## Process and Owners

### 1. Development of the L1 contract changes.

Owner: Feature Team

We use the term "feature team" to refer to the team responsible for
the development of the L1 contract changes (including both code and
configuration), for example, the Ecotone team (for updating gas config
on L1), the extended pause feature team (for proxy implementation
updates), the MCP L1 feature team, and the fault proof feature team.

### 2. Development of the OP Testnet and Mainnet change tooling and configs.

Owner: Feature Team

Specifically, the feature team is responsible for creating a new
multisig ceremony under `/tasks/sep/` (template, example) with
satisfactory playbooks for OP Sepolia, and `/tasks/eth/` for OP
Mainnet.

### 3. Execution of OP Testnet changes

Owner: Feature Team

Once the testnet playbooks are marked as `READY_TO_SIGN`. The feature
team is responsible for coordinating with
[signers](https://github.com/ethereum-optimism/safe-wallets/tree/main/wallets)
of the OP Testnet multisigs to sign and execute the transactions.

### 4. Execution of OP Mainnet changes

Owner: Foundation Multisig Facilitator

Once the mainnet playbooks are marked as `READY_TO_SIGN`, a Foundation
multisig facilitator and the Security Council lead will
[coordiante](https://docs.google.com/document/d/1VBmCh2FNukP95xmeX6Nb_fnvX4IlWTSlf47SrrWeTnA/edit)
the sigining and execution of the transactions.

### 5. Development of change tooling and configs for all chains in the Superchain Registry.

TBD

### 6. Execution of changes for all chains in the Superchain Registry.

TBD
