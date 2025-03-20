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
import {IOPContractsManager} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOPContractsManager.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

/// @notice This template supports OPCMV200 upgrade tasks.
contract OPCMUpgradeV200 is OPCMBaseTask {
    using stdToml for string;
    using LibString for string;

    /// @notice The StandardValidatorV200 address
    IStandardValidatorV200 public STANDARD_VALIDATOR_V200;

    /// @notice Struct to store inputs for OPCM.upgrade() function per l2 chain
    struct OPCMUpgrade {
        Claim absolutePrestate;
        uint256 chainId;
    }

    /// @notice Mapping of l2 chain IDs to their respective prestates
    mapping(uint256 => Claim) public absolutePrestates;

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
            abi.decode(tomlContent.parseRaw(".opcmUpgrades.absolutePrestates"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < upgrades.length; i++) {
            absolutePrestates[upgrades[i].chainId] = upgrades[i].absolutePrestate;
        }

        OPCM = tomlContent.readAddress(".addresses.OPCM");
        require(IOPContractsManager(OPCM).version().eq("1.6.0"), "Incorrect OPCM");
        vm.label(OPCM, "OPCM");

        STANDARD_VALIDATOR_V200 = IStandardValidatorV200(tomlContent.readAddress(".addresses.StandardValidatorV200"));
        require(STANDARD_VALIDATOR_V200.disputeGameFactoryVersion().eq("1.0.1"), "Incorrect StandardValidatorV200");
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
        (bool success,) = OPCM.call(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
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
            // We expect many errors returned from this validation. Below are reasons for each failure which have been deemed acceptable.
            // In future versions of StandardValidator, we shouldn't be expecting any errors.
            string memory reasons = STANDARD_VALIDATOR_V200.validate({_input: input, _allowFailure: true});
            // PDDG-50: The current mipsImpl on sepolia was deployed without using deterministic create2 deployments, so a new one was deployed.
            // PDDG-DWETH-40: Delayed WETH delay in permissioned game is not set to 1 week.
            // PDDG-ANCHORP-40: The anchor state registry's permissioned root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            // PLDG-50: The current mipsImpl on sepolia was deployed without using deterministic create2 deployments, so a new one was deployed.
            // PLDG-DWETH-40: Delayed WETH delay in permissionless game is not set to 1 week. Config mismatch.
            // PLDG-ANCHORP-40: Anchor state registry root must match expected dead root (for permissionless dispute game) - This does not apply to any chain more than 1 week old
            string memory expectedErrors_11155420 =
                "PDDG-50,PDDG-DWETH-40,PDDG-ANCHORP-40,PLDG-50,PLDG-DWETH-40,PLDG-ANCHORP-40";
            // SYSCON-20: System config gas limit must be 60,000,000 - This is OK because we don't touch the system config.
            // PDDG-120: Permissioned dispute game challenger must match challenger address - It is checking for the OP Sepolia Challenger
            // PDDG-ANCHORP-40: Anchor state registry root must match expected dead root (for permissioned dispute game) - This does not apply to any chain more than 1 week old.
            // PDDG-DWETH-30: Delayed WETH owner must be l1PAOMultisig (for permissioned dispute game) - It is checking for the OP Sepolia PAO.
            // PLDG-10: Permissionless dispute game implementation is missing. Expected on Soneium.
            string memory expectedErrors_1946 =
                "SYSCON-20,PDDG-50,PDDG-DWETH-30,PDDG-DWETH-40,PDDG-ANCHORP-40,PDDG-120,PLDG-10";
            // PLDG-DWETH-30: Delayed WETH owner must be l1PAOMultisig (for permissionless dispute game) - It is checking for the OP Sepolia PAO
            string memory expectedErrors_763373 =
                "SYSCON-20,PDDG-50,PDDG-DWETH-30,PDDG-DWETH-40,PDDG-ANCHORP-40,PLDG-50,PLDG-DWETH-30,PLDG-DWETH-40,PLDG-ANCHORP-40";
            // PROXYA-10: Proxy admin owner must be l1PAOMultisig - This is OK because it is checking for the OP Sepolia PAO.
            // DF-30: Dispute factory owner must be l1PAOMultisig - It is checking for the OP Sepolia PAO.
            string memory expectedErrors_84532 =
                "PROXYA-10,DF-30,PDDG-50,PDDG-DWETH-30,PDDG-DWETH-40,PDDG-ANCHORP-40,PDDG-120,PLDG-50,PLDG-DWETH-30,PLDG-DWETH-40,PLDG-ANCHORP-40";
            require(
                reasons.eq(expectedErrors_11155420) || reasons.eq(expectedErrors_1946)
                    || reasons.eq(expectedErrors_763373) || reasons.eq(expectedErrors_84532),
                string.concat("Unexpected errors: ", reasons)
            );
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
}
