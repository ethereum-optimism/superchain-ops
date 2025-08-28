// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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

import {OPCMTaskBase} from "../tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

interface ISuperchainConfig {
    enum UpdateType {
        GUARDIAN
    }

    event ConfigUpdate(UpdateType indexed updateType, bytes data);
    event Initialized(uint8 version);
    event Paused(address identifier);
    event Unpaused(address identifier);

    error SuperchainConfig_OnlyGuardian();
    error SuperchainConfig_AlreadyPaused(address identifier);
    error ReinitializableBase_ZeroInitVersion();

    function guardian() external view returns (address);
    function initialize(address _guardian) external;
    function upgrade() external;
    function pause(address _identifier) external;
    function unpause(address _identifier) external;
    function pausable(address _identifier) external view returns (bool);
    function paused(address _identifier) external view returns (bool);
    function expiration(address _identifier) external view returns (uint256);
    function extend(address _identifier) external;
    function version() external view returns (string memory);
    function pauseTimestamps(address) external view returns (uint256);
    function pauseExpiry() external view returns (uint256);
    function initVersion() external view returns (uint8);

    function __constructor__() external;
}

interface IStandardValidatorBase {
    struct ImplementationsBase {
        address l1ERC721BridgeImpl;
        address optimismPortalImpl;
        address systemConfigImpl;
        address optimismMintableERC20FactoryImpl;
        address l1CrossDomainMessengerImpl;
        address l1StandardBridgeImpl;
        address disputeGameFactoryImpl;
        address anchorStateRegistryImpl;
        address delayedWETHImpl;
        address mipsImpl;
    }

    function anchorStateRegistryImpl() external view returns (address);
    function anchorStateRegistryVersion() external pure returns (string memory);
    function challenger() external view returns (address);
    function delayedWETHImpl() external view returns (address);
    function delayedWETHVersion() external pure returns (string memory);
    function disputeGameFactoryImpl() external view returns (address);
    function disputeGameFactoryVersion() external pure returns (string memory);
    function l1CrossDomainMessengerImpl() external view returns (address);
    function l1CrossDomainMessengerVersion() external pure returns (string memory);
    function l1ERC721BridgeImpl() external view returns (address);
    function l1ERC721BridgeVersion() external pure returns (string memory);
    function l1PAOMultisig() external view returns (address);
    function l1StandardBridgeImpl() external view returns (address);
    function l1StandardBridgeVersion() external pure returns (string memory);
    function mipsImpl() external view returns (address);
    function mipsVersion() external pure returns (string memory);
    function optimismMintableERC20FactoryImpl() external view returns (address);
    function optimismMintableERC20FactoryVersion() external pure returns (string memory);
    function optimismPortalImpl() external view returns (address);
    function optimismPortalVersion() external pure returns (string memory);
    function permissionedDisputeGameVersion() external pure returns (string memory);
    function preimageOracleVersion() external pure returns (string memory);
    function protocolVersions() external view returns (address);
    function protocolVersionsImpl() external view returns (address);
    function protocolVersionsVersion() external pure returns (string memory);
    function superchainConfig() external view returns (address);
    function superchainConfigImpl() external view returns (address);
    function superchainConfigVersion() external pure returns (string memory);
    function systemConfigImpl() external view returns (address);
    function systemConfigVersion() external pure returns (string memory);
    function withdrawalDelaySeconds() external view returns (uint256);
}

interface IStandardValidatorV200 is IStandardValidatorBase {
    struct InputV200 {
        address proxyAdmin;
        address sysCfg;
        bytes32 absolutePrestate;
        uint256 l2ChainID;
    }

    function validate(InputV200 memory _input, bool _allowFailure) external view returns (string memory);

    function __constructor__(
        IStandardValidatorBase.ImplementationsBase memory _implementations,
        ISuperchainConfig _superchainConfig,
        address _l1PAOMultisig,
        address _challenger,
        uint256 _withdrawalDelaySeconds
    ) external;
}

