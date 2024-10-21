<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Superchain Presigned Pause](#superchain-presigned-pause)
  - [Objective](#objective)
    - [Ensure no gaps with PSPs coverage](#1-ensure-no-gaps-with-psps-coverage)
  - [Approving the transaction](#approving-the-transaction)
    - [1. Update repo and move to the appropriate folder for this rehearsal task](#1-update-repo-and-move-to-the-appropriate-folder-for-this-rehearsal-task)
    - [2. Setup Ledger](#2-setup-ledger)
    - [3. Sign the transactions](#3-sign-the-transactions)
      - [3.1. Validate integrity of the simulation.](#31-validate-integrity-of-the-simulation)
      - [3.2. Validate correctness of the state diff.](#32-validate-correctness-of-the-state-diff)
      - [3.3. Extract the domain hash and the message hash to approve.](#33-extract-the-domain-hash-and-the-message-hash-to-approve)
    - [4. Approve the signature on your ledger](#4-approve-the-signature-on-your-ledger)
    - [5. Send the output to Facilitator(s)](#5-send-the-output-to-facilitators)
  - [[Before Ceremony] Instructions for the facilitator](#before-ceremony-instructions-for-the-facilitator)
    - [1. Update input files](#1-update-input-files)
    - [2. Prepare the transactions](#2-prepare-the-transactions)
  - [[After Ceremony] Instructions for the facilitator](#after-ceremony-instructions-for-the-facilitator)
    - [1. Collect the signatures](#1-collect-the-signatures)
    - [2. Merge the signatures](#2-merge-the-signatures)
    - [3. Verify the signatures](#3-verify-the-signatures)
    - [4. Simulate the transaction with signatures](#4-simulate-the-transaction-with-signatures)
    - [5. Store and execute the transaction](#5-store-and-execute-the-transaction)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Superchain Presigned Pause

## Objective

This task is intended to generate pre-signed transactions to pause
ETH, ERC20, ERC721 withdrawals across the Superchain. Deposits and L2
state progression will not be impacted by the pause, only withdrawals.

The call that will be executed by the Safe contract is defined in a
json file. This will be the standard approach for all transactions.

Note that no onchain actions will be taking place during this
signing. You won’t be submitting a transaction and your address
doesn’t even need to be funded. These are offchain signatures.

A Facilitator will collect the signatures and execute the contract.

### Ensure no gaps with PSPs coverage

We need to ensure there is no gaps in the PSPs coverage during upgrade.
Upgrades to certain components of the system can invalidate existing PSPs and cause them to no longer work, thus we need to ensure before the upgrade that PSPs coverage continues without a gap.
In this case of breaking changes, we need to simulate the PSPs against the **new changes** and presign the new PSPs against these **new changes**.
This will allow us to have continuous PSP coverage before, during, and after the upgrade.

> [!WARNING]  
> This will require to making some **overrides** in _superchains-ops_ tasks to simulate successfully with the new changes. We already had to do this for the PSPs in the [task 017](https://github.com/ethereum-optimism/superchain-ops/blob/main/tasks/eth/017-presigned-pause/PresignPauseFromJson.s.sol)

Additionally, if there is another entity that depends on the PSPs, we need to share these before the upgrade occurs.

## Approving the transaction

### 1. Update repo and move to the appropriate folder for this rehearsal task

In addition to the general tools installed when you clone/update the
repo and run `just install` at the root of the repo, this ceremony
also requires a `presigner` tool, which can be installed by running
the following command at the ceremony folder:

```shell
cd superchain-ops
git pull
just install
just clean
cd tasks/<NETWORK_DIR>/<RUNBOOK_DIR>
just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../presigned-pause.just \
   install
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message “Application
is ready”.

Check your address is correct by running the following command

```
just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../presigned-pause.just \
   whoami 0
```

Where `0` is the index of the address you want to use in the derivation path.

You should see the output similar to the following:

```
Signer: 0x8C835568fE7Eea01B6DCD79214aB5BCe5E1759B0
```

If this is not the address you are expecting,
you can change the index of the address you want to use, i.e.

```
just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../presigned-pause.just \
   whoami 1
```

### 3. Sign the transactions

The transactions to be signed are inside the `tx` folder named `draft-{nonce}.json`

If you have an `ETH_RPC_URL` already set in your environment, unset it.
This is required so the one in the `.env` file takes precedence.

```shell
unset ETH_RPC_URL
```

You can sign them by running the following commands:

```
just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../presigned-pause.just \
   sign 0
```

Where `0` is the index of the address you want to use in the derivation path.

For each transaction we will be performing 3 validations
and ensure the domain hash and message hash are the same
between the Tenderly simulation and your
Ledger:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.

#### 3.1. Validate integrity of the simulation.

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to

1. "Network": Check the network is the correct one.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not,
   you will need to determine which “number” it is in the list of
   addresses on your ledger.

Here is an example screenshot, note that the Timestamp and Sender
might be different in your simulation:

![](images/tenderly-overview-network.png)

#### 3.2. Validate correctness of the state diff.

Now click on the "State" tab. Verify that:

1. Under address `SuperchainConfig` contract
   address([mainnet](https://github.com/ethereum-optimism/superchain-registry/blob/77a930120ec63dd50c43483c82b1a0a29939ed27/superchain/configs/mainnet/superchain.yaml#L8),
   [sepolia](https://github.com/ethereum-optimism/superchain-registry/blob/77a930120ec63dd50c43483c82b1a0a29939ed27/superchain/configs/sepolia/superchain.yaml#L8)),
   the storage key
   `0x54176ff9944c4784e5857ec4e5ef560a462c483bf534eda43f91bb01a470b1b6`'s
   value is changed from `0x00` to `0x01`. This is indicating that the
   `paused` variable is successfully changed from `false` to `true`. The
   storage key hash is evaluated from the following expression:
   `bytes32(uint256(keccak256("superchainConfig.paused")) - 1)` per the
   `SuperchainConfig` [implementation](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.5.0-rc.1/packages/contracts-bedrock/src/L1/SuperchainConfig.sol#L19).
2. There are no other significant state changes except for 2 nonce
   changes from the Safe and the signer address.
3. You will see a state override (not a state change). This is
   expected and its purpose is to generate a successful Safe execution
   simulation without collecting any signatures.

Here is an example screenshot. Note that the addresses may be
different:

![](images/tenderly-state-changes-presigned-pause.png)

#### 3.3. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right
operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Overview" tab, and find the first
`GnosisSafe.domainSeparator` call. This call's return value will be
the domain hash that will show up in your Ledger.

Here is an example screenshot. Note that the hash value may be
different:

![](images/tenderly-hashes-1.png)

Right before the `GnosisSafe.domainSeparator` call, you will see a
call to `GnosisSafe.encodeTransactionData`. Its return value will be a
concatenation of `0x1901`, the domain hash, and the message hash:
`0x1901[domain hash][message hash]`.

Here is an example screenshot. Note that the hash value may be
different:

![](images/tenderly-hashes-2.png)

Note down both the domain hash and the message hash. You will need to
compare them with the ones displayed on the Ledger screen at signing.

### 4. Approve the signature on your ledger

Once the validations are done, approve the transaction in your Ledger.

> [!IMPORTANT] This is the most security critical part of the
> playbook: make sure the domain hash and message hash in the
> following two places match:

1. on your Ledger screen.
2. in the Tenderly simulation. You should use the same Tenderly
   simulation as the one you used to verify the state diffs, instead
   of opening the new one printed in the console.

There is no need to verify anything printed in the console. There is
no need to open the new Tenderly simulation link either.

After verification, sign the transaction. You will see the `Data`,
`Signer` and `Signature` printed in the console. Format should be
something like this:

```
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Double check the signer address is the right one.

### 5. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which
will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a
Facilitator will do the final execution for convenience.

The signed transactions are in the `tx` folder. They will be named
according to the address used to sign, i.e.
`tx/draft-92.signer-0x8c78B948Cdd64812993398b4B51ed2603b3543A6.json`
was signed by `0x8c78B948Cdd64812993398b4B51ed2603b3543A6`. Share
these 3 files with the Facilitator, and congrats, you are done!

## [Before Ceremony] Instructions for the facilitator

### 1. Update input files

Update `.env` and `input.json` in the ceremony folder with the right
values.

### 2. Prepare the transactions

First, navigate into the task directory and create an empty `tx` folder.
This is where the transactions to sign will be written.

```shell
cd tasks/<NETWORK_DIR>/<RUNBOOK_DIR>
mkdir tx
```

If you have an `ETH_RPC_URL` already set in your environment, unset it.
This is required so the one in the `.env` file takes precedence.

```shell
unset ETH_RPC_URL
```

Now, prepare the transactions by running the following command.
The `FOUNDRY_SENDER` and `TEST_SENDER` environment variables should be the same,
and set to any address on the Safe that we are preparing the presigned pause for.
An example address from the Sepolia Foundation Safe is used below:

```shell
SIMULATE_WITHOUT_LEDGER=1 \
FOUNDRY_SENDER=0xF0871b2F75ecD07e2D709b7a2cc0AF6848c1cE76 \
TEST_SENDER=0xF0871b2F75ecD07e2D709b7a2cc0AF6848c1cE76 \
just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../presigned-pause.just \
   prepare
```

## [After Ceremony] Instructions for the facilitator

The Facilitator will collect the signatures, merge the signatures,
verify, simulate and execute the contract.

### 1. Collect the signatures

The signed transactions are in the `tx` folder.
They will be named according to the address used to sign, i.e.
`tx/draft-92.signer-0x8c78B948Cdd64812993398b4B51ed2603b3543A6.json`
was signed by `0x8c78B948Cdd64812993398b4B51ed2603b3543A6`.

All signatures should be present in the same transaction file before execution,
so next we'll merge them.

### 2. Merge the signatures

To merge the signatures, run the following command:

```
just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../presigned-pause.just \
   merge
```

This will overwrite the original `draft-*.json` files with the all merged signatures.

You can check the file contents with the following command:

```
cat tx/draft-*.json | jq
```

### 3. Verify the signatures

To verify the signatures, run the following command:

```
just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../presigned-pause.just \
   verify
```

### 4. Simulate the transaction with signatures

WARNING: do not simulate using public tenderly projects, anyone who
can see the simulation will be able to extract the signature and
execute the pause!

To simulate the transaction, run the following command:

```
just \
   --dotenv-path $(pwd)/.env \
   --justfile ../../../presigned-pause.just \
   simulate-all
```

The simulate command will output the Tenderly simulation link, new
`ready-*` json files and a `.sh.b64` script for further execution.

Files with prefix `ready-` are transactions fully signed and ready
to be executed.

The additional file with extension `.sh.b64` is a one-liner script,
which can be quickly executed from command line.

### 5. Store and execute the transaction

Please refer to the [internal playbook](https://www.notion.so/oplabs/RB-111-Pre-signed-pause-8bce5b27728b447aa51ba12fcfff9e58?pvs=4#a227c38a09e14518b26095baa91f81c8)
for how to store the presigned pause and executed it in emergency situations.
