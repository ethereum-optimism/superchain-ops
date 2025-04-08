// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OPCMTaskBase} from "../tasks/types/OPCMTaskBase.sol";
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
contract OPCMUpgradeV300 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice The StandardValidatorV300 address
    IStandardValidatorV300 public STANDARD_VALIDATOR_V300;

    /// @notice Struct to store inputs for OPCM.upgrade() function per L2 chain.
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
    }

    /// @notice Mapping of L2 chain IDs to their respective prestates.
    mapping(uint256 => Claim) public absolutePrestates;

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](8);
        storageWrites[0] = "OPCM";
        storageWrites[1] = "SystemConfigProxy";
        storageWrites[2] = "OptimismPortalProxy";
        storageWrites[3] = "L1CrossDomainMessengerProxy";
        storageWrites[4] = "L1ERC721BridgeProxy";
        storageWrites[5] = "L1StandardBridgeProxy";
        storageWrites[6] = "DisputeGameFactoryProxy";
        storageWrites[7] = "AddressManager";
        return storageWrites;
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
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
        require(
            address(STANDARD_VALIDATOR_V300).code.length > 0, "Incorrect StandardValidatorV300 - no code at address"
        );
        require(
            STANDARD_VALIDATOR_V300.mipsVersion().eq("1.0.0"),
            "Incorrect StandardValidatorV300 - expected mips version 1.0.0"
        );
        require(
            STANDARD_VALIDATOR_V300.systemConfigVersion().eq("2.5.0"),
            "Incorrect StandardValidatorV300 - expected systemConfig version 2.5.0"
        );
        vm.label(address(STANDARD_VALIDATOR_V300), "StandardValidatorV300");
    }

    /// @notice Build the task action for all L2 chains in the task.
    /// A single call to OPCM.upgrade() is made for all L2 chains.
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

        // See: template/OPCMUpgradeV200.sol for more information on why we expect a revert here.
        (bool success,) = OPCM.call(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(!success, "OPCMUpgradeV300: Call unexpectedly succeeded; expected revert due to non-delegatecall.");
    }

    /// @notice Validate the task for a given L2 chain.
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
            string memory expectedErrors_11155420 = "PDDG-ANCHORP-40,PLDG-ANCHORP-40";

            // PDDG-DWETH-30: Delayed WETH owner must be l1PAOMultisig (for permissioned dispute game) - It is checking for the OP Sepolia PAO
            // PDDG-ANCHORP-40: The anchor state registry's permissioned root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            string memory expectedErrors_1946 = "PDDG-DWETH-30,PDDG-ANCHORP-40,PDDG-120,PLDG-10";

            // PDDG-DWETH-30: Delayed WETH owner must be l1PAOMultisig (for permissioned dispute game) - It is checking for the OP Sepolia PAO
            // PDDG-ANCHORP-40: The anchor state registry's permissioned root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            // PLDG-ANCHORP-40: The anchor state registry's permissionless root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            string memory expectedErrors_763373 = "PDDG-DWETH-30,PDDG-ANCHORP-40,PLDG-DWETH-30,PLDG-ANCHORP-40";

            require(
                reasons.eq(expectedErrors_11155420) || reasons.eq(expectedErrors_1946)
                    || reasons.eq(expectedErrors_763373),
                string.concat("Unexpected errors: ", reasons)
            );
        }
    }

    /// @notice No code exceptions for this template.
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
