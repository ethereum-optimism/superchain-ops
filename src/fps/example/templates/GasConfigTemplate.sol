pragma solidity 0.8.15;

import {SystemConfig} from "src/fps/example/ISystemConfig.sol";
import {MultisigProposal} from "src/fps/proposal/MultisigProposal.sol";
import {NetworkTranslator} from "src/fps/utils/NetworkTranslator.sol";
import {AddressRegistry as Addresses} from "src/fps/AddressRegistry.sol";
import {BASE_CHAIN_ID, OP_CHAIN_ID, ADDRESSES_PATH} from "src/fps/utils/Constants.sol";

contract GasConfigTemplate is MultisigProposal {
    /// @notice Struct to store gas limits to be set for a specific l2 chain id
    struct GasConfig {
        uint256 chainId;
        uint64 gasLimit;
    }

    /// @notice Mapping of chain IDs to their respective gas limits
    mapping(uint256 => uint64) public gasLimits;

    /// @notice Struct to store gas configuration to be set for a specific l2 chain id
    struct SetGasConfig {
        uint256 l2ChainId;
        uint256 overhead;
        uint256 scalar;
    }

    /// @notice Mapping of L2 chain IDs to their respective gas configuration settings
    mapping(uint256 => SetGasConfig) public setGasConfigs;

    /// @notice Runs the proposal with the given task and network configuration file paths. Sets the address registry, initializes the proposal and processes the proposal.
    /// @param taskConfigFilePath The path to the task configuration file.
    /// @param networkConfigFilePath The path to the network configuration file.
    function run(string memory taskConfigFilePath, string memory networkConfigFilePath) public {
        Addresses _addresses = new Addresses(ADDRESSES_PATH, networkConfigFilePath);

        _init(taskConfigFilePath, networkConfigFilePath, _addresses);

        GasConfig[] memory gasConfig =
            abi.decode(vm.parseToml(vm.readFile(networkConfigFilePath), ".gasConfigs.gasLimits"), (GasConfig[]));

        for (uint256 i = 0; i < gasConfig.length; i++) {
            gasLimits[gasConfig[i].chainId] = gasConfig[i].gasLimit;
        }

        SetGasConfig[] memory setGasConfig =
            abi.decode(vm.parseToml(vm.readFile(networkConfigFilePath), ".gasConfigs.gasScalars"), (SetGasConfig[]));

        for (uint256 i = 0; i < setGasConfig.length; i++) {
            setGasConfigs[setGasConfig[i].l2ChainId] = setGasConfig[i];
        }

        processProposal();
    }

    /// @notice build the actions for setting the gas limits and gas configs for a specific l2 chain id.
    function _build(uint256 chainId) internal override {
        /// View only, filtered out by Proposal.sol
        SystemConfig systemConfig = SystemConfig(addresses.getAddress("SystemConfigProxy", chainId));

        if (gasLimits[chainId] != 0) {
            /// Mutative call, recorded by Proposal.sol for generating multisig calldata
            systemConfig.setGasLimit(gasLimits[chainId]);
        }

        if (setGasConfigs[chainId].l2ChainId != 0) {
            systemConfig.setGasConfig(setGasConfigs[chainId].overhead, setGasConfigs[chainId].scalar);
        }
    }

    /// @notice Validates the gas limit and gas config were set correctly for the specified chain ID.
    function _validate(uint256 chainId) internal view override {
        SystemConfig systemConfig = SystemConfig(addresses.getAddress("SystemConfigProxy", chainId));

        if (setGasConfigs[chainId].l2ChainId != 0) {
            assertEq(systemConfig.overhead(), setGasConfigs[chainId].overhead, "overhead not set");
            assertEq(systemConfig.scalar(), setGasConfigs[chainId].scalar, "scalar not set");
        }

        if (gasLimits[chainId] != 0) {
            assertEq(systemConfig.gasLimit(), gasLimits[chainId], "l2 gas limit not set");
        }
    }
}
