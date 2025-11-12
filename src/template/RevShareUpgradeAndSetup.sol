// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {RevShareContractsUpgrader} from "src/RevShareContractsUpgrader.sol";
import {FeeSplitterSetup} from "src/libraries/FeeSplitterSetup.sol";

/// @notice Task for setting up revenue sharing on OP Stack chains.
contract RevShareUpgradeAndSetup is OPCMTaskBase {
    using stdToml for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice RevShareContractsUpgrader address
    address public REV_SHARE_UPGRADER;

    /// @notice RevShare configurations
    RevShareContractsUpgrader.RevShareConfig[] internal revShareConfigs;

    /// @notice Names in the SimpleAddressRegistry that are expected to be written during this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        return new string[](0);
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {
        return new string[](0);
    }

    /// @notice Sets the allowed storage accesses - override to add portal addresses
    function _setAllowedStorageAccesses() internal virtual override {
        super._setAllowedStorageAccesses();
        // Add portal addresses as they will have storage writes from depositTransaction calls
        for (uint256 i; i < revShareConfigs.length; i++) {
            _allowedStorageAccesses.add(revShareConfigs[i].portal);
        }
    }

    /// @notice Sets up the template with configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address) internal override {
        string memory tomlContent = vm.readFile(taskConfigFilePath);

        // Load RevShareContractsUpgrader address from TOML
        REV_SHARE_UPGRADER = tomlContent.readAddress(".revShareUpgrader");
        require(REV_SHARE_UPGRADER.code.length > 0, "RevShareContractsUpgrader has no code");
        vm.label(REV_SHARE_UPGRADER, "RevShareContractsUpgrader");

        // Set RevShareContractsUpgrader as the allowed target for delegatecall
        OPCM_TARGETS.push(REV_SHARE_UPGRADER);

        // Get the length of the configs array by parsing just the portal addresses
        address[] memory portals = abi.decode(tomlContent.parseRaw(".configs[*].portal"), (address[]));
        require(portals.length > 0, "No configs found");

        // Load RevShare configs by reading each field individually
        // Note: We can't use parseRaw + abi.decode directly because TOML inline tables
        // sort keys alphabetically, which doesn't match the struct field order
        // So we need to read each field separately and construct the struct manually
        for (uint256 i; i < portals.length; i++) {
            string memory basePath = string.concat(".configs[", vm.toString(i), "]");
            revShareConfigs.push(
                RevShareContractsUpgrader.RevShareConfig({
                    portal: tomlContent.readAddress(string.concat(basePath, ".portal")),
                    l1WithdrawerConfig: FeeSplitterSetup.L1WithdrawerConfig({
                        minWithdrawalAmount: tomlContent.readUint(
                            string.concat(basePath, ".l1WithdrawerConfig.minWithdrawalAmount")
                        ),
                        recipient: tomlContent.readAddress(string.concat(basePath, ".l1WithdrawerConfig.recipient")),
                        gasLimit: uint32(tomlContent.readUint(string.concat(basePath, ".l1WithdrawerConfig.gasLimit")))
                    }),
                    chainFeesRecipient: tomlContent.readAddress(string.concat(basePath, ".chainFeesRecipient"))
                })
            );
        }
    }

    /// @notice Builds the actions for executing the operations.
    function _build(address) internal override {
        // Delegatecall into RevShareContractsUpgrader
        // OPCMTaskBase uses Multicall3Delegatecall, so this delegatecall will be captured as an action
        (bool success,) = REV_SHARE_UPGRADER.delegatecall(
            abi.encodeCall(RevShareContractsUpgrader.upgradeAndSetupRevShare, (revShareConfigs))
        );
        require(success, "RevShareUpgradeAndSetup: Delegatecall failed");
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory _actions, address) internal view override {
        MultisigTaskPrinter.printTitle("Validating delegatecall to RevShareContractsUpgrader");

        // For OPCM tasks using delegatecall, we validate that the delegatecall was made correctly.
        // The actual portal calls happen inside the delegatecall and are validated by integration tests.

        require(_actions.length == 1, "Expected exactly one action");

        Action memory action = _actions[0];
        require(action.target == REV_SHARE_UPGRADER, "Delegatecall to RevShareContractsUpgrader not found");
        require(action.value == 0, "Call value must be 0 for delegatecall");

        // Verify it's calling upgradeAndSetupRevShare
        bytes4 selector = bytes4(action.arguments);
        require(
            selector == RevShareContractsUpgrader.upgradeAndSetupRevShare.selector,
            "Wrong function selector for delegatecall"
        );

        // Decode and validate the revShareConfigs argument
        // Skip the first 4 bytes (function selector) and decode the rest
        RevShareContractsUpgrader.RevShareConfig[] memory configs;
        {
            bytes memory args = action.arguments;
            bytes memory argsWithoutSelector = new bytes(args.length - 4);
            for (uint256 j = 4; j < args.length; j++) {
                argsWithoutSelector[j - 4] = args[j];
            }
            configs = abi.decode(argsWithoutSelector, (RevShareContractsUpgrader.RevShareConfig[]));
        }

        // Validate each config
        require(configs.length > 0, "No configs provided");
        require(configs.length == revShareConfigs.length, "Config length mismatch");

        for (uint256 i; i < configs.length; i++) {
            RevShareContractsUpgrader.RevShareConfig memory config = configs[i];

            // Validate portal address is not zero
            require(config.portal != address(0), "Portal address cannot be zero");

            // Validate L1 withdrawer config
            require(config.l1WithdrawerConfig.recipient != address(0), "L1 withdrawer recipient cannot be zero");
            require(config.l1WithdrawerConfig.gasLimit > 0, "Gas limit must be greater than 0");

            // Validate chain fees recipient
            require(config.chainFeesRecipient != address(0), "Chain fees recipient cannot be zero");

            // Validate config matches the expected config from template setup
            require(config.portal == revShareConfigs[i].portal, "Portal address mismatch");
            require(
                config.l1WithdrawerConfig.minWithdrawalAmount
                    == revShareConfigs[i].l1WithdrawerConfig.minWithdrawalAmount,
                "Min withdrawal amount mismatch"
            );
            require(
                config.l1WithdrawerConfig.recipient == revShareConfigs[i].l1WithdrawerConfig.recipient,
                "L1 withdrawer recipient mismatch"
            );
            require(
                config.l1WithdrawerConfig.gasLimit == revShareConfigs[i].l1WithdrawerConfig.gasLimit,
                "Gas limit mismatch"
            );
            require(config.chainFeesRecipient == revShareConfigs[i].chainFeesRecipient, "Chain fees recipient mismatch");
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }
}
