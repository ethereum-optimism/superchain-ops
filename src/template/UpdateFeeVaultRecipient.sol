// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @title UpdateFeeVaultRecipient
/// @notice This template upgrades each fee vault proxy to point to pre-deployed implementations
///         that have an updated recipient address baked in as an immutable.
///
///         The implementations must be deployed on L2 before running this task.
///         This task only performs the 3 proxy upgrade calls via L1→L2 deposit transactions
///         through the OptimismPortal.
contract UpdateFeeVaultRecipient is L2TaskBase {
    using stdToml for string;

    /// @notice L2 predeploy addresses for fee vaults.
    address internal constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    address internal constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    address internal constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;
    address internal constant L2_PROXY_ADMIN = 0x4200000000000000000000000000000000000018;

    /// @notice Struct representing configuration for the task per chain.
    /// @dev Fields MUST be in alphabetical order for stdToml.parseRaw compatibility.
    struct FeeVaultConfig {
        uint256 chainId;
        address defaultFeeVaultImpl;
        address seqFeeVaultImpl;
        uint64 upgradeGasLimit;
    }

    /// @notice Mapping of chain ID to configuration for the task.
    mapping(uint256 => FeeVaultConfig) public cfg;

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
            require(
                configs[i].seqFeeVaultImpl != address(0), "UpdateFeeVaultRecipient: seqFeeVaultImpl is zero address"
            );
            require(
                configs[i].defaultFeeVaultImpl != address(0),
                "UpdateFeeVaultRecipient: defaultFeeVaultImpl is zero address"
            );
            require(
                configs[i].upgradeGasLimit >= 100_000,
                "UpdateFeeVaultRecipient: upgradeGasLimit must be at least 100,000"
            );
            cfg[configs[i].chainId] = configs[i];
        }
    }

    /// @notice Build the task actions: upgrade the 3 fee vault proxies to the pre-deployed implementations.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            FeeVaultConfig memory c = cfg[chainId];
            require(c.chainId != 0, "UpdateFeeVaultRecipient: Config not found for chain");

            address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
            IOptimismPortal2 portalContract = IOptimismPortal2(payable(portal));

            // 1. Upgrade SequencerFeeVault proxy
            portalContract.depositTransaction(
                L2_PROXY_ADMIN,
                0,
                c.upgradeGasLimit,
                false,
                abi.encodeCall(IProxyAdmin.upgrade, (SEQUENCER_FEE_VAULT, c.seqFeeVaultImpl))
            );

            // 2. Upgrade BaseFeeVault proxy
            portalContract.depositTransaction(
                L2_PROXY_ADMIN,
                0,
                c.upgradeGasLimit,
                false,
                abi.encodeCall(IProxyAdmin.upgrade, (BASE_FEE_VAULT, c.defaultFeeVaultImpl))
            );

            // 3. Upgrade L1FeeVault proxy
            portalContract.depositTransaction(
                L2_PROXY_ADMIN,
                0,
                c.upgradeGasLimit,
                false,
                abi.encodeCall(IProxyAdmin.upgrade, (L1_FEE_VAULT, c.defaultFeeVaultImpl))
            );
        }
    }

    /// @notice Validates that all deposit transactions were captured correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        // We expect 3 actions per chain: upgrade SEQ, BASE, L1 fee vault proxies
        require(_actions.length == chains.length * 3, "UpdateFeeVaultRecipient: unexpected action count");

        for (uint256 i = 0; i < chains.length; i++) {
            _validateChain(chains[i].chainId, _actions, i * 3);
        }
    }

    /// @notice Validates the 3 upgrade actions for a single chain.
    function _validateChain(uint256 chainId, Action[] memory _actions, uint256 baseIdx) internal view {
        FeeVaultConfig memory c = cfg[chainId];
        require(c.chainId != 0, "UpdateFeeVaultRecipient: Config not found for chain");

        address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);

        _validateAction(
            _actions[baseIdx], portal, _expectedUpgrade(SEQUENCER_FEE_VAULT, c.seqFeeVaultImpl, c.upgradeGasLimit)
        );
        _validateAction(
            _actions[baseIdx + 1], portal, _expectedUpgrade(BASE_FEE_VAULT, c.defaultFeeVaultImpl, c.upgradeGasLimit)
        );
        _validateAction(
            _actions[baseIdx + 2], portal, _expectedUpgrade(L1_FEE_VAULT, c.defaultFeeVaultImpl, c.upgradeGasLimit)
        );
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

    /// @notice Builds expected depositTransaction calldata for a proxy upgrade.
    function _expectedUpgrade(address proxy, address impl, uint64 gasLimit) internal pure returns (bytes memory) {
        return abi.encodeCall(
            IOptimismPortal2.depositTransaction,
            (L2_PROXY_ADMIN, 0, gasLimit, false, abi.encodeCall(IProxyAdmin.upgrade, (proxy, impl)))
        );
    }

    /// @notice New implementations are pre-deployed on L2, so their addresses won't have code on L1.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

// ----- INTERFACES ----- //

interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface IProxyAdmin {
    function upgrade(address _proxy, address _implementation) external;
}
