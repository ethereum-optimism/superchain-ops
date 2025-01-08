pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

/// this can be used to avoid duplication in TOML files and reduce errors
contract NetworkMapper is Test {
    /// @notice Network configuration struct
    struct NetworkConfig {
        uint256 l2ChainId;
        string name;
    }

    /// @notice mapping from chainId to network config
    mapping(uint256 => NetworkConfig) private _chainIdToConfig;

    /// @notice mapping from network name to network config
    mapping(string => NetworkConfig) private _nameToConfig;

    constructor(string memory filePath) {
        bytes memory content = bytes(vm.readFile(filePath));
        NetworkConfig[] memory configs = abi.decode(content, (NetworkConfig[]));

        for (uint256 i = 0; i < configs.length; i++) {
            NetworkConfig memory config = configs[i];

            _chainIdToConfig[config.l2ChainId] = config;
            _nameToConfig[config.name] = config;
        }
    }
}