/// @notice This template supports OPCMV200 upgrade tasks.
/// Supports: op-contracts/v1.8.0
contract OPCMUpgradeV200 is OPCMTaskBase {
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
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // For OPCMUpgradeV200, the OPCMUpgrade struct is used to store the absolutePrestate for each l2 chain.
        OPCMUpgrade[] memory upgrades =
            abi.decode(tomlContent.parseRaw(".opcmUpgrades.absolutePrestates"), (OPCMUpgrade[]));
        for (uint256 i = 0; i < upgrades.length; i++) {
            absolutePrestates[upgrades[i].chainId] = upgrades[i].absolutePrestate;
        }

        address OPCM = tomlContent.readAddress(".addresses.OPCM");
        OPCM_TARGETS.push(OPCM);
        require(IOPContractsManager(OPCM).version().eq("1.6.0"), "Incorrect OPCM");
        vm.label(OPCM, "OPCM");

        STANDARD_VALIDATOR_V200 = IStandardValidatorV200(tomlContent.readAddress(".addresses.StandardValidatorV200"));
        require(STANDARD_VALIDATOR_V200.disputeGameFactoryVersion().eq("1.0.1"), "Incorrect StandardValidatorV200");
        vm.label(address(STANDARD_VALIDATOR_V200), "StandardValidatorV200");
    }

    /// @notice Build the task action for all l2chains in the task.abi
    /// A single call to OPCM.upgrade() is made for all l2 chains.
    function _build(address) internal override {
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

        (bool success,) = OPCM_TARGETS[0].delegatecall(abi.encodeCall(IOPContractsManager.upgrade, (opChainConfigs)));
        require(success, "OPCMUpgradeV200: upgrade call failed in _build.");
    }

    /// @notice validate the task for a given l2chain
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
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

            // Sepolia errors
            // PDDG-50: The current mipsImpl on sepolia was deployed without using deterministic create2 deployments, so a new one was deployed.
            // PDDG-DWETH-40: Delayed WETH delay in permissioned game is not set to 1 week.
            // PDDG-ANCHORP-40: The anchor state registry's permissioned root is not 0xdead000000000000000000000000000000000000000000000000000000000000
            // PLDG-50: The current mipsImpl on sepolia was deployed without using deterministic create2 deployments, so a new one was deployed.
            // PLDG-DWETH-40: Delayed WETH delay in permissionless game is not set to 1 week. Config mismatch.
            // PLDG-ANCHORP-40: Anchor state registry root must match expected dead root (for permissionless dispute game) - This does not apply to any chain more than 1 week old
            string memory expectedErrors_11155420 =
                "PDDG-50,PDDG-DWETH-40,PDDG-ANCHORP-40,PLDG-50,PLDG-DWETH-40,PLDG-ANCHORP-40";

            // PROXYA-10: Proxy admin owner must be l1PAOMultisig - This is OK because it is checking for the OP Sepolia PAO.
            // DF-30: Dispute factory owner must be l1PAOMultisig - It is checking for the OP Sepolia PAO.
            string memory expectedErrors_84532 =
                "PROXYA-10,DF-30,PDDG-50,PDDG-DWETH-30,PDDG-DWETH-40,PDDG-ANCHORP-40,PDDG-120,PLDG-50,PLDG-DWETH-30,PLDG-DWETH-40,PLDG-ANCHORP-40";

            // Mainnet errors
            // PDDG-DWETH-30: Permissioned dispute game's DelayedWETH owner must be l1PAOMultisig
            // PLDG-DWETH-30: Permissionless dispute game's DelayedWETH owner must be l1PAOMultisig
            //   DWETH-30 errors are pre-existing misconfigurations on OP Mainnet which are out of scope for this task.
            // PDDG-ANCHORP-40: Permissioned dispute game's AnchorStateRegistry root must be 0xdead000000000000000000000000000000000000000000000000000000000000
            // PLDG-ANCHORP-40: Permissionless dispute game's AnchorStateRegistry root must be 0xdead000000000000000000000000000000000000000000000000000000000000
            //   ANCHORP-40 errors do not apply to chains over 1 week old.
            string memory expectedErrors_10 = "PDDG-DWETH-30,PDDG-ANCHORP-40,PLDG-DWETH-30,PLDG-ANCHORP-40";

            // PDDG-ANCHORP-40: Permissioned dispute game's AnchorStateRegistry root must be 0xdead000000000000000000000000000000000000000000000000000000000000
            //   ANCHORP-40 errors do not apply to chains over 1 week old.
            // PLDG-10: Permissionless dispute game implementation is null (not found)
            //   This error is expect on chains which do not yet have permissionless dispute games.
            string memory expectedErrors_1868 = "PDDG-ANCHORP-40,PLDG-10";

            // SYSCON-30: System config scalar must be 1 << 248 (first byte must be 1)
            //   SYSCON-30 is a result of the Ink system config being on an earlier
            // PDDG-ANCHORP-40: Permissioned dispute game's AnchorStateRegistry root must be 0xdead000000000000000000000000000000000000000000000000000000000000
            // PLDG-ANCHORP-40: Permissionless dispute game's AnchorStateRegistry root must be 0xdead000000000000000000000000000000000000000000000000000000000000
            //   ANCHORP-40 errors do not apply to chains over 1 week old.
            string memory expectedErrors_57073 = "SYSCON-30,PDDG-ANCHORP-40,PLDG-ANCHORP-40";

            string memory expectedErrors_1301 =
                "PROXYA-10,DF-30,PDDG-DWETH-30,PDDG-ANCHORP-40,PDDG-120,PLDG-DWETH-30,PLDG-ANCHORP-40";
            string memory expectedErrors_130 =
                "PROXYA-10,DF-30,PDDG-DWETH-30,PDDG-ANCHORP-40,PLDG-DWETH-30,PLDG-ANCHORP-40";
            require(
                reasons.eq(expectedErrors_11155420) || reasons.eq(expectedErrors_84532) || reasons.eq(expectedErrors_10)
                    || reasons.eq(expectedErrors_1868) || reasons.eq(expectedErrors_57073)
                    || reasons.eq(expectedErrors_1301) || reasons.eq(expectedErrors_130),
                string.concat("Unexpected errors: ", reasons)
            );
        }
    }

    /// @notice no code exceptions for this template
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}
