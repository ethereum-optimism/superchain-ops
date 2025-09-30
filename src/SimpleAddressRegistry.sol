// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {Utils} from "src/libraries/Utils.sol";

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

        if (bytes(chainKey).length > 0) _loadHardcodedAddresses(chainKey);

        string memory toml = vm.readFile(_configPath);
        if (!toml.keyExists(".addresses")) return; // If the addresses section is missing, do nothing.

        string memory allowOverwriteKey = ".allowOverwrite";
        string[] memory allowOverwrite;
        if (toml.keyExists(allowOverwriteKey)) {
            allowOverwrite = toml.readStringArray(allowOverwriteKey);
        }

        string[] memory _identifiers = vm.parseTomlKeys(toml, ".addresses");
        for (uint256 i = 0; i < _identifiers.length; i++) {
            string memory key = _identifiers[i];
            address who = toml.readAddress(string.concat(".addresses.", key));
            _registerAddress(key, who, allowOverwrite);
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
    function _loadHardcodedAddresses(string memory _chainKey) internal {
        string memory toml = vm.readFile("./src/addresses.toml");
        string[] memory keyStrings = vm.parseTomlKeys(toml, _chainKey);

        for (uint256 i = 0; i < keyStrings.length; i++) {
            string memory key = keyStrings[i];
            address who = toml.readAddress(string.concat(_chainKey, ".", key));

            _registerAddress(key, who, new string[](0));
        }
    }

    /// @notice Registers an address with a key.
    function _registerAddress(string memory _key, address _who, string[] memory _allowOverwrite) internal {
        require(bytes(_key).length > 0, "SimpleAddressRegistry: empty key");
        require(_who != address(0), string.concat("SimpleAddressRegistry: zero address for ", _key));
        // If we have overwrites, then we should check if we are allowed to overwrite the current address.
        if (!Utils.contains(_allowOverwrite, _key)) {
            require(addresses[_key] == address(0), string.concat("SimpleAddressRegistry: duplicate key ", _key));
        }
        require(
            bytes(keys[_who]).length == 0, string.concat("SimpleAddressRegistry: address already registered ", _key)
        );

        addresses[_key] = _who;
        keys[_who] = _key;
        vm.label(_who, _key);
    }
}
