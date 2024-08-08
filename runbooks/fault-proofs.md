# Key Handover Runbook

This document describes how to generate upgrade playbooks to upgrade chains from `op-contracts/v1.3.0` (MCP) to `op-contracts/v1.X.0` (Fault Proofs).

## Upgrades Involved

This runbook will apply the following upgrade:

- [Fault Proofs](#fault-proofs-upgrade-7)

Each upgrade is described below.
The Extended Pause upgrade is only applied to chains currently on the Bedrock commit, corresponding to the [`op-contracts/v1.0.0`](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2Fv1.0.0) tag in the [Optimism monorepo](https://github.com/ethereum-optimism/optimism).

In either case, the upgrade will be a single, atomic transaction.

### Fault Proofs (Upgrade #7)

This protocol upgrade reduces the trust assumptions for users of OP Mainnet 
[and the OP Stack] by enabling permissionless output proposals and a 
permissionless fault proof system. As part of a responsible and safe rollout
of Fault Proofs, it preserves the ability for the guardian to override if 
necessary to maintain security. As a result, withdrawals no longer depend on 
the privileged proposer role posting an output root, allowing the entire 
withdrawal process to be completed without any privileged actions. The trust 
assumption is reduced to requiring only that the guardian role does not act 
to intervene.

Learn more:

- [Faul Proofs release notes](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts/v1.4.0). (This is release `op-contracts/v1.4.0`).
- [Governance post](https://gov.optimism.io/t/final-protocol-upgrade-7-fault-proofs/8161).
- [Blog post](https://blog.oplabs.co/https://blog.oplabs.co/the-fault-proof-system-is-available-for-the-op-stack/).

### Additional Context

One of the requirement for getting to Stage, 1 as defined by [L2Beat](https://medium.com/l2beat/introducing-stages-a-framework-to-evaluate-rollups-maturity-d290bb22befe)
is having a, "the implementation of a fully functional proof system, 
decentralization of [fault] proof submission."

> [!IMPORTANT]
> In addition to the L1 smart contracts, chain operators must be running [op-challeger](https://docs.optimism.io/builders/chain-operators/tools/op-challenger) to defend the chain against invalid L2 state root proposals and have [monitoring](https://github.com/ethereum-optimism/monitorism/tree/main) in place.

## Upgrade Process

### Setup

#### **Local Machine**

First, let’s make sure you have all the right repos and tools on your machine. Start by cloning the repos below and checking out the latest main branch unless stated otherwise. Then, follow the repo setup instructions for each.

1. https://github.com/ethereum-optimism/optimism
   1. Checkout the contract release tag `git checkout op-contracts/v1.4.0`
   2. Run `pnpm clean && pnpm install && cd packages/contracts-bedrock && pnpm build:go-ffi && forge build`
2. https://github.com/ethereum-optimism/superchain-ops
    1. Follow the installation instructions in the README: https://github.com/ethereum-optimism/superchain-ops?tab=readme-ov-file#installation
    2. Then, run `just install`.
3. https://github.com/ethereum-optimism/superchain-registry
    1. No setup steps.
4. https://github.com/clabby/msup
    1. Then, run `cargo build`. 
5. Ensure you have a Tenderly account.

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
    - `upgradeName` is `fp-upgrade`

We'll use the `tasks/sep/mode-001-fp-upgrade` directory as our template.
Start by copying everything over:

```bash
cd tasks/{NetworkDir}

# copy everything from the mode directory into a directory that
# will be created.
cp -R mode-001-fp-upgrade/. {chainName}-001-fp-upgrade

# Delete the input.json file.
cd {chainName}-001-fp-upgrade
rm input.json

# Clean your environment to avoid forge caching issues.
forge clean
```

The `.env` file should look like below. t can be left alone, unless you need 
to change the address of the owner safe. This can be found with `cast call $ProxyAdmin "owner()(address)" -r $SEPOLIA_RPC_URL`,
and the proxy admin address can be found from the superchain registry. In 
other words, the `OWNER_SAFE` corresponds to the proxy admin owner. It’s 
populated with a default value as a result of the `cp` command ran above. 
This account might not actually be the correct proxy admin owner for the 
chain being upgraded, so you should *always* run that `cast` command to 
verify what address should be there.

```bash
ETH_RPC_URL=https://1rpc.io/sepolia # L1 Sepolia RPC URL that has archive data access.
OWNER_SAFE=0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD
SAFE_NONCE=""
```

### Deploy new proxies and implementations (todo)

The chain operator will need deployed the following proxies and implementation 
contracts. After they've completed that, they'll need to share those contract 
addresses.

New proxy addresses we need:

todo: update versions and add links

- DisputeGameFactoryProxy
- AnchorStateRegistryProxy
- DelayedWETHProxy

New implementation addresses we need:

- OptimismPortal2: [3.10.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/L1/OptimismPortal2.sol#L144)
- SystemConfig: [2.2.0](https://github.com/ethereum-optimism/optimism/blob/547ea72d9849e13ce169fd31df0f9197651b3f86/packages/contracts-bedrock/src/L1/SystemConfig.sol#L111)
- DisputeGameFactory: [1.0.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L25)
- FaultDisputeGame: [1.2.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/FaultDisputeGame.sol#L73)
- PermissionedDisputeGame: [1.2.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/PermissionedDisputeGame.sol)
- DelayedWETH: [1.0.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/weth/DelayedWETH.sol#L25)
- AnchorStateRegistry: [1.0.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L28)
- MIPS: [1.0.1](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/cannon/MIPS.sol#L47)
- PreimageOracle: [1.0.0](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/cannon/PreimageOracle.sol#L33)

#### Deploy the Contracts

todo: can we use this?

https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.5.0/packages/contracts-bedrock/scripts/fpac

### Generate the `input.json` (todo)

Use the `msup` tool to generate the safe transaction bundle:

```bash
./target/debug/msup generate --output input.json
```

This will open up a CLI prompt to generate the safe bundle in `input.json`.

```bash
? Number of transactions in the multisig batch:
```

Specify you'll be completing `7` transactions:

1. Upgrade OptimismPortal to StorageSetter
2. Reset l2Sender in OptimismPortalProxy
3. Upgrade the OptimismPortal
4. Upgrade SystemConfig to StorageSetter
5. Clear SystemConfig's L2OutputOracle slot
6. Set SystemConfig's DisputeGameFactory slot
7. Upgrade SystemConfig to 2.2.0

```bash
? Chain ID that the batch transaction will be performed on:
```

Enter `1` for mainnet and `10` for sepolia upgrades.

```bash
? Enter the name of the batch:
```

Enter the following and replace the chain name: FP Upgrade - {Chain Name}

```bash
? Enter the description of the batch:
```

Use the following description: Upgrades the OptimismPortal and SystemConfig implementations

```bash
Transaction #1
? Name:
```

Transaction #1 Name: Upgrade OptimismPortal to StorageSetter

```bash
? Description:
```

Transaction #1 Description: Upgrade OptimismPortal to StorageSetter and reset `initializing`

```bash
? Address of the contract to call:
```

Enter the `OptimismPortalProxy` address.

```bash
? Value to send (in WEI):
```

Enter `0`.

```bash
? Enter the function signature of the contract to call:
```

Enter the following function signature: upgradeAndCall(address _implementation,bytes _data)

```bash
? Enter the value for input #1 (_implementation):
```

Enter the value of the new OptimismPortal implementation contract you deployed.

```bash
? Enter the value for input #2 (_data):
```

todo: whats the data here??

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
