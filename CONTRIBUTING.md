# Superchain-Ops Contributing Guide

Welcome to the Superchain-Ops Contributing Guide!
Before diving into the specifics of this repository, know that you should always feel free to report issues in this repository.
Great bug reports are detailed and give clear instructions for how a developer can reproduce the problem.
Write good bug reports and developers will love you.

> [!IMPORTANT]
> If you believe your report impacts the security of this repository, refer to the canonical [Security Policy](https://github.com/ethereum-optimism/.github/blob/master/SECURITY.md) document from the Optimism monorepo.

## Developer Quick Start

### Setting Up

Clone the repository and open it:
```bash
git clone https://github.com/ethereum-optimism/superchain-ops
cd superchain-ops
```

### Software Dependencies

You will need to install a number of software dependencies to effectively contribute to the
Optimism Monorepo. We use [`mise`](https://mise.jdx.dev/) as a dependency manager for these tools.
Once properly installed, `mise` will provide the correct versions for each tool. `mise` does not
replace any other installations of these binaries and will only serve these binaries when you are
working inside of the `optimism` directory.

#### Install `mise`

> ⚠️ **IMPORTANT**: **Do not** update `mise` to a newer version unless you're told to do so by the maintainers of this repository. We pin to specific allowed versions of `mise` to reduce the likelihood of installing a vulnerable version of `mise`.

**Step 1: Install and activate `mise`**

To run an installation of `mise` you **must use** the following script. We want a local, static version of the script to reduce the likelihood of installing a vulnerable version of `mise`.

```bash
./src/improvements/script/install-mise.sh
```

Verify the installation:

```bash
~/.local/bin/mise --version
```

To ensure `mise` works correctly, you must activate it in your shell, which sets up the proper environment for your tools (like forge, just, go, etc.).

After running the installation script above, you will see the following log output:

```bash
mise: installing mise...
#################### 100.0%
mise: installed successfully to /Users/<username>/.local/bin/mise
mise: run the following to activate mise in your shell:
echo "eval \"\$(/Users/<username>/.local/bin/mise activate zsh)\"" >> "/Users/<username>/.zshrc"

mise: run `mise doctor` to verify this is setup correctly
```

You must follow the remaining instructions in the log output to fully activate mise in your shell (i.e. add the eval command to your shell profile). Please note, the log output may be different for you depending on your shell.


**Step 2: Verify your setup**

Run:
```sh
mise doctor
```
You should see:

```yaml
activated: yes
```
If that’s true, you’re all set. For full instructions, see the official [mise docs](https://github.com/jdx/mise).


**Step 3: Trust the `mise.toml` file**

`mise` requires that you explicitly trust the `mise.toml` file which lists the dependencies that
this repository uses. After you've installed `mise` you'll be able to trust the file via:

```bash
mise trust mise.toml
```

**Step 4: Install dependencies**

Use `mise` to install the correct versions for all of the required tools:

```bash
mise install
```

`mise` will notify you if any dependencies are outdated. Simply run `mise install` again to install
the latest versions of the dependencies if you receive these notifications.

### Building the repo

You must install all of the required [Software Dependencies](#software-dependencies) to build the
repo. Once you've done so, run the following command to build:

```bash
just install
```

### Running tests

Before running tests: **follow the above instructions to get everything built**.
Once done, you can run tests as follows:

```bash
cd src/improvements/
just test # Run this command before asking for a review on any PR.
```

## Contributions Related to Spelling and Grammar

At this time, we will not be accepting contributions that primarily fix spelling, stylistic or grammatical errors in documentation, code or elsewhere.

Pull Requests that ignore this guideline will be closed, and may be aggregated into new Pull Requests without attribution.

## Code of Conduct

Interactions within this repository are subject to a [Code of Conduct](https://github.com/ethereum-optimism/.github/blob/master/CODE_OF_CONDUCT.md) adapted from the [Contributor Covenant](https://www.contributor-covenant.org/version/1/4/code-of-conduct/).
