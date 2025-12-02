# 036-U17-main-base: Upgrades Base Mainnet to `op-contracts/v5.0.0` (i.e. U17)

Status: [EXECUTED](https://etherscan.io/tx/0x9b9aa2d8e857e1a28e55b124e931eac706b3ae04c1b33ba949f0366359860993)

## Objective

Upgrade Base Mainnet to U17. More context on U17 can be found in the Optimism docs.

## Step 1. Tenderly Account

Make a free [Tenderly](https://tenderly.co/) account if you don't already have one. We will use this later on for validating the task transaction.

## Step 2. Clone the Repo

Inside a terminal window run:

```bash
git clone https://github.com/ethereum-optimism/superchain-ops.git
```

Note: if you see an error output after running this command stating `fatal: destination path 'superchain-ops' already exists and is not an empty directory.`, then, instead, run the following commands:

```bash
cd superchain-ops
git pull
```

## Step 3. Install & Configure Mise

Install Mise by executing the following commands. When the Bash script runs, follow the instructions in the log output to activate mise in your shell.

```bash
cd src
./script/install-mise.sh
```

Now configure Mise with the following commands:

```bash
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc
mise trust ../mise.toml
mise install
just --justfile ../justfile install
```

If you see a `libusb` warning (`warning: libusb not found...`), you can safely ignore it and continue to the next step.

## Step 4. Setup Ledger

Connect and unlock your Ledger with your 8-digit pin. Open the Ethereum application on your Ledger so that it displays the message "Application is ready". Also, please ensure that blind signing is first enabled on your Ledger.

## Step 5. Base-Nested / Foundation Operations Simulation, Validation, and Signing

Base has a doubly-nested safe architecture which is supported by superchain-ops. You **MUST** ensure the hashes you generate from running the commands below match the documented hashes. If you notice *any* mismatches, please alert your facilitator **immediately**.

```bash
#
#    ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐       ┌─────────────────────────────────────────────┐
#    │                 Base Council                │       │              Base Operations                │       │           Foundation Operations (FOS)       │
#    │                  (7 of 10)                  │       │                 (3 of 6)                    │       │                 (5 of 7)                    │
#    │  0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd │       │  0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110 │       │  0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A │
#    └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘       └─────────────────────┬───────────────────────┘
#                          │                                                     │                                                     │
#                          └─────────────────┬───────────────────────────────────┘                                                     │
#                                            ▼                                                                                         │
#                             ┌─────────────────────────────────────────────┐                                                          │
#                             │                 Base Nested                 │                                                          │
#                             │  0x9855054731540A48b28990B63DcF4f33d8AE46A1 │                                                          │
#                             └─────────────────────┬───────────────────────┘                                                          │
#                                                   │                                                                                  │
#                                                   └─────────────────┬────────────────────────────────────────────────────────────────┘
#                                                                     ▼
#                                            ┌─────────────────────────────────────────────┐
#                                            │               ProxyAdminOwner               │
#                                            │  0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c │
#                                            └─────────────────────────────────────────────┘
```

In this section, you will simulate, validate, and sign the upgrade transactions for the 'base-nested' (`0x9855054731540A48b28990B63DcF4f33d8AE46A1`) path and / or the 'foundation-operations' (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`) path, depending on which safe you are a member of. Both of these safes are required to reach a threshold on the Proxy Admin Owner.

### Step 5.1. Simulation

First, simulate the upgrade transaction using the command below corresponding to the safe you are a member of (Base Council, Base Operations, or Foundations Operations) and take note of the resulting hashes and output:

```bash
cd tasks/eth/036-U17-main-base

# Base Council: 0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd
#  ┌────────────────────┐
#  │ Child Safe Depth 2 │
#  │   'base-council'   │
#  └────────────────────┘
#             │
#             └─────────────────┬
#                               ▼
#                           ┌────────────────────┐
#                           │ Child Safe Depth 1 │
#                           │    'base-nested'   │
#                           └────────────────────┘
#                                      │
#                                      └──────────┬
#                                                 ▼
#                                          ┌─────────────────┐
#                                          │ ProxyAdminOwner │
#                                          └─────────────────┘
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just simulate-stack eth 036-U17-main-base base-nested base-council
# Expected Hashes
# Domain Hash: 0x1fbfdc61ceb715f63cb17c56922b88c3a980f1d83873df2b9325a579753e8aa3
# Message Hash: 0x6d55b9a2f22dbc0280930a2800465d93570c7bcf69747baab4cdb6ab03cb48fa

# Base Operations: 0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110
#  ┌────────────────────┐
#  │ Child Safe Depth 2 │
#  │ 'base-operations'  │
#  └────────────────────┘
#             │
#             └─────────────────┬
#                               ▼
#                           ┌────────────────────┐
#                           │ Child Safe Depth 1 │
#                           │    'base-nested'   │
#                           └────────────────────┘
#                                      │
#                                      └──────────┬
#                                                 ▼
#                                          ┌─────────────────┐
#                                          │ ProxyAdminOwner │
#                                          └─────────────────┘
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just simulate-stack eth 036-U17-main-base base-nested base-operations
# Expected Hashes
# Domain Hash: 0xfb308368b8deca582e84a807d31c1bfcec6fda754061e2801b4d6be5cb52a8ac
# Message Hash: 0xda46ae8404c84e5ab5a1823b3c4b3379a1c610e7f9c5cfd43c3388c88457023d


# Foundation Operations: 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
#                           ┌────────────────────┐
#                           │ Child Safe Depth 1 │
#                           │        'FOS'       │
#                           └────────────────────┘
#                                      │
#                                      └──────────┬
#                                                 ▼
#                                          ┌─────────────────┐
#                                          │ ProxyAdminOwner │
#                                          └─────────────────┘
SIMULATE_WITHOUT_LEDGER=1 SKIP_DECODE_AND_PRINT=1 just simulate-stack eth 036-U17-main-base foundation-operations
# Expected Hashes
# Domain Hash: 0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890
# Message Hash: 0xb509e266fe97416f0dc1820a83c4384e11584d4a166dbb5dca348a2a6ac83929
```

You will see a `Simulation link` in the output (yes, it's a big link). Paste this URL from your terminal in your browser. A prompt may ask you to choose a project, any project will do. You can create one if necessary.

In your terminal output, if you saw text instructing you to `Insert the following hex into the 'Raw input data' field:` after the link, the following 2 additional steps are required:

1. In Tenderly, click the "Enter raw input data" option towards the bottom of the `Contract` component on the left side of your screen.
2. Paste the data string that was output below the `Insert the following hex into the 'Raw input data' field:` text in your terminal into the "Raw input data" field.

Click "Simulate Transaction".

Example link below (just for reference):

```txt
https://dashboard.tenderly.co/TENDERLY_USERNAME/TENDERLY_PROJECT/simulator/new?network=1&contractAddress=0xcA11bde05977b3631167028862bE2a173976CA11&from=0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38&stateOverrides=%5B%7B"contractAddress":"0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd","storage":%5B%7B"key":"0x0000000000000000000000000000000000000000000000000000000000000004","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D,%7B"key":"0x0000000000000000000000000000000000000000000000000000000000000003","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D,%7B"key":"0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0","value":"0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11"%7D,%7B"key":"0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D%5D%7D,%7B"contractAddress":"0x9855054731540A48b28990B63DcF4f33d8AE46A1","storage":%5B%7B"key":"0x0000000000000000000000000000000000000000000000000000000000000004","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D%5D%7D,%7B"contractAddress":"0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c","storage":%5B%7B"key":"0x0000000000000000000000000000000000000000000000000000000000000004","value":"0x0000000000000000000000000000000000000000000000000000000000000001"%7D%5D%7D%5D
```

### Step 5.2. Validation Overview

Now, we will perform 3 validations, as well as extract the domain and message hashes to be approved later on your Ledger:

1. Validate the integrity of the simulation.
2. Validate the correctness of the state diff.
3. Validate and extract the domain and message hashes for approval.

> [!NOTE]
> Ensure you have "Dev Mode" turned on in Tenderly for these validations. This switch is usually located towards the top right of the Tenderly UI.

### Step 5.3. Validate Integrity of the Simulation

Make sure you are on the "Summary" tab of the Tenderly simulation. To validate the integrity of the simulation, we need to check the following:

1. "Network": Check that the network is Mainnet.
2. "Timestamp": Check that the simulation is performed on a block with a recent timestamp (i.e. close to when you ran the script). You can double-check the timestamp by inputting the block number [here](https://etherscan.io/blocks).

### Step 5.4. Validate Correctness of the State Diff

Now click on the "State" tab.

Please ensure that you verify all state diffs listed in the "Task State Changes" section.

Once you have completed the verification checks corresponding to your role, return to this document to continue the process.

### Step 5.5. Extract The Domain and Message Hashes for Approval

Now that we have verified that the transaction performs the right operation, we need to extract the domain and message hashes for approval.

Go back to the "Summary" tab in the Tenderly UI, and find the `Safe.checkSignatures` call. This call's `data` parameter contains both the domain hash and the message hash that will show up on your Ledger (and are also listed in the "Expected Domain and Message Hashes" section of your respective State Validation instructions in [Step 3.1.4 above](#Step-314-Validate-correctness-of-the-state-diff)).

This `data` field will consist of a concatenation of `0x1901`, the domain hash, and the message hash, in the format: **`0x1901[domain hash][message hash]`**.

Confirm that these values match the values listed in the "Expected Domain and Message Hashes" section of your respective State Validation instructions in [Step 3.1.4 above](#Step-314-Validate-correctness-of-the-state-diff) and note them down. You will need to compare these values with the ones displayed on your Ledger screen when signing in [Step 3.1.6 below](#Step-316-Signing).

### Step 5.6. Signing

Now, perform the signing for whichever of the safes you are a member of:

```bash
cd src/tasks/eth/036-U17-main-base

just --dotenv-path $(pwd)/.env sign base-nested base-council
# Expected Hashes
# Domain Hash: 0x1fbfdc61ceb715f63cb17c56922b88c3a980f1d83873df2b9325a579753e8aa3
# Message Hash: 0x6d55b9a2f22dbc0280930a2800465d93570c7bcf69747baab4cdb6ab03cb48fa

just --dotenv-path $(pwd)/.env sign base-nested base-operations
# Expected Hashes
# Domain Hash: 0xfb308368b8deca582e84a807d31c1bfcec6fda754061e2801b4d6be5cb52a8ac
# Message Hash: 0xda46ae8404c84e5ab5a1823b3c4b3379a1c610e7f9c5cfd43c3388c88457023d

just --dotenv-path $(pwd)/.env sign foundation-operations
# Expected Hashes
# Domain Hash: 0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890
# Message Hash: 0xb509e266fe97416f0dc1820a83c4384e11584d4a166dbb5dca348a2a6ac83929
```

> **⚠️ Attention Signers:**
> Once you've signed, please send your signature(s) to the designated ceremony facilitator.

As a signer (on the Base Council, Base Operations, or Foundations Operations), the procedure for you is now complete.
