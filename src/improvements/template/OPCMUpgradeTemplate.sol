pragma solidity ^0.8.0;

import {OPCMBaseTask} from "../tasks/OPCMBaseTask.sol";
import {AddressRegistry as Addresses} from "src/improvements/AddressRegistry.sol";
import {console} from "forge-std/console.sol";

contract OPCMUpgradeTemplate is OPCMBaseTask {
    address public constant OPCM = 0x5BC817c7C3F1A8dCAA01d229Cbdeed9624C80E09;

    /// @notice Struct to store gas limits to be set for a specific L2 chain ID
    /// @param chainId The ID of the L2 chain
    /// @param prestate The prestate to be set for the l2 chain
    struct OPCMUpgrade {
        uint256 chainId;
        bytes32 prestate;
    }

    /// @notice Mapping of l2 chain IDs to their respective prestates
    mapping(uint256 => bytes32) public opcmUpgrades;

    function opcm() public pure override returns (address) {
        return OPCM;
    }

    /// @notice Returns the safe address string identifier
    /// @return The string "ProxyAdminOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions
    /// currently used OPCM is a dummy so no storage writes are needed
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](0);
        return storageWrites;
    }

    /// @notice Sets up the template with gas configurations from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        OPCMUpgrade[] memory opcmUpgrade =
            abi.decode(vm.parseToml(vm.readFile(taskConfigFilePath), ".opcmUpgrades.opcmPrestates"), (OPCMUpgrade[]));

        for (uint256 i = 0; i < opcmUpgrade.length; i++) {
            opcmUpgrades[opcmUpgrade[i].chainId] = opcmUpgrade[i].prestate;
        }
    }

    /// @notice build the task actions for all l2chains in the task
    /// @dev contract calls must be perfomed in plain solidity.
    ///      overriden requires using buildModifier modifier to leverage
    ///      foundry snapshot and state diff recording to populate the actions array.
    function build() public override buildModifier {
        Addresses.ChainInfo[] memory chains = addresses.getChains();
        OpChainConfig[] memory opcmConfigs = new OpChainConfig[](chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            opcmConfigs[i] = OpChainConfig({
                systemConfigProxy: addresses.getAddress("SystemConfigProxy", chains[i].chainId),
                proxyAdmin: addresses.getAddress("ProxyAdmin", chains[i].chainId),
                absolutePrestate: opcmUpgrades[chains[i].chainId]
            });
        }
        console.log("address this", address(this));
        vm.label(opcm(), "OPCM");

        (bool success,) =
            opcm().delegatecall(abi.encodeWithSignature("upgrade((address,address,bytes32)[])", opcmConfigs));
        require(success, "OPCMUpgrateTemplate: failed to upgrade OPCM");
    }

    function _validate(uint256 chainId) internal view override {}
}
