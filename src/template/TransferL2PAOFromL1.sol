// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice Template contract to transfer ownership of the L2 ProxyAdmin to the aliased L1 ProxyAdmin owner
/// for one or more chains. The user provides the unaliased L1 PAO owner, and this template aliases the
/// address and transfers ownership. All chains in the task are transferred to the same new owner.
/// This template creates one transaction per chain that executes on L1 via that chain's OptimismPortal
/// which is then forwarded to the L2. See: https://docs.optimism.io/stack/transactions/deposit-flow
///
/// ATTENTION: Use caution when using this template — transferring ownership is high risk.
/// To gain additional assurance that the corresponding L2 deposit transactions work as expected,
/// you must follow the steps outlined in the documentation for EACH chain in the task:
/// ../../docs/simulate-l2-ownership-transfer.md
/// Add the results of the simulations to the VALIDATION.md file for the task.
///
/// Manual Post-Execution checks to follow when executing this task, repeated for each chain:
/// 1. Find the L2 deposit transaction by identifying the alias of the L1 ProxyAdmin owner safe.
/// 2. The transaction you're looking for should be the most recent transaction sent from the aliased
///    L1PAO address on that L2. If it's not, then it should be the most recent transaction that was interacting
///    with the L2 ProxyAdmin 0x4200000000000000000000000000000000000018.
/// 3. Once you've found the correct transaction, verify that the expected log event was emitted i.e. 'emit OwnershipTransferred(oldOwner, newOwner)'.
contract TransferL2PAOFromL1 is L2TaskBase {
    using stdToml for string;

    /// @notice The gas limit for each L2 deposit transaction.
    /// See this Tenderly simulation for an example of this gas limit working: https://www.tdly.co/shared/simulation/d5028138-469c-4bb2-97fd-50f5f4bb8515
    uint64 public constant DEPOSIT_GAS_LIMIT = 200000;

    /// @notice The new owner address. This address is unaliased.
    address public newOwnerToAlias;

    /// @notice The aliased L1 PAO owner.
    address public aliasedNewOwner;

    /// @notice Stores the chain information for all chains in the task after setup.
    SuperchainAddressRegistry.ChainInfo[] internal taskChains;

    /// @notice Returns the safe address string identifier
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "OptimismPortalProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with the new owner from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory toml = vm.readFile(taskConfigFilePath);

        // New owner address. This address is unaliased.
        newOwnerToAlias = abi.decode(vm.parseToml(toml, ".newOwnerToAlias"), (address));
        // Apply the alias to the new owner.
        aliasedNewOwner = AddressAliasHelper.applyL1ToL2Alias(newOwnerToAlias);

        SuperchainAddressRegistry.ChainInfo[] memory _chains = superchainAddrRegistry.getChains();
        require(_chains.length > 0, "Must specify at least one chain id to transfer ownership for");
        for (uint256 i = 0; i < _chains.length; i++) {
            taskChains.push(_chains[i]);
        }
    }

    /// @notice Builds the actions for transferring ownership of the proxy admin on the L2 for each chain in the
    /// task. It does this by calling each chain's L1 OptimismPortal depositTransaction function.
    function _build(address) internal override {
        for (uint256 i = 0; i < taskChains.length; i++) {
            SuperchainAddressRegistry.ChainInfo memory chain = taskChains[i];
            // Verify that the new owner is the current L1PAO owner. This template assumes that all L1 ownership transfers have already been completed.
            ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chain.chainId));
            require(
                proxyAdmin.owner() == newOwnerToAlias,
                string.concat("New owner is not the current L1PAO owner for chain ", chain.name)
            );

            OptimismPortal optimismPortal =
                OptimismPortal(superchainAddrRegistry.getAddress("OptimismPortalProxy", chain.chainId));
            optimismPortal.depositTransaction(
                address(Predeploys.PROXY_ADMIN),
                0,
                DEPOSIT_GAS_LIMIT,
                false,
                abi.encodeCall(ProxyAdmin.transferOwnership, (aliasedNewOwner))
            );
        }
    }

    /// @notice Validates that one depositTransaction action was created per chain with the expected calldata.
    /// We can't perform an assertion on the L2 state because the transaction is only simulated and not actually
    /// executed, so it's up to the user to manually assert that. See the manual post-execution checks documented
    /// in the comments at the top of this file.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory actions, address) internal view override {
        bytes memory expectedCalldata = abi.encodeCall(
            OptimismPortal.depositTransaction,
            (
                address(Predeploys.PROXY_ADMIN),
                0,
                DEPOSIT_GAS_LIMIT,
                false,
                abi.encodeCall(ProxyAdmin.transferOwnership, (aliasedNewOwner))
            )
        );

        for (uint256 i = 0; i < taskChains.length; i++) {
            address expectedPortal = superchainAddrRegistry.getAddress("OptimismPortalProxy", taskChains[i].chainId);

            // Check that we have exactly one action to this chain's OptimismPortal with the expected calldata.
            uint256 matches = 0;
            for (uint256 j = 0; j < actions.length; j++) {
                if (actions[j].target == expectedPortal) {
                    assertEq(
                        keccak256(actions[j].arguments), keccak256(expectedCalldata), "unexpected calldata for portal"
                    );
                    assertEq(actions[j].value, 0, "Should not send ETH with depositTransaction");
                    matches++;
                }
            }
            assertEq(matches, 1, "Should have exactly one depositTransaction action per chain");
        }
        assertEq(actions.length, taskChains.length, "Should have exactly one action per chain");
    }

    /// @notice No code exceptions for this template.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface OptimismPortal {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface ProxyAdmin {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}
