// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {Utils} from "src/libraries/Utils.sol";

/// @title UpdateFeeVaultRecipient
/// @notice This template deploys new fee vault implementations on L2 with an updated recipient address,
///         and upgrades each fee vault proxy to point to the new implementation.
///         This is done via L1→L2 deposit transactions through the OptimismPortal.
///
///         Fee vaults have immutable recipients baked into their constructor bytecode, so changing
///         the recipient requires deploying new implementations and upgrading the proxies.
contract UpdateFeeVaultRecipient is L2TaskBase {
    using stdToml for string;

    /// @notice L2 predeploy addresses for fee vaults.
    address internal constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;
    address internal constant L2_PROXY_ADMIN = 0x4200000000000000000000000000000000000018;

    /// @notice The address of the CREATE2 Deployer preinstall on L2.
    address internal constant CREATE2_DEPLOYER = 0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2;

    /// @notice Gas limits for L2 operations.
    uint64 internal constant DEPLOY_GAS_LIMIT = 1_200_000;
    uint64 internal constant UPGRADE_GAS_LIMIT = 150_000;

    /// @notice Struct representing configuration for the task per chain.
    /// @dev Fields MUST be in alphabetical order for stdToml.parseRaw compatibility.
    struct FeeVaultConfig {
        uint256 chainId;
        address currentRecipient;
        uint256 minWithdrawalAmount;
        address newRecipient;
        uint8 withdrawalNetwork; // 0 = L1, 1 = L2
    }

    /// @notice Mapping of chain ID to configuration for the task.
    mapping(uint256 => FeeVaultConfig) public cfg;

    /// @notice Creation code for the default FeeVault (used for BaseFeeVault and L1FeeVault).
    /// Sourced from the FeeVaultUpgrader library.
    bytes public defaultFeeVaultCreationCode;

    /// @notice Creation code for the SequencerFeeVault.
    bytes public sequencerFeeVaultCreationCode;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "OptimismPortalProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with configurations from a TOML file.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory toml = vm.readFile(_taskConfigFilePath);

        FeeVaultConfig[] memory configs = abi.decode(toml.parseRaw(".feeVaultConfig"), (FeeVaultConfig[]));
        for (uint256 i = 0; i < configs.length; i++) {
            cfg[configs[i].chainId] = configs[i];
        }

        // Read creation codes from config
        defaultFeeVaultCreationCode = toml.readBytes(".creationCodes.defaultFeeVault");
        sequencerFeeVaultCreationCode = toml.readBytes(".creationCodes.sequencerFeeVault");
    }

    /// @notice Build the task actions: deploy new fee vault implementations and upgrade proxies.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            FeeVaultConfig memory c = cfg[chainId];
            require(c.chainId != 0, "UpdateFeeVaultRecipient: Config not found for chain");

            address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);

            // Build constructor args for the new implementations
            // FeeVault constructor: initialize(address _recipient, uint256 _minWithdrawalAmount, WithdrawalNetwork _withdrawalNetwork)
            bytes memory initArgs = abi.encode(c.newRecipient, c.minWithdrawalAmount, c.withdrawalNetwork);

            IOptimismPortal2 portalContract = IOptimismPortal2(payable(portal));

            // 1. Deploy new SequencerFeeVault implementation via CREATE2
            bytes32 seqSalt = keccak256(abi.encodePacked("ArenaZ:SequencerFeeVault:", chainId));
            bytes memory seqInitCode = abi.encodePacked(sequencerFeeVaultCreationCode, initArgs);
            address seqImpl = Utils.getCreate2Address(seqSalt, seqInitCode, CREATE2_DEPLOYER);
            portalContract.depositTransaction(
                CREATE2_DEPLOYER,
                0,
                DEPLOY_GAS_LIMIT,
                false,
                abi.encodeCall(ICreate2Deployer.deploy, (0, seqSalt, seqInitCode))
            );

            // 2. Deploy new default FeeVault implementation via CREATE2 (shared by BaseFeeVault and L1FeeVault)
            bytes32 defaultSalt = keccak256(abi.encodePacked("ArenaZ:FeeVault:", chainId));
            bytes memory defaultInitCode = abi.encodePacked(defaultFeeVaultCreationCode, initArgs);
            address defaultImpl = Utils.getCreate2Address(defaultSalt, defaultInitCode, CREATE2_DEPLOYER);
            portalContract.depositTransaction(
                CREATE2_DEPLOYER,
                0,
                DEPLOY_GAS_LIMIT,
                false,
                abi.encodeCall(ICreate2Deployer.deploy, (0, defaultSalt, defaultInitCode))
            );

            // 3. Upgrade SequencerFeeVault proxy
            portalContract.depositTransaction(
                L2_PROXY_ADMIN,
                0,
                UPGRADE_GAS_LIMIT,
                false,
                abi.encodeCall(IProxyAdmin.upgrade, (SEQUENCER_FEE_VAULT, seqImpl))
            );

            // 4. Upgrade BaseFeeVault proxy
            portalContract.depositTransaction(
                L2_PROXY_ADMIN,
                0,
                UPGRADE_GAS_LIMIT,
                false,
                abi.encodeCall(IProxyAdmin.upgrade, (BASE_FEE_VAULT, defaultImpl))
            );

            // 5. Upgrade L1FeeVault proxy
            portalContract.depositTransaction(
                L2_PROXY_ADMIN,
                0,
                UPGRADE_GAS_LIMIT,
                false,
                abi.encodeCall(IProxyAdmin.upgrade, (L1_FEE_VAULT, defaultImpl))
            );
        }
    }

    /// @notice Validates that all deposit transactions were captured correctly by reconstructing
    ///         the expected calldata for each of the 5 deposit transactions and comparing.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        // We expect 5 actions per chain: 2 deploys + 3 upgrades
        require(_actions.length == chains.length * 5, "UpdateFeeVaultRecipient: unexpected action count");

        for (uint256 i = 0; i < chains.length; i++) {
            _validateChain(chains[i].chainId, _actions, i * 5);
        }
    }

    /// @notice Validates the 5 deposit actions for a single chain.
    function _validateChain(uint256 chainId, Action[] memory _actions, uint256 baseIdx) internal view {
        FeeVaultConfig memory c = cfg[chainId];
        require(c.chainId != 0, "UpdateFeeVaultRecipient: Config not found for chain");

        address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
        bytes memory initArgs = abi.encode(c.newRecipient, c.minWithdrawalAmount, c.withdrawalNetwork);

        // Reconstruct and verify CREATE2 deploys
        _validateAction(
            _actions[baseIdx],
            portal,
            _expectedCreate2Deploy(
                keccak256(abi.encodePacked("ArenaZ:SequencerFeeVault:", chainId)),
                abi.encodePacked(sequencerFeeVaultCreationCode, initArgs)
            )
        );
        _validateAction(
            _actions[baseIdx + 1],
            portal,
            _expectedCreate2Deploy(
                keccak256(abi.encodePacked("ArenaZ:FeeVault:", chainId)),
                abi.encodePacked(defaultFeeVaultCreationCode, initArgs)
            )
        );

        // Reconstruct and verify proxy upgrades
        address seqImpl = Utils.getCreate2Address(
            keccak256(abi.encodePacked("ArenaZ:SequencerFeeVault:", chainId)),
            abi.encodePacked(sequencerFeeVaultCreationCode, initArgs),
            CREATE2_DEPLOYER
        );
        address defaultImpl = Utils.getCreate2Address(
            keccak256(abi.encodePacked("ArenaZ:FeeVault:", chainId)),
            abi.encodePacked(defaultFeeVaultCreationCode, initArgs),
            CREATE2_DEPLOYER
        );

        _validateAction(_actions[baseIdx + 2], portal, _expectedUpgrade(SEQUENCER_FEE_VAULT, seqImpl));
        _validateAction(_actions[baseIdx + 3], portal, _expectedUpgrade(BASE_FEE_VAULT, defaultImpl));
        _validateAction(_actions[baseIdx + 4], portal, _expectedUpgrade(L1_FEE_VAULT, defaultImpl));
    }

    /// @notice Validates a single action against expected target and calldata.
    function _validateAction(Action memory action, address expectedTarget, bytes memory expectedCalldata)
        internal
        pure
    {
        require(action.target == expectedTarget, "UpdateFeeVaultRecipient: action target mismatch");
        require(action.value == 0, "UpdateFeeVaultRecipient: action value is not zero");
        require(
            keccak256(action.arguments) == keccak256(expectedCalldata),
            "UpdateFeeVaultRecipient: action calldata mismatch"
        );
    }

    /// @notice Builds expected depositTransaction calldata for a CREATE2 deploy.
    function _expectedCreate2Deploy(bytes32 salt, bytes memory initCode) internal pure returns (bytes memory) {
        return abi.encodeCall(
            IOptimismPortal2.depositTransaction,
            (CREATE2_DEPLOYER, 0, DEPLOY_GAS_LIMIT, false, abi.encodeCall(ICreate2Deployer.deploy, (0, salt, initCode)))
        );
    }

    /// @notice Builds expected depositTransaction calldata for a proxy upgrade.
    function _expectedUpgrade(address proxy, address impl) internal pure returns (bytes memory) {
        return abi.encodeCall(
            IOptimismPortal2.depositTransaction,
            (L2_PROXY_ADMIN, 0, UPGRADE_GAS_LIMIT, false, abi.encodeCall(IProxyAdmin.upgrade, (proxy, impl)))
        );
    }

    /// @notice New implementations will be deployed on L2, so their L2 addresses won't have code on L1.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

// ----- INTERFACES ----- //

interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface ICreate2Deployer {
    function deploy(uint256 _value, bytes32 _salt, bytes memory _code) external;
}

interface IProxyAdmin {
    function upgrade(address _proxy, address _implementation) external;
}
