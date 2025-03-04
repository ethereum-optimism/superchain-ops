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
import {console} from "forge-std/console.sol";
import {LibString} from "solady/utils/LibString.sol";

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
    mapping(uint256 => Claim) public opcmUpgrades;

    /// @notice Returns the OPCM address
    function opcm() public view override returns (address) {
        require(OPCM != address(0), "OPCMUpgradeV200: OPCM address not set in template");
        return OPCM;
    }

    function chainHasPermissionlessDisputeGame(uint256 chainId) public pure returns (bool) {
        chainId;
        return true; // TODO: implement for fully for chainIds going through V200 upgrade.
    }

    /// @notice Returns the storage write permissions
    function _taskStorageWrites(string memory taskConfigFilePath)
        internal
        view
        virtual
        override
        returns (string[] memory)
    {
        string memory toml = vm.readFile(taskConfigFilePath);
        bytes memory chainListContent = toml.parseRaw(".l2chains");
        SuperchainAddressRegistry.ChainInfo[] memory chains =
            abi.decode(chainListContent, (SuperchainAddressRegistry.ChainInfo[]));
        require(chains.length > 0, "OPCMUpgradeV200: no chains found");

        uint256 extraWrites = 0;
        for (uint256 i = 0; i < chains.length; i++) {
            if (chainHasPermissionlessDisputeGame(chains[i].chainId)) {
                extraWrites++;
            }
        }

        uint256 chainWrites = (2 * chains.length) + extraWrites;
        uint256 commonWrites = 10;
        uint256 totalWrites = commonWrites + chainWrites;
        string[] memory storageWrites = new string[](totalWrites);

        // Common contracts
        storageWrites[0] = "OPContractsManager";
        storageWrites[1] = "SuperchainConfig";
        storageWrites[2] = "ProtocolVersions";
        storageWrites[3] = "SystemConfigProxy";
        storageWrites[4] = "L1ERC721BridgeProxy";
        storageWrites[5] = "L1StandardBridgeProxy";
        storageWrites[6] = "DisputeGameFactoryProxy";
        storageWrites[7] = "OptimismPortalProxy";
        storageWrites[8] = "OptimismMintableERC20FactoryProxy";
        storageWrites[9] = "AddressManager";

        uint256 index = commonWrites;
        for (uint256 i = 0; i < chains.length; i++) {
            string memory chainIdStr = LibString.toString(chains[i].chainId);
            storageWrites[index] = string.concat(chainIdStr, "_PermissionedWETH");
            index++;
            if (chainHasPermissionlessDisputeGame(chains[i].chainId)) {
                storageWrites[index] = string.concat(chainIdStr, "_PermissionlessWETH");
                index++;
            }
            storageWrites[index] = string.concat(chainIdStr, "_NewAnchorStateRegistry");
            index++;
        }
        return storageWrites;
    }

    /// @notice Sets up the template with prestate inputs from a TOML file
    function _templateSetup(string memory taskConfigFilePath) internal override {
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        OPCMUpgrade[] memory upgrades =
            abi.decode(vm.parseToml(tomlContent, ".opcmUpgrades.absolutePrestates"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < upgrades.length; i++) {
            opcmUpgrades[upgrades[i].chainId] = upgrades[i].absolutePrestate;
        }

        address opcmAddress = abi.decode(vm.parseToml(tomlContent, ".opcmUpgrades.opcmAddress"), (address));
        require(opcmAddress != address(0), "OPCMUpgradeV200: OPCM address not set in task config");
        OPCM = opcmAddress;
        vm.label(opcmAddress, "OPCM");

        address standardValidatorAddress =
            abi.decode(vm.parseToml(tomlContent, ".opcmUpgrades.standardValidatorAddress"), (address));
        require(
            standardValidatorAddress != address(0), "OPCMUpgradeV200: StandardValidator address not set in task config"
        );
        STANDARD_VALIDATOR_V200 = IStandardValidatorV200(standardValidatorAddress);
        vm.label(standardValidatorAddress, "StandardValidatorV200");
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
                absolutePrestate: opcmUpgrades[chains[i].chainId]
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

            address disputeGameFactoryProxy = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            IFaultDisputeGame pddg =
                IFaultDisputeGame(IDisputeGameFactory(disputeGameFactoryProxy).gameImpls(uint32(1)));
            require(
                address(pddg) == superchainAddrRegistry.get(string.concat(chainIdStr, "_NewPermissionedDisputeGame")),
                "OPCMUpgradeV200: PermissionedDisputeGame address incorrect."
            );
            // PDDG-DWETH-40: permissioned dispute game's delayed weth delay is not 1 week
            require(
                IDelayedWETH(pddg.weth()).delay() == 3.5 days,
                "OPCMUpgradeV200: PermissionedDisputeGame delayed weth delay incorrect."
            );
            require(
                pddg.absolutePrestate() == currentAbsolutePrestate,
                "OPCMUpgradeV200: PermissionedDisputeGame absolutePrestate incorrect."
            );
            IAnchorStateRegistry newAsr =
                IAnchorStateRegistry(superchainAddrRegistry.get(string.concat(chainIdStr, "_NewAnchorStateRegistry")));
            require(
                pddg.anchorStateRegistry() == address(newAsr),
                "OPCMUpgradeV200: PermissionedDisputeGame anchorStateRegistry incorrect."
            );

            address oldAsr = superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId);
            (bytes32 oldAsrRoot,) = IAnchorStateRegistry(oldAsr).anchors(uint32(0));

            // PLDG-ANCHORP-40: bad permissionless dispute game ASR root
            (bytes32 pddgASRoot,) = newAsr.anchors(uint32(1));
            require(
                pddgASRoot == oldAsrRoot, "OPCMUpgradeV200: PermissionedDisputeGame anchorStateRegistry root incorrect."
            );

            IFaultDisputeGame pldg =
                IFaultDisputeGame(IDisputeGameFactory(disputeGameFactoryProxy).gameImpls(uint32(0)));
            if (address(pldg) != address(0)) {
                require(
                    address(pldg)
                        == superchainAddrRegistry.get(string.concat(chainIdStr, "_NewPermissionlessDisputeGame")),
                    "OPCMUpgradeV200: PermissionlessDisputeGame address incorrect."
                );
                // PLDG-DWETH-40: permissionless dispute game's delayed weth delay is not 1 week
                require(
                    IDelayedWETH(pldg.weth()).delay() == 3.5 days,
                    "OPCMUpgradeV200: PermissionlessDisputeGame delayed weth delay incorrect."
                );
                require(
                    pldg.absolutePrestate() == currentAbsolutePrestate,
                    "OPCMUpgradeV200: PermissionlessDisputeGame absolutePrestate incorrect."
                );

                require(
                    pldg.anchorStateRegistry() == address(newAsr),
                    "OPCMUpgradeV200: PermissionlessDisputeGame anchorStateRegistry incorrect."
                );
                // PDDG-ANCHORP-40: bad permissioned dispute game ASR root
                (bytes32 pldgASRoot,) = newAsr.anchors(uint32(0));
                require(
                    pldgASRoot == oldAsrRoot,
                    "OPCMUpgradeV200: PermissionlessDisputeGame anchorStateRegistry root incorrect."
                );
            }
            // PDDG-50: bad permissioned VM address
            // PLDG-50: bad permissionless vm address
            // The upgrade path maintains the existing mips impl address, so this error is expected.
            // Validate errors using the standard validator.
            string memory reasons = STANDARD_VALIDATOR_V200.validate({_input: input, _allowFailure: true});
            string memory expectedErrors = "PDDG-50,PDDG-DWETH-40,PDDG-ANCHORP-40,PLDG-50,PLDG-DWETH-40,PLDG-ANCHORP-40";
            require(
                keccak256(bytes(reasons)) == keccak256(bytes(expectedErrors)),
                string.concat("Unexpected errors: ", reasons)
            );
        }
    }

    /// @notice no code exceptions for this template
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
}

interface IDelayedWETH {
    function delay() external view returns (uint256);
}

interface IFaultDisputeGame {
    function weth() external view returns (address);
    function absolutePrestate() external view returns (bytes32);
    function anchorStateRegistry() external view returns (address);
}

interface IDisputeGameFactory {
    function gameImpls(uint32 gameType) external view returns (address);
}

interface IAnchorStateRegistry {
    function anchors(uint32 gameType) external view returns (bytes32, bytes32);
}
