// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OPCMBaseTask} from "../tasks/OPCMBaseTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {
    IOPContractsManager,
    ISystemConfig,
    IProxyAdmin
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {IStandardValidatorV200} from "@eth-optimism-bedrock/interfaces/L1/IStandardValidator.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

/// @notice This template supports OPCMV200 upgrade tasks.
contract OPCMUpgradeV200 is OPCMBaseTask {
    using stdToml for string;

    /// @notice The OPContractsManager address
    address public OPCM;

    /// @notice The StandardValidatorV200 address
    IStandardValidatorV200 public STANDARD_VALIDATOR_V200;

    /// @notice Struct to store inputs for OPCM.upgrade() function per l2 chain
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
    }

    /// @notice Mapping of l2 chain IDs to their respective prestates
    mapping(uint256 => Claim) public absolutePrestates;

    /// @notice Returns the OPCM address
    function opcm() public view override returns (address) {
        require(OPCM != address(0), "OPCMUpgradeV200: OPCM address not set in template");
        return OPCM;
    }

    /// @notice Returns the storage write permissions
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](13);
        storageWrites[0] = "OPCM";
        storageWrites[1] = "SuperchainConfig";
        storageWrites[2] = "ProtocolVersions";
        storageWrites[3] = "SystemConfigProxy";
        storageWrites[4] = "AddressManager";
        storageWrites[5] = "L1ERC721BridgeProxy";
        storageWrites[6] = "L1StandardBridgeProxy";
        storageWrites[7] = "DisputeGameFactoryProxy";
        storageWrites[8] = "OptimismPortalProxy";
        storageWrites[9] = "OptimismMintableERC20FactoryProxy";
        storageWrites[10] = "OptimismMintableERC20FactoryProxy";
        storageWrites[11] = "PermissionedWETH"; // GameType 1
        storageWrites[12] = "PermissionlessWETH"; // GameType 0
        return storageWrites;
    }

    /// @notice Sets up the template with prestate inputs from a TOML file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // For OPCMUpgradeV200, the OPCMUpgrade struct is used to store the absolutePrestate for each l2 chain.
        OPCMUpgrade[] memory upgrades =
            abi.decode(vm.parseToml(tomlContent, ".opcmUpgrades.absolutePrestates"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < upgrades.length; i++) {
            absolutePrestates[upgrades[i].chainId] = upgrades[i].absolutePrestate;
        }

        address opcmAddress = tomlContent.readAddress(".addresses.OPCM");
        OPCM = opcmAddress;
        require(OPCM != address(0), "OPCMUpgradeV200: OPCM address not set in config.toml");
        vm.label(opcm(), "OPCM");

        address standardValidatorV200 = tomlContent.readAddress(".opcmUpgrades.standardValidatorV200");
        require(
            standardValidatorV200 != address(0), "OPCMUpgradeV200: StandardValidator address not set in config.toml"
        );
        STANDARD_VALIDATOR_V200 = IStandardValidatorV200(standardValidatorV200);
        vm.label(address(STANDARD_VALIDATOR_V200), "StandardValidatorV200");
    }

    /// @notice Build the task action for all l2chains in the task.abi
    /// A single call to OPCM.upgrade() is made for all l2 chains.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        IOPContractsManager.OpChainConfig[] memory opChainConfigs =
            new IOPContractsManager.OpChainConfig[](chains.length);

        for (uint256 i = 0; i < chains.length; i++) {
            opChainConfigs[i] = IOPContractsManager.OpChainConfig({
                systemConfigProxy: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId)),
                proxyAdmin: IProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[i].chainId)),
                absolutePrestate: absolutePrestates[chains[i].chainId]
            });
        }

        // Before '_build()' is invoked by the 'build()' function in 'MultisigTask.sol', we start recording all state changes using 'vm.startStateDiffRecording()'.
        // The primary purpose of '_build()' is to trigger the necessary account accesses so they are recorded when we call 'vm.stopAndReturnStateDiff()'.
        // These recorded accesses are then converted into actions that the safe eventually executes via MultiCall3DelegateCall (in this case).
        // More specifically, we want to ensure that the correct target and callData are recorded for the 'Call3' struct in MultiCall3DelegateCall.
        // In this case, the 'target' should be the OPCM address, and the 'callData' should be the ABI-encoded 'upgrade()' call.
        //
        // The code below is unintuitive because we expect it to revert. Due to limitations in Foundry's 'prank' cheatcode (see: https://github.com/foundry-rs/foundry/issues/9990),
        // we cannot correctly use a delegatecall to this function without it reverting.
        //
        // As a workaround, we make the call anyway to ensure the desired OPCM account access is recorded. This is acceptable because we later simulate
        // the actual 'OPCM.upgrade()' call. However, it is crucial that the 'OPCM.upgrade()' call does not revert during the simulation.
        (bool success,) = opcm().call(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(!success, "OPCMUpgradeV200: Call unexpectedly succeeded; expected revert due to non-delegatecall.");
    }

    /// @notice validate the task for a given l2chain
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            bytes32 currentAbsolutePrestate = Claim.unwrap(absolutePrestates[chainId]);
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IStandardValidatorV200.InputV200 memory input = IStandardValidatorV200.InputV200({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: currentAbsolutePrestate,
                l2ChainID: chainId
            });

            string memory reasons = STANDARD_VALIDATOR_V200.validate({_input: input, _allowFailure: true});
            string memory expectedErrors_11155420 =
                "PDDG-50,PDDG-DWETH-40,PDDG-ANCHORP-40,PLDG-50,PLDG-DWETH-40,PLDG-ANCHORP-40";
            require(
                keccak256(bytes(reasons)) == keccak256(bytes(expectedErrors_11155420)),
                string.concat("Unexpected errors: ", reasons)
            );
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
}
