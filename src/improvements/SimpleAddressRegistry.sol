// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {StdChains} from "forge-std/StdChains.sol";

/// @notice This contract provides a simple key-value store for addresses which are read in from
/// the config TOML file. It expects an `[addresses]` section in the `config.toml` file, with each key
/// being the identifier for the address, and the value being the address.
contract SimpleAddressRegistry is StdChains {
    using stdToml for string;

    address private constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm private constant vm = Vm(VM_ADDRESS);

    /// @notice Maps a key to an address.
    mapping(string => address) internal addresses;

    /// @notice Given an address, returns the key.
    mapping(address => string) internal keys;

    /// @notice Initializes the contract by loading addresses from the TOML config file.
    constructor(string memory _configPath) {
        string memory chainKey;
        if (block.chainid == getChain("mainnet").chainId) chainKey = ".eth";
        else if (block.chainid == getChain("sepolia").chainId) chainKey = ".sep";
        else if (block.chainid == getChain("optimism").chainId) chainKey = ".oeth";

        if (bytes(chainKey).length > 0) _loadHardcodedAddresses(chainKey);

        string memory toml = vm.readFile(_configPath);
        if (!toml.keyExists(".addresses")) return; // If the addresses section is missing, do nothing.

        string[] memory _identifiers = vm.parseTomlKeys(toml, ".addresses");
        for (uint256 i = 0; i < _identifiers.length; i++) {
            string memory key = _identifiers[i];
            address who = toml.readAddress(string.concat(".addresses.", key));

            _registerAddress(key, who);
        }
    }

    /// @notice Retrieves an address by its contract identifier.
    function get(string memory _identifier) public view returns (address who_) {
        who_ = addresses[_identifier];
        require(who_ != address(0), string.concat("SimpleAddressRegistry: address not found for ", _identifier));
    }

    /// @notice Retrieves a contract identifier by an address.
    function get(address _who) public view returns (string memory identifier_) {
        identifier_ = keys[_who];
        require(
            bytes(identifier_).length > 0,
            string.concat("SimpleAddressRegistry: identifier not found for ", vm.toString(_who))
        );
    }

    /// @notice Reads in hardcoded addresses from the addresses.toml file and registers them.
    function _loadHardcodedAddresses(string memory chainKey) internal {
        string memory toml = vm.readFile("./src/improvements/addresses.toml");
        string[] memory keyStrings = vm.parseTomlKeys(toml, chainKey);

        for (uint256 i = 0; i < keyStrings.length; i++) {
            string memory key = keyStrings[i];
            address who = toml.readAddress(string.concat(chainKey, ".", key));

            _registerAddress(key, who);
        }
    }

    /// @notice Registers an address with a key.
    function _registerAddress(string memory key, address who) internal {
        require(bytes(key).length > 0, "SimpleAddressRegistry: empty key");
        require(who != address(0), string.concat("SimpleAddressRegistry: zero address for ", key));
        require(addresses[key] == address(0), string.concat("SimpleAddressRegistry: duplicate key ", key));
        require(bytes(keys[who]).length == 0, string.concat("SimpleAddressRegistry: address already registered ", key));

        addresses[key] = who;
        keys[who] = key;
        vm.label(who, key);
    }
}
