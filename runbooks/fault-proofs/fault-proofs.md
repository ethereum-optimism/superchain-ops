# Key Handover Runbook

This document describes how to generate upgrade playbooks to upgrade chains from `op-contracts/v1.3.0` (MCP) to `op-contracts/v1.X.0` (Fault Proofs).

## Context

One of the requirement for getting to Stage, 1 as defined by [L2Beat](https://medium.com/l2beat/introducing-stages-a-framework-to-evaluate-rollups-maturity-d290bb22befe) is having a, "the implementation of a fully functional proof system, decentralization of [fault] proof submission."

> [!IMPORTANT]
> In addition to the L1 smart contracts, chain operators must be running [op-challeger](https://docs.optimism.io/builders/chain-operators/tools/op-challenger) to defend the chain against invalid L2 state root proposals and have [monitoring](https://github.com/ethereum-optimism/monitorism/tree/main) in place.

## Upgrade Process

### Setup

#### **Local Machine**

First, let’s make sure you have all the right repos and tools on your machine. Start by cloning the repos below and checking out the latest main branch unless stated otherwise. Then, follow the repo setup instructions for each.

1. https://github.com/ethereum-optimism/superchain-ops
    1. Follow the installation instructions in the README: https://github.com/ethereum-optimism/superchain-ops?tab=readme-ov-file#installation
    2. Then, run `just install`.
2. https://github.com/ethereum-optimism/superchain-registry
    1. No setup steps.
3. Ensure you have a Tenderly account.

#### Familiarize yourself with the `single.just` file (superchain-ops repo)

There are three just recipes in this file:

- `simulate` - to simulate the transactions in the the `input.json` bundle
- `sign` - to sign the transactions in the `input.json` bundle
- `execute` - to execute the transactions in the `input.json` bundle

We use `single.just` because the ProxyAdmin owners are regular Safe’s. (For OP Mainnet we use `nested.just` because the ProxyAdmin owner is a Safe, where both owners are also Safes).

### Scaffold the ops task (playbook) for your upgrade (superchain-ops repo)

#### Create a task directory in superchain-ops

```bash
mkdir tasks/<NETWORK_DIR>/<RUNBOOK_DIR>
```

In the superchain-ops repo, tasks live in `tasks/<NETWORK_DIR>/<RUNBOOK_DIR>` where:

- `NETWORK_DIR` is `eth` for Ethereum mainnet and `sep` for Sepolia.
- `RUNBOOK_DIR` is of the form `{chainName}-{upgradeIndex}-{upgradeName}`.
    - `chainName` is just the chain’s name i.e. `base` . This is excluded for OP Chains.
    - `upgradeIndex` starts at `001` for the first playbook and increments each time. This gives a sequential ordering to upgrade transactions occurring on that chain.
    - `upgradeName` is `fault-proofs`

#### Copy the following files into the task directory

Please create the following files in the task directory and update the placeholder values.

- [README.md](./README.md)
- [.env](./.env)
- [SignFromJson.s.sol](./SignFromJson.s.sol)
- [VALIDATION.md](./VALIDATION.md)

`README.md`: The README template with an overview of the upgrade task. This needs to be updated with the network details.

`.env`: These are the enviornment variables for the upgrade.

- The `ETH_RPC_URL` can be from [PublicNode](https://ethereum.publicnode.com/) or your own node provider.
- The `OWNER_SAFE` can be found with `cast call $ProxyAdmin "owner()(address)" -r $RPC_URL` or from the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/tree/main). In other words, the`OWNER_SAFE` corresponds to the ProxyAdmin owner. You should *always* run that `cast` command to verify what address should be there.
- The `SAFE_NONCE` can be found using `getSafeDetails()` from mds1’s [Ethereum helper functions](https://gist.github.com/mds1/3f070676129a095dec372c2d02cedfdd#file-ethrc-sh-L181-L230).

`SignFromJson.s.sol`: This solidity script will generate the Tenderly validation link.

`Validation.md`: The validation template. 

### Generate the `input.json` (todo)



### Simulate and Validate (todo)

Now your task folder is prepared. Navigate into that directory and execute the following command:

```
SIMULATE_WITHOUT_LEDGER=1 just \                    
  --dotenv-path .env \
  --justfile ../../../single.just \
  simulate
```

If all goes well, your output should look similar to this:

```bash

```

- Copy the entire `https://dashboard.tenderly.co/....` URL and paste it into your browser.
  - Make sure to include the `contractAddress`, `storage`, `key`, `value`, `contractAddress`, and `storage` parameters.
    - Note: Due to the data in this URL, you cannot just click the link from some terminals (like VSCode’s) directly. Instead you will have to highlight the whole link and copy/paste it.
- The tenderly UI will ask you to select a project—select any one.
- Scroll down and click the “Simulate Transaction” button.
- In the part that looks like the image below, sanity check these values. For example, make sure the block number is close to the latest block for the chain, ensure the sender is correct, and that the gas used seems sensible.
- Please make sure that the `Data to sign` matches what you see in the simulation and on your hardware wallet. This is a critical step that must not be skipped. Copy the `Data to sign:` from your terminal output and search the Tenderly Simulated Transaction and ensure its there.
- Then click the “State” tab at the top to see the state diff. 

#### Update Validation.md (todo)

Update the validation file to match the tenderly simulation user interface.

- Use the superchain registry to find the chain’s addresses. Look for the file will be located at `superchain/configs/mainnet/{network}/{chainName}.toml`.
- Replace all of the placeholder values.
- Ensure the order of the state changes match Tenderly.
- Ensure the etherscan links are correct.

### Add New Chain to CircleCI (todo)

Before the task is executed, it should be added to the CircleCI config to ensure it continues to pass even as changes are made to the repo prior to execution.

Add the following to the `jobs` in the `.circleci/config.yml` file:

```yml
just_simulate_[eth or sep]-[chain-name]-[index]-key-handover:
    docker:
      - image: <<pipeline.parameters.ci_builder_image>>
    steps:
      - checkout
      - run:
          name: just simulate [eth or sep]/[chain-name]-[index]-key-handover
          command: |
            go install github.com/mikefarah/yq/v4@latest
            just install
            cd tasks/[eth or sep]/[chain-name]-[index]-key-handover
            export SIMULATE_WITHOUT_LEDGER=1
            just \
            --dotenv-path $(pwd)/.env \
            --justfile ../../../single.just \
            simulate
```

The add the following to the workflows.main.jobs section at the bottom:

```
- just_simulate_[eth or sep]-[chain-name]-[index]-key-handover
```

### Open PR

Once the task folder has been prepared, you can open a PR with the following 
information:

```md
pr title: tasks([eth or sep]/[chain-short-name]) <chain-name> key handover

**Description**

<chain-name> Key Handover task has been prepared.
```

### Sign

Follow steps 4 and 5 in `SINGLE.md`

### Facilitators Execute

Ensure you properly fill out your `.env` file and follow the last section of the `SINGLE.md` file.

### Post Execution

#### superchain-ops (todo)

Once the task is executed, the job can be removed from CI and the task status 
should be updated to: `[EXECUTED](block-explorer-transaction-execution-link)`.
Then opening a PR to the repo with the following information:

```md
pr title: <chain-name> Key Handover Executed

**Description**

The <chain-name> key handover task has been executed.
```

#### superchain-registry (todo)

The Superchain Registry needs to be updated. You can do that by modifying the 
`ProxyAdminOwner` in the `superchain/configs/<superchain-target>/<chain-short-name>.toml` 
and then running `just codegen` from the root of the repository. Then opening
a PR to the repo with the following information:

```md
pr title: <chain-name> key handover executed

**Description**

- The <chain-name> Key Handover [task](<merged-task>)
- I've updated the ProxyAdminOwners for the network to the new owner, the same one as OP <Mainnet or Sepolia>. I did this by modifying the `superchain/configs/sepolia/<chain-short-name>.toml` and then running `just codegen`.
```
