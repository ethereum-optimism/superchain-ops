> 🚨 Deprecation Notice (Effective Q1 2025)
> We’re migrating all task definitions from the old superchain-ops repo (`tasks/`) into the new improvements repo (`src/improvements/tasks/`).
>
> • New tasks: please use the [improvements flow](./src/improvements) and refer to the [README](./src/improvements/README.md) for more information.
> • Need help? Reach out in [#superchain-ops](https://discord.com/channels/1244729134312198194/1342572064175030293) on Discord.
>
> The old flow will be retired as soon as we don't need the old tasks anymore.

# superchain-ops

This repo contains execution code and artifacts related to superchain deployments and other tasks.

This repo is structured with each network having a high level directory which contains sub directories of any "tasks" which have occured on that network.

Tasks include:

- new contract deployments
- contract upgrades
- onchain configuration changes

Effectively any significant change to the state of the network, requiring authorization to execute, should be considered a task.

## Directory structure

Top level directory names should be the [EIP-3770](https://eips.ethereum.org/EIPS/eip-3770) short name for the network (see [shortNameMapping.json](https://chainid.network/shortNameMapping.json))

Each task should contain the following:

- `README.md`: A brief markdown file describing the task to be executed.
- `Validation.md`: A markdown file describing and justifying the expected state changes for manual validation by multisig signers.
- A foundry script that implements post upgrade assertions, depending on the nature of the ceremony it should be called either:
  - `SignFromJson.s.sol`: If the ceremony is for a Safe owned by EOA signers.
  - `NestedSignFromJson.s.sol`: If the ceremony is for a Safe owned by other Safe's.
- `input.json`: A JSON file which defines the specific transaction for the task to be executed. This file may either be generated automatically or manually created.
- `.env`: a place to store environment variables specific to this task.

## Installation

The following instructions are for MacOS, but should be similar for other operating systems.

For each of these steps, if you already have some version of the software installed, it should be safe to skip it.

### Installing mise

Make sure you have `mise` installed. Follow the [CONTRIBUTING.md](./CONTRIBUTING.md) guide to install mise. We use mise to install the other required tools (go, just, foundry, etc).

### Installing git

Very likely you have git on your system. To verify this, open a Terminal and type `git --version`.
If an error message shows, these are the steps to download and install it:

1. Go to the official Git website at https://git-scm.com/downloads
1. Download the appropriate installer for your operating system.
1. Run the installer and follow the instructions.
1. Once the installation is complete, open a command prompt or Git Bash and type `git --version`. You should see the version number of Git that you just installed.

### Installing the Rust Toolchain

1. Visit the rust toolchain installer website at https://rustup.rs
1. Follow the instructions for your operating system to install `rustup`, and use `rustup` to install the Rust toolchain.
1. Verify the installation from the command prompt:
  Type `cargo --version`.
  You should see a version number.

### Cloning the superchain-ops repo

The superchain-ops repo holds the tools and artifacts that define any on-chain actions taken to
either upgrade our system, or modify its configuration.

1. Clone the superchain-ops repo
  `git clone https://github.com/ethereum-optimism/superchain-ops.git`
1. Or if you’ve already cloned, just pull the main branch:
  `git checkout main`
 	`git pull`

Move into the repo and install the contract dependencies

`just install-contracts`

### Create a Tenderly account

Tenderly is used to simulate transactions.
If you don’t already have a Tenderly account, go to https://dashboard.tenderly.co/login and sign up.
The free account is sufficient.

## Creating a Task

Each task in the `tasks` directory should contain all of the information required to both validate
and perform the network interaction. To validate that the intention of the network interaction is
correct, specific contextual information must be included in `Validation.md` that enables signers
to double check the correctness. This includes linking to authoritative sources such as the
[superchain-registry](https://github.com/ethereum-optimism/superchain-registry), the [Optimism monorepo](https://github.com/ethereum-optimism/optimism), and
[Etherscan](https://etherscan.io) to prove the correctness of particular configuration values.

The base scripts for performing network interactions found in the `script` directory should be
inherited by the `SignFromJson.s.sol` or `NestedSignFromJson.s.sol` file where the `_postCheck` hook
is implemented. This function must make assertions on the post-transaction state of the network
interaction. It will run each time that a signer generates a signature, giving additional automation
on validating the correctness of the network interaction.
