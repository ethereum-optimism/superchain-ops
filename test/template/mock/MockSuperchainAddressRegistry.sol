// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";

/// @notice Stand-in for `SuperchainAddressRegistry`: the chains of the task and one address per key and chain.
contract MockSuperchainAddressRegistry {
    SuperchainAddressRegistry.ChainInfo[] internal chains;
    mapping(string => mapping(uint256 => address)) internal addresses;

    function addChain(uint256 chainId, string memory name) external {
        chains.push(SuperchainAddressRegistry.ChainInfo({chainId: chainId, name: name}));
    }

    function set(string memory identifier, uint256 chainId, address addr) public {
        require(addresses[identifier][chainId] == address(0), "MockSuperchainAddressRegistry: duplicate key");
        addresses[identifier][chainId] = addr;
    }

    function saveAddress(string memory identifier, SuperchainAddressRegistry.ChainInfo memory chain, address addr)
        external
    {
        set(identifier, chain.chainId, addr);
    }

    function getChains() external view returns (SuperchainAddressRegistry.ChainInfo[] memory) {
        return chains;
    }

    function getAddress(string memory identifier, uint256 chainId) external view returns (address addr) {
        addr = addresses[identifier][chainId];
        require(addr != address(0), string.concat("MockSuperchainAddressRegistry: address not found for ", identifier));
    }
}
