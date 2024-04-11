# EOA Execution

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Simulating and Verifying the Transaction](#simulating-and-verifying-the-transaction)
  - [1. Update repo and move to the appropriate folder for this task](#1-update-repo-and-move-to-the-appropriate-folder-for-this-task)
  - [2. Setup Ledger](#2-setup-ledger)
  - [3. Simulate and validate the transaction](#3-simulate-and-validate-the-transaction)
    - [3.1. Validate integrity of the simulation](#31-validate-integrity-of-the-simulation)
    - [3.2. Validate correctness of the state diff](#32-validate-correctness-of-the-state-diff)
- [[For EOA Private Key Holder ONLY] Execute the Transaction](#for-eoa-private-key-holder-only-execute-the-transaction)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Simulating and Verifying the Transaction

### 1. Update repo and move to the appropriate folder for this task

```sh
cd superchain-ops
git pull
just install
cd tasks/<NETWORK_DIR>/<RUNBOOK_DIR>
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following command.

**Note:** Remember that by default the script will assume the derivation path of your address is `m/44'/60'/0'/0/0`.
If you wish to use a different account, append an `X` to the command to set the derivation path of
the address that you want to use. For example by adding a `1` to the end, it will derive the address
using `m/44'/60'/1'/0/0` instead.

If you are not the private key holder and are just validating the transaction, you can
prepend the below command with `SIMULATE_WITHOUT_LEDGER=1`.

```shell
# To simulate the transaction as the proxy admin owner key holder.
just \
   --dotenv-path .env \
   --justfile ../../../eoa.just \
   simulate \
   0 # or 1 or ...
```

```shell
# To simulate the transaction as as a validator that does not hold the private key.
SIMULATE_WITHOUT_LEDGER=1 just \
   --dotenv-path .env \
   --justfile ../../../eoa.just \
   simulate
```

You will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 2 validations on your Ledger:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.

#### 3.1. Validate integrity of the simulation

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is Ethereum mainnet or Sepolia. This must match the `<NETWORK_DIR>` from above.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not see the derivation path Note above.
![Tenderly simulation overview](./images/tenderly-overview-network.png)

#### 3.2. Validate correctness of the state diff

Now click on the "State" tab, and refer to the "State Validations" instructions for the transaction you are signing.
Once complete return to this document to complete the signing.

## [For EOA Private Key Holder ONLY] Execute the Transaction

> [!WARNING]
> Because we're executing from an EOA, we are unable to batch transactions. This means each
> transaction in the `transactions` array of a task's `input.json` file is executed as its own
> standalone transaction, unlike with Safe executions where they are all bundled into a single,
> atomic transaction.
>
> A consequence of this is that it's possible that after a few successfully broadcast transactions,
> one may fail. If this happens, determine and resolve the issue, the use the second command below
> to resume the failed execution. For example, if the failure was because the account ran out of ETH
> to pay for gas, top up the account and then run the second command below.

Once the validations are done, it's time to actually sign and execute the
transaction. Make sure your ledger is still unlocked and run the
following to broadcast the transaction:

```shell
just \
   --dotenv-path .env \
   --justfile ../../../eoa.just \
   execute \
   0 # or 1 or ...
```

Double check the signer address is the right one.

As mentioned in the warning above, if a transaction fails, you can resume the broadcast by
modifying the command by appending `resume` as shown below:

```shell
just \
   --dotenv-path .env \
   --justfile ../../../eoa.just \
   execute \
   0 \ # or 1 or ...
   resume
```
