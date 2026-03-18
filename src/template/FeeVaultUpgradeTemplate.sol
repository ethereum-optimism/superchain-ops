// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {FeeVaultUpgrader} from "src/libraries/FeeVaultUpgrader.sol";
import {RevShareCommon} from "src/libraries/RevShareCommon.sol";
import {Utils} from "src/libraries/Utils.sol";
import {IFeeVault} from "src/interfaces/IFeeVault.sol";
import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";

/// @notice Template for upgrading L2 fee vault predeploys to a new implementation with a
///         configurable fee recipient and withdrawal network. Calls are made via
///         OptimismPortal2.depositTransaction(), so no separate on-chain upgrader contract is needed.
///
///         The vault list is config-driven (modular): each run can target any subset of the four
///         known fee-vault predeploys:
///           - SequencerFeeVault  0x4200000000000000000000000000000000000011
///           - BaseFeeVault       0x4200000000000000000000000000000000000019
///           - L1FeeVault         0x420000000000000000000000000000000000001a
///           - OperatorFeeVault   0x420000000000000000000000000000000000001b  (U18+)
///
///         BaseFeeVault and L1FeeVault share the same implementation bytecode; a single
///         CREATE2 deployment is made for both.
///
/// @dev    Uses `L2TaskBase` (direct portal calls), not `OPCMTaskBase` (delegatecall to upgrader).
///         Safe → Multicall3.aggregate3Value → portal.depositTransaction × N
contract FeeVaultUpgradeTemplate is L2TaskBase {
    using stdToml for string;

    // -------------------------------------------------------------------------
    // Config state
    // -------------------------------------------------------------------------

    /// @notice Predeploy addresses to upgrade, read from TOML `vaultProxies`.
    address[] public vaultProxies;

    /// @notice Fee recipient per chain (index aligned with l2chains), read from TOML `recipients`.
    address[] public recipients;

    /// @notice Withdrawal network per chain (0 = L1, 1 = L2), read from TOML `networks`.
    uint256[] public networks;

    /// @notice Minimum withdrawal amount per chain, read from TOML `minWithdrawalAmounts`.
    uint256[] public minWithdrawalAmounts;

    // -------------------------------------------------------------------------
    // L2TaskBase overrides
    // -------------------------------------------------------------------------

    /// @notice The Safe that signs this task — the L2 ProxyAdminOwner on L1.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice OptimismPortal storage is written when `depositTransaction` is called.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory writes = new string[](1);
        writes[0] = "OptimismPortalProxy";
        return writes;
    }

    /// @notice No ETH balance changes expected.
    function _taskBalanceChanges() internal pure override returns (string[] memory) {}

    // -------------------------------------------------------------------------
    // Template lifecycle
    // -------------------------------------------------------------------------

    /// @notice Reads and validates all config from the TOML file.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        string memory toml = vm.readFile(_taskConfigFilePath);

        // --- vault proxies (shared across all chains) ---
        vaultProxies = abi.decode(toml.parseRaw(".vaultProxies"), (address[]));
        require(vaultProxies.length > 0, "FeeVaultUpgradeTemplate: vaultProxies must not be empty");
        for (uint256 i; i < vaultProxies.length; i++) {
            _requireKnownVault(vaultProxies[i]);
        }

        // --- per-chain arrays ---
        recipients = abi.decode(toml.parseRaw(".recipients"), (address[]));
        networks = abi.decode(toml.parseRaw(".networks"), (uint256[]));
        minWithdrawalAmounts = abi.decode(toml.parseRaw(".minWithdrawalAmounts"), (uint256[]));

        require(
            recipients.length == chains.length && networks.length == chains.length
                && minWithdrawalAmounts.length == chains.length,
            "FeeVaultUpgradeTemplate: per-chain arrays must have the same length as l2chains"
        );

        for (uint256 i; i < chains.length; i++) {
            require(
                recipients[i] != address(0), "FeeVaultUpgradeTemplate: recipient cannot be the zero address"
            );
            require(networks[i] <= 1, "FeeVaultUpgradeTemplate: network must be 0 (L1) or 1 (L2)");
        }

        super._templateSetup(_taskConfigFilePath, _rootSafe);
    }

    /// @notice Builds portal deposit calls: for each chain × vault, deploy the implementation
    ///         (if not already queued) and call ProxyAdmin.upgradeAndCall to re-initialize.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        for (uint256 c; c < chains.length; c++) {
            address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[c].chainId);
            address recipient = recipients[c];
            IFeeVault.WithdrawalNetwork network = IFeeVault.WithdrawalNetwork(networks[c]);
            uint256 minWithdrawal = minWithdrawalAmounts[c];

            // Track salts that have already been submitted for deployment on this chain
            // to avoid duplicate CREATE2 calls (BaseFeeVault + L1FeeVault share one impl).
            bytes32[] memory deployedSalts = new bytes32[](vaultProxies.length);
            uint256 deployedCount = 0;

            for (uint256 v; v < vaultProxies.length; v++) {
                (bytes memory creationCode, string memory saltName) = _getVaultImpl(vaultProxies[v]);
                bytes32 salt = RevShareCommon.getSalt(saltName);
                address impl = Utils.getCreate2Address(salt, creationCode, RevShareCommon.CREATE2_DEPLOYER);

                // Deploy the implementation only once per unique salt per chain.
                if (!_saltDeployed(deployedSalts, deployedCount, salt)) {
                    RevShareCommon.depositCreate2(
                        portal, FeeVaultUpgrader.FEE_VAULTS_DEPLOYMENT_GAS_LIMIT, salt, creationCode
                    );
                    deployedSalts[deployedCount++] = salt;
                }

                // Upgrade the vault proxy and initialize with the new config.
                // Pre-encode to avoid stack-too-deep in the nested abi.encodeCall.
                bytes memory initData = abi.encodeCall(IFeeVault.initialize, (recipient, minWithdrawal, network));
                bytes memory upgradeData =
                    abi.encodeCall(IProxyAdmin.upgradeAndCall, (payable(vaultProxies[v]), impl, initData));
                RevShareCommon.depositCall(
                    portal, address(RevShareCommon.PROXY_ADMIN), RevShareCommon.UPGRADE_GAS_LIMIT, upgradeData
                );
            }
        }
    }

    /// @notice Validates that the actions generated match the expected portal deposit pattern.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        uint256 uniqueDeployments = _countUniqueDeployments();
        uint256 actionsPerChain = uniqueDeployments + vaultProxies.length;
        uint256 expectedTotal = chains.length * actionsPerChain;

        require(
            _actions.length == expectedTotal,
            string.concat(
                "FeeVaultUpgradeTemplate: expected ",
                vm.toString(expectedTotal),
                " actions, got ",
                vm.toString(_actions.length)
            )
        );

        uint256 idx = 0;
        for (uint256 c; c < chains.length; c++) {
            address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[c].chainId);
            for (uint256 a; a < actionsPerChain; a++) {
                require(
                    _actions[idx].target == portal,
                    "FeeVaultUpgradeTemplate: action target must be OptimismPortalProxy"
                );
                require(_actions[idx].value == 0, "FeeVaultUpgradeTemplate: action value must be 0");
                idx++;
            }
        }

        MultisigTaskPrinter.printTitle("FeeVaultUpgradeTemplate: validated portal deposit actions");
    }

    /// @notice No code-length exceptions are required.
    function _getCodeExceptions() internal view override returns (address[] memory) {
        return new address[](0);
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    /// @notice Returns the CREATE2 creation code and salt name for a given vault predeploy address.
    ///         BaseFeeVault and L1FeeVault share the same implementation; both use the "BaseFeeVault" salt.
    function _getVaultImpl(address _vault)
        internal
        pure
        returns (bytes memory creationCode, string memory saltName)
    {
        if (_vault == FeeVaultUpgrader.SEQUENCER_FEE_WALLET) {
            return (FeeVaultUpgrader.sequencerFeeVaultCreationCode, "SequencerFeeVault");
        } else if (_vault == FeeVaultUpgrader.BASE_FEE_VAULT) {
            return (FeeVaultUpgrader.defaultFeeVaultCreationCode, "BaseFeeVault");
        } else if (_vault == FeeVaultUpgrader.L1_FEE_VAULT) {
            // L1FeeVault reuses the same implementation as BaseFeeVault.
            return (FeeVaultUpgrader.defaultFeeVaultCreationCode, "BaseFeeVault");
        } else if (_vault == FeeVaultUpgrader.OPERATOR_FEE_VAULT) {
            return (FeeVaultUpgrader.operatorFeeVaultCreationCode, "OperatorFeeVault");
        } else {
            revert("FeeVaultUpgradeTemplate: unknown vault address");
        }
    }

    /// @notice Reverts if `_vault` is not one of the four known fee-vault predeploys.
    function _requireKnownVault(address _vault) internal pure {
        if (
            _vault != FeeVaultUpgrader.SEQUENCER_FEE_WALLET && _vault != FeeVaultUpgrader.BASE_FEE_VAULT
                && _vault != FeeVaultUpgrader.L1_FEE_VAULT && _vault != FeeVaultUpgrader.OPERATOR_FEE_VAULT
        ) {
            revert("FeeVaultUpgradeTemplate: unknown vault address");
        }
    }

    /// @notice Returns true if `_salt` is already present in the first `_count` entries of `_salts`.
    function _saltDeployed(bytes32[] memory _salts, uint256 _count, bytes32 _salt) internal pure returns (bool) {
        for (uint256 i; i < _count; i++) {
            if (_salts[i] == _salt) return true;
        }
        return false;
    }

    /// @notice Counts the number of unique CREATE2 salts across all configured vault proxies.
    function _countUniqueDeployments() internal view returns (uint256 count) {
        bytes32[] memory seen = new bytes32[](vaultProxies.length);
        for (uint256 i; i < vaultProxies.length; i++) {
            (, string memory saltName) = _getVaultImpl(vaultProxies[i]);
            bytes32 salt = RevShareCommon.getSalt(saltName);
            if (!_saltDeployed(seen, count, salt)) {
                seen[count++] = salt;
            }
        }
    }
}
