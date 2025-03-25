// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OPCMBaseTask} from "../tasks/OPCMBaseTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {
    IOPContractsManager,
    ISystemConfig,
    IProxyAdmin
} from "@eth-optimism-bedrock/interfaces/L1/IOPContractsManager.sol";
import {IOPContractsManager} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOPContractsManager.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

/// @notice This template supports OPCMV300 upgrade tasks.
contract OPCMUpgradeV300 is OPCMBaseTask {
    using stdToml for string;
    using LibString for string;

    /// @notice The StandardValidatorV300 address
    IStandardValidatorV300 public STANDARD_VALIDATOR_V300;

    /// @notice Struct to store inputs for OPCM.upgrade() function per l2 chain
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
    }

    /// @notice Mapping of l2 chain IDs to their respective prestates
    mapping(uint256 => Claim) public absolutePrestates;

    /// @notice Returns the storage write permissions
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](8);
        storageWrites[0] = "OPCM";
        storageWrites[1] = "SystemConfigProxy";
        storageWrites[2] = "OptimismPortalProxy";
        storageWrites[3] = "L1CrossDomainMessengerProxy";
        storageWrites[4] = "L1ERC721BridgeProxy";
        storageWrites[5] = "L1StandardBridgeProxy";
        storageWrites[6] = "DisputeGameFactoryProxy";
        // TODO: Add these notes to the validation file
        // Note the addressManager is used with the L1CrossDomainMessengerProxy
        // It is stored in AddressManager.sol under the name "OVM_L1CrossDomainMessenger"
        // See: https://github.com/ethereum-optimism/optimism/blob/4dbde37858af8ce89f776488506974c080879d2a/packages/contracts-bedrock/src/L1/OPContractsManager.sol#L842-L842
        // The addresses mapping (keyed by the hash of the name) in AddressManager.sol is updated
        // cast keccak OVM_L1CrossDomainMessenger
        // 0x3b4a6791a6879d27c0ceeea3f78f8ebe66a01905f4a1290a8c6aff3e85f4665a
        storageWrites[7] = "AddressManager";
        return storageWrites;
    }

    /// @notice Sets up the template with prestate inputs from a TOML file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // For OPCMUpgradeV300, the OPCMUpgrade struct is used to store the absolutePrestate for each l2 chain.
        OPCMUpgrade[] memory upgrades =
            abi.decode(tomlContent.parseRaw(".opcmUpgrades.absolutePrestates"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < upgrades.length; i++) {
            absolutePrestates[upgrades[i].chainId] = upgrades[i].absolutePrestate;
        }

        OPCM = tomlContent.readAddress(".addresses.OPCM");
        require(OPCM.code.length > 0, "Incorrect OPCM - no code at address");
        require(IOPContractsManager(OPCM).version().eq("1.9.0"), "Incorrect OPCM - expected version 1.9.0");
        vm.label(OPCM, "OPCM");

        STANDARD_VALIDATOR_V300 = IStandardValidatorV300(tomlContent.readAddress(".addresses.StandardValidatorV300"));
        require(address(STANDARD_VALIDATOR_V300).code.length > 0, "Incorrect StandardValidatorV300 - no code at address");
        require(STANDARD_VALIDATOR_V300.mipsVersion().eq("1.0.0"), "Incorrect StandardValidatorV300 - expected mips version 1.0.0");
        require(STANDARD_VALIDATOR_V300.systemConfigVersion().eq("2.5.0"), "Incorrect StandardValidatorV300 - expected systemConfig version 2.5.0");
        vm.label(address(STANDARD_VALIDATOR_V300), "StandardValidatorV300");
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
        (bool success,) = OPCM.call(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(!success, "OPCMUpgradeV300: Call unexpectedly succeeded; expected revert due to non-delegatecall.");
    }

    /// @notice validate the task for a given l2chain
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            bytes32 currentAbsolutePrestate = Claim.unwrap(absolutePrestates[chainId]);
            address proxyAdmin = superchainAddrRegistry.getAddress("ProxyAdmin", chainId);
            address sysCfg = superchainAddrRegistry.getAddress("SystemConfigProxy", chainId);

            IStandardValidatorV300.InputV300 memory input = IStandardValidatorV300.InputV300({
                proxyAdmin: proxyAdmin,
                sysCfg: sysCfg,
                absolutePrestate: currentAbsolutePrestate,
                l2ChainID: chainId
            });

            string memory reasons = STANDARD_VALIDATOR_V300.validate({_input: input, _allowFailure: true});
            // PDDG-ANCHORP-40: The anchor state registry's permissioned root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            // PLDG-ANCHORP-40: The anchor state registry's permissionless root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            // PDDG-DWETH-40: the delayed weth delay is changing to 3.5 days for permissioned games
            // PLDG-DWETH-40: the delayed weth delay is changing to 3.5 days for permissionless
            string memory expectedErrors_11155420 = "PDDG-DWETH-40,PDDG-ANCHORP-40,PLDG-DWETH-40,PLDG-ANCHORP-40";
            // SYSCON-20: System config gas limit must be 60,000,000 - This is OK because we don't touch the system config.
            // PDDG-ANCHORP-40: The anchor state registry's permissioned root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            // PLDG-ANCHORP-40: The anchor state registry's permissionless root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            // PDDG-DWETH-40: the delayed weth delay is changing to 3.5 days for permissioned games
            // PLDG-DWETH-40: the delayed weth delay is changing to 3.5 days for permissionless
            string memory expectedErrors_1946 = "SYSCON-20,PDDG-DWETH-30,PDDG-DWETH-40,PDDG-ANCHORP-40,PDDG-120,PLDG-10";
            // SYSCON-20: System config gas limit must be 60,000,000 - This is OK because we don't touch the system config.
            // PDDG-ANCHORP-40: The anchor state registry's permissioned root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            // PLDG-ANCHORP-40: The anchor state registry's permissionless root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            // PDDG-DWETH-40: the delayed weth delay is changing to 3.5 days for permissioned games
            // PLDG-DWETH-30: Delayed WETH owner must be l1PAOMultisig (for permissionless dispute game) - It is checking for the OP Sepolia PAO
            // PDDG-DWETH-30: Delayed WETH owner must be l1PAOMultisig (for permissioned dispute game) - It is checking for the OP Sepolia PAO
            // PLDG-DWETH-40: the delayed weth delay is changing to 3.5 days for permissionless
            // PLDG-ANCHORP-40: Anchor state registry root must match expected dead root (for permissionless dispute game) - This does not apply to any chain more than 1 week old
        string memory expectedErrors_763373 = "SYSCON-20,PDDG-DWETH-30,PDDG-DWETH-40,PDDG-ANCHORP-40,PLDG-DWETH-30,PLDG-DWETH-40,PLDG-ANCHORP-40";
            require(reasons.eq(expectedErrors_11155420) || reasons.eq(expectedErrors_1946) || reasons.eq(expectedErrors_763373),
                string.concat("Unexpected errors: ", reasons));
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
}

interface IStandardValidatorV300 {
    struct InputV300 {
        address proxyAdmin;
        address sysCfg;
        bytes32 absolutePrestate;
        uint256 l2ChainID;
    }

    function validate(InputV300 memory _input, bool _allowFailure) external view returns (string memory);

    function mipsVersion() external pure returns (string memory);

    function systemConfigVersion() external pure returns (string memory);
}
