# Address Registry

The address registry contract stores contract addresses on a single network. On construction, it reads in all of the configurations from the specified TOML configuration file. This TOML configuration file tells the address registry which L2 contracts to read in and store. As an example, if a task only touched the OP Mainnet contracts, the TOML file would only have a single entry

```toml
[[chains]]
  name = "OP Mainnet"
  chain_id = 10
```

## Usage

Addresses can be fetched by calling the `getAddress(string memory identifier, uint256 l2ChainId)` function. This function will return the address of the contract with the given identifier on the given chain. If the contract does not exist, the function will revert. If the l2ChainId is unsupported by this address registry instance, the function will revert.
