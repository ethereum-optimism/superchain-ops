# Address Registry

The address registry contract stores contract addresses on a single network. On construction, it reads in all of the configurations from the specified TOML configuration file. This TOML configuration file tells the address registry which L2 contracts to read in and store. As an example, if a task only touched the OP Mainnet contracts, the TOML file would only have a single entry:

```toml
l2chains = [{name = "OP Mainnet", chainId = 10}]
```

## Usage

The Address Registry provides several methods to interact with stored addresses:

### getAddress
```solidity
function getAddress(string memory identifier, uint256 l2ChainId) external view returns (address)
```
Returns the address associated with the given identifier on the specified chain. If the contract does not exist, the function will revert. If the l2ChainId is unsupported by this address registry instance, the function will revert.

### isAddressContract
```solidity
function isAddressContract(string memory identifier, uint256 l2ChainId) external view returns (bool)
```
Returns true if the address associated with the given identifier is a contract on the specified chain.

### isAddressRegistered
```solidity
function isAddressRegistered(string memory identifier, uint256 l2ChainId) external view returns (bool)
```
Returns true if an address exists for the given identifier on the specified chain.

### getChains
```solidity
function getChains() external view returns (ChainInfo[] memory)
```
Returns an array of supported chains and their configurations.
