// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {
    IOPContractsManager,
    ISystemConfig,
    IProxyAdmin
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {console} from "forge-std/console.sol";
import {LibString} from "solady/utils/LibString.sol";
import {IStandardValidatorV200} from "@eth-optimism-bedrock/interfaces/L1/IStandardValidator.sol";

import {OPCMBaseTask} from "../tasks/OPCMBaseTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

/// @notice This is an example of implementing OPCMBaseTask to perform an upgrade via the OPCM contract.
/// @dev OPCM upgrade tasks always target a specific l1 contract release version and therfore OPCM contract.
contract TestOPCMUpgradeVxyz is OPCMBaseTask {
    using stdToml for string;

    /// @notice The OPContractsManager address
    address public OPCM;

    /// @notice Struct to store inputs for OPCM.upgrade() function per l2 chain
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
    }

    /// @notice Mapping of l2 chain IDs to their respective prestates
    mapping(uint256 => Claim) public opcmUpgrades;

    /// @notice The StandardValidatorV200 address
    IStandardValidatorV200 public STANDARD_VALIDATOR_V200 =
        IStandardValidatorV200(0x37739a6b0a3F1E7429499a4eC4A0685439Daff5C);

    /// @notice Returns the OPCM address
    function opcm() public pure override returns (address) {
        return 0x1B25F566336F47BC5E0036D66E142237DcF4640b;
    }

    /// @notice Returns the storage write permissions
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](0);
        return storageWrites;
    }

    /// @notice Sets up the template with prestate inputs from a TOML file
    /// @param taskConfigFilePath Path to the TOML configuration file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        OPCMUpgrade[] memory opcmUpgrade =
            abi.decode(vm.parseToml(tomlContent, ".opcmUpgrades.opcmPrestates"), (OPCMUpgrade[]));

        for (uint256 i = 0; i < opcmUpgrade.length; i++) {
            opcmUpgrades[opcmUpgrade[i].chainId] = opcmUpgrade[i].absolutePrestate;
        }

        vm.label(opcm(), "OPCM");
    }

    /// @notice Build the task action for all l2chains in the task in a single call to the OPCM.upgrade() function.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        IOPContractsManager.OpChainConfig[] memory opChainConfigs =
            new IOPContractsManager.OpChainConfig[](chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            opChainConfigs[i] = IOPContractsManager.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId)),
                proxyAdmin: IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[i].chainId)),
                absolutePrestate: opcmUpgrades[chains[i].chainId]
            });
        }
        (bool success,) = opcm().call(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(!success, "OPCMUpgradeV200: Call unexpectedly succeeded; expected revert due to non-delegatecall.");
    }

    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory actions) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            string memory chainIdStr = LibString.toString(chainId);
            bytes32 currentAbsolutePrestate = Claim.unwrap(opcmUpgrades[chainId]);
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IStandardValidatorV200.InputV200 memory input = IStandardValidatorV200.InputV200({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: currentAbsolutePrestate,
                l2ChainID: chainId
            });
            string memory reasons = STANDARD_VALIDATOR_V200.validate({_input: input, _allowFailure: true});
            string memory expectedErrors = "PDDG-50,PDDG-DWETH-40,PDDG-ANCHORP-40,PLDG-50,PLDG-DWETH-40,PLDG-ANCHORP-40";
            require(
                keccak256(bytes(reasons)) == keccak256(bytes(expectedErrors)),
                string.concat("Unexpected errors: ", reasons)
            );
        }
    }

    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
}
