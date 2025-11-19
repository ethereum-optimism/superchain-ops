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
        require(REV_SHARE_UPGRADER != address(0), "RevShareContractsUpgrader address cannot be zero");
        require(REV_SHARE_UPGRADER.code.length > 0, "RevShareContractsUpgrader has no code");
        vm.label(REV_SHARE_UPGRADER, "RevShareContractsUpgrader");

        // Set RevShareContractsUpgrader as the allowed target for delegatecall
        OPCM_TARGETS.push(REV_SHARE_UPGRADER);

        // Load flattened arrays from TOML
        address[] memory portals = abi.decode(tomlContent.parseRaw(".portals"), (address[]));
        address[] memory chainFeesRecipients = abi.decode(tomlContent.parseRaw(".chainFeesRecipients"), (address[]));
        uint256[] memory minWithdrawalAmounts =
            abi.decode(tomlContent.parseRaw(".l1WithdrawerMinWithdrawalAmounts"), (uint256[]));
        address[] memory l1WithdrawerRecipients =
            abi.decode(tomlContent.parseRaw(".l1WithdrawerRecipients"), (address[]));
        uint256[] memory gasLimits = abi.decode(tomlContent.parseRaw(".l1WithdrawerGasLimits"), (uint256[]));

        // Validate all arrays have the same length
        require(portals.length > 0, "No configs found");
        require(
            portals.length == chainFeesRecipients.length && portals.length == minWithdrawalAmounts.length
                && portals.length == l1WithdrawerRecipients.length && portals.length == gasLimits.length,
            "Config arrays length mismatch"
        );

        // Validate individual configuration values and check for duplicates
        for (uint256 i; i < portals.length; i++) {
            // Validate portal address
            require(portals[i] != address(0), string.concat("Portal address cannot be zero at index ", vm.toString(i)));
            require(portals[i].code.length > 0, string.concat("Portal has no code at index ", vm.toString(i)));

            // Check for duplicate portals
            for (uint256 j; j < i; j++) {
                require(portals[i] != portals[j], string.concat("Duplicate portal address at index ", vm.toString(i)));
            }

            // Validate chain fees recipient
            require(
                chainFeesRecipients[i] != address(0),
                string.concat("Chain fees recipient cannot be zero at index ", vm.toString(i))
            );

            // Validate L1 withdrawer recipient
            require(
                l1WithdrawerRecipients[i] != address(0),
                string.concat("L1 withdrawer recipient cannot be zero at index ", vm.toString(i))
            );

            // Validate gas limit bounds
            require(gasLimits[i] > 0, string.concat("Gas limit must be greater than 0 at index ", vm.toString(i)));
            require(
                gasLimits[i] <= type(uint32).max,
                string.concat("Gas limit exceeds uint32 max at index ", vm.toString(i))
            );
        }

        // Construct RevShare configs array from flattened arrays
        for (uint256 i; i < portals.length; i++) {
            revShareConfigs.push(
                RevShareContractsUpgrader.RevShareConfig({
                    portal: portals[i],
                    l1WithdrawerConfig: FeeSplitterSetup.L1WithdrawerConfig({
                        minWithdrawalAmount: minWithdrawalAmounts[i],
                        recipient: l1WithdrawerRecipients[i],
                        gasLimit: uint32(gasLimits[i])
                    }),
                    chainFeesRecipient: chainFeesRecipients[i]
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
