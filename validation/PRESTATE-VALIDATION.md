# Validation - Prestates

This document describes the required steps to validate an absolute prestate hash ("prestate").  Prestates are used in 
`FaultDisputeGame.sol` and `PermissionedDisputeGame.sol` contracts to define the program that will be loaded by Cannon.
The referenced program should be a valid release of `op-program`.

## Releases.json
All `op-program` releases are documented in
[standard-prestates.toml in the superchain-registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml).

For example, here is a subset of documented releases:
```toml
[[prestates."1.4.0"]]
type = "cannon64"
hash = "0x03b7eaa4e3cbce90381921a4b48008f4769871d64f93d113fcadca08ecee503b"

[[prestates."1.4.0"]]
type = "cannon32"
hash = "0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568"

[[prestates."1.4.0-rc.3"]]
type = "cannon64"
hash = "0x03b7eaa4e3cbce90381921a4b48008f4769871d64f93d113fcadca08ecee503b"

[[prestates."1.4.0-rc.3"]]
type = "cannon32"
hash = "0x03f89406817db1ed7fd8b31e13300444652cdb0b9c509a674de43483b2f83568"
```

There are a few features to notice here:
* Each "hash" field is a prestate.
* Finalized releases are formatted as `<major>.<minor>.<patch>`. For example: `1.4.0`.
* Release candidates are formatted as `<major>.<minor>.<patch>-rc.<counter>`. For example: `1.4.0-rc.3`.
* Each entry has a "type" field:
  * If this is set to "cannon64", this defines a 64-bit program meant for [64-bit Multithreaded Cannon](https://specs.optimism.io/experimental/cannon-fault-proof-vm-mt.html). These programs must execute on `MIPS64.sol`.
  * If this is set to "cannon32", this defines a 32-bit program meant for the [original 32-bit Cannon FPVM](https://github.com/ethereum-optimism/specs/blob/86d043705a7eb65295e15feaeea248fda38b9b8a/specs/fault-proof/cannon-fault-proof-vm.md).  These programs must execute on `MIPS.sol`.

## Calculating the absolute prestate

To calculate the prestates associated with a given `op-program` release (for example `1.5.0-rc.2`):
* Navigate to the root of your local [optimism repo](https://github.com/ethereum-optimism/optimism):
  ```shell
    cd optimism
  ```
* Check out your target `op-program` release version tag:
  ```shell
    git fetch <remote> --tags
    git checkout <release-tag>
  ```
  For example:
  ```shell
    git fetch origin --tags
    git checkout op-program/v1.5.0-rc.2
  ```
* Run the `reproducible-prestate` task to generate the `op-program` prestates at this tag:
  ```shell
    make reproducible-prestate
  ``` 
  This will print a bunch of output and then at the end you'll see the calculated prestates, which will look something like:
  ```shell
  Cannon Absolute prestate hash: 
  0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd
  Cannon64 Absolute prestate hash:
  0x03a7d967025dc434a9ca65154acdb88a7b658147b9b049f0b2f5ecfb9179b0fe
  ```
  * The "Cannon" hash is the 32-bit prestate.
  * The "Cannon64" hash is the 64-bit prestate.
* Verify that your target prestate was calculated as expected and matches the corresponding entry in
  [standard-prestates.toml](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-prestates.toml).
