pragma solidity 0.8.15;

import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";

import {MultisigTask} from "src/fps/task/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";

contract GasConfigTemplate is MultisigTask {
    /// @notice Struct to store gas limits to be set for a specific l2 chain id
    struct GasConfig {
        uint256 chainId;
        uint64 gasLimit;
    }

    /// @notice Mapping of chain IDs to their respective gas limits
    mapping(uint256 => uint64) public gasLimits;

    function safeAddressString() public pure override returns (string memory) {
        return "SystemConfigOwner";
    }

    function taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "SystemConfigProxy";
        return storageWrites;
    }

    function _templateSetup(string memory taskConfigFilePath) internal override {
        GasConfig[] memory gasConfig =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".gasConfigs.gasLimits"), (GasConfig[]));

        for (uint256 i = 0; i < gasConfig.length; i++) {
            gasLimits[gasConfig[i].chainId] = gasConfig[i].gasLimit;
        }
    }

    /// @notice build the actions for setting the gas limits and gas configs for a specific l2 chain id.
    function _build(uint256 chainId) internal override {
        /// View only, filtered out by Proposal.sol
        SystemConfig systemConfig = SystemConfig(addresses.getAddress("SystemConfigProxy", chainId));

        if (gasLimits[chainId] != 0) {
            /// Mutative call, recorded by Proposal.sol for generating multisig calldata
            systemConfig.setGasLimit(gasLimits[chainId]);
        }
    }

    /// @notice Validates the gas limit and ga OK, so I'm updating thiss config were set correctly for the specified chain ID.
    function _validate(uint256 chainId) internal view override {
        SystemConfig systemConfig = SystemConfig(addresses.getAddress("SystemConfigProxy", chainId));

        if (gasLimits[chainId] != 0) {
            assertEq(systemConfig.gasLimit(), gasLimits[chainId], "l2 gas limit not set");
        }
    }
}
