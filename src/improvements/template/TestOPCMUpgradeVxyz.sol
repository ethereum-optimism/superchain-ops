pragma solidity ^0.8.0;

import {OPCMBaseTask} from "../tasks/OPCMBaseTask.sol";
import {AddressRegistry} from "src/improvements/AddressRegistry.sol";

/// @notice This is an example of implementing OPCMBaseTask to perform an upgrade via the OPCM contract.
/// @dev OPCM upgrade tasks always target a specific l1 contract release version and therfore OPCM contract.
contract TestOPCMUpgradeVxyz is OPCMBaseTask {
    address public constant OPCM = 0x5BC817c7C3F1A8dCAA01d229Cbdeed9624C80E09;

    /// @notice Struct to store inputs for OPCM.upgrade() function per l2 chain
    /// THIS IS AN EXAMPLE STRUCT for the case where the only per-chain input is the absolute prestate.
    /// MODIFY THIS for a specific OPCM instance.
    /// @param chainId The ID of the L2 chain
    /// @param prestate The prestate to be set for the l2 chain
    struct OPCMUpgrade {
        uint256 chainId;
        bytes32 prestate;
    }

    /// @notice Mapping of l2 chain IDs to their respective prestates
    mapping(uint256 => bytes32) public opcmUpgrades;

    /// @notice Returns the OPCM address
    /// overrides the OPCMBaseTask function to return the correct OPCM address
    /// Every OPCMUpgradeTemplate MUST IMPLEMENT THIS FUNCTION to return the correct OPCM address
    /// @return The address of the OPCM
    function opcm() public pure override returns (address) {
        return OPCM;
    }

    /// @notice Returns the storage write permissions
    /// currently used OPCM is a dummy so no storage writes are needed
    /// update this function to return all the storage writes permissions
    /// required as per the OPCM contract.
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](0);
        return storageWrites;
    }

    /// @notice Sets up the template with prestate inputs from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        OPCMUpgrade[] memory opcmUpgrade =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".opcmUpgrades.opcmPrestates"), (OPCMUpgrade[]));

        for (uint256 i = 0; i < opcmUpgrade.length; i++) {
            opcmUpgrades[opcmUpgrade[i].chainId] = opcmUpgrade[i].prestate;
        }
    }

    /// @notice build the task action for all l2chains in the task
    /// in a single call to the OPCM.upgrade() function.
    function _buildSingle() internal override {
        AddressRegistry.ChainInfo[] memory chains = addrRegistry.getChains();
        OpChainConfig[] memory opcmConfigs = new OpChainConfig[](chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            opcmConfigs[i] = OpChainConfig({
                systemConfigProxy: addrRegistry.getAddress("SystemConfigProxy", chains[i].chainId),
                proxyAdmin: addrRegistry.getAddress("ProxyAdmin", chains[i].chainId),
                absolutePrestate: opcmUpgrades[chains[i].chainId]
            });
        }
        vm.label(opcm(), "OPCM");

        (bool success,) =
            opcm().delegatecall(abi.encodeWithSignature("upgrade((address,address,bytes32)[])", opcmConfigs));
        require(success, "OPCMUpgrateTemplate: failed to upgrade OPCM");
    }

    /// @notice validate the task for a given l2chain
    /// for this dummy opcm there are no validations per l2 chain
    /// for a real OPCM instance, add the validations per l2chain
    function _validate(uint256 chainId) internal view override {}
}
