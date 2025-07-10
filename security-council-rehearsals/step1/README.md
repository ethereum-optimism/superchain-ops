# Rehearsal 1 - Welcome to SuperchainOps

## Objective

This rehearsal is intended simply to ensure that all the signers feel
confident running the tooling and performing the validations required
to execute an onchain action.

Once completed, the WelcomeToSuperchainOps contract will return `"Welcome to SuperchainOps, <name>"` from its `welcome()` method.

The call that will be executed can be found in the `build` function of the `WelcomeToSuperchainOps` template.

Note that no onchain actions will be taking place during this
signing. You won’t be submitting a transaction and your address
doesn’t even need to be funded. These are offchain signatures produced
with your wallet which will be collected by a Facilitator will execute
the contract, submitting all signatures for its execution.

Execution can be finalized by anyone once a threshold of signatures
are collected, so a Facilitator will do the final execution for
convenience.

## Approving the transaction

### 1. Create a new task in the `sep` directory:

```bash
cd superchain-ops/src/improvements
just new task # Follow the prompts to create a new rehearsals task. 
# (a) choose 'sep' 
# (b) choose 'WelcomeToSuperchainOps' 
# (c) press enter for no to 'Is this a nested task?'
# (d) press 'y' for 'Is this a security council rehearsal task?'
# (e) enter a name of the task in the format of '<nnn>-welcome-to-superchain-ops-rehearsal'

# This creates a new directory in the `src/improvements/tasks/sep/rehearsals` directory.
```

Next, make sure your `config.toml` is correct. You should use the TOML below as a starting point.

```toml
templateName = "WelcomeToSuperchainOps"

name = "Satoshi" # Enter your name here if you like.

[addresses]
TargetContract = "0x5c6623738B2a3a54edF1d46B2A85f959fe6b1f6b" # Sepolia deployment of target contract.
```

For sepolia, the Gnosis safe that you will be signing for will be the `SecurityCouncil` safe. Because this task lives in the `sep` directory, the code automatically retrieves the `SecurityCouncil` safe address from the [`addresses.toml`](../../src/improvements/addresses.toml) file.


TODO: Talk about the state changes and the slots: `cast index address 0x1084092ac2f04c866806cf3d4a385afa4f6a6c97 0` -> `0x8b832b208e2b85d2569164b1655368f5b5eddb1c56f6c1acf41053cac08f5141`
