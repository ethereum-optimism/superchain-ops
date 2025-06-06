// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice Template contract to transfer ownership of the L2 ProxyAdmin to the aliased L1 ProxyAdmin owner.
/// The user provides the unaliased L1 PAO owner, and this template aliases the address and transfers ownership.
/// This template creates a transaction that executes on L1 via the OptimismPortal which is then forwarded to the L2.
/// See: https://docs.optimism.io/stack/transactions/deposit-flow
///
/// ATTENTION: Use caution when using this template — transferring ownership is high risk.
/// To gain additional assurance that the corresponding L2 deposit transaction works as expected,
/// you must follow the steps outlined in the documentation: ../doc/simulate-l2-ownership-transfer.md
/// Add the results of the simulation to the VALIDATION.md file for the task.
///
/// Manual Post-Execution checks to follow when executing this task:
/// 1. Find the L2 deposit transaction by identifying the alias of the L1 ProxyAdmin owner safe.
/// 2. The transaction you're looking for should be the most recent transaction sent from the aliased
///    L1PAO address on L2. If it's not, then it should be the most recent transaction that was interacting
///    with the L1 ProxyAdmin 0x4200000000000000000000000000000000000018.
/// 3. Once you've found the correct transaction, verify that the expected log event was emitted i.e. 'emit OwnershipTransferred(oldOwner, newOwner)'.
contract TransferL2PAOFromL1 is L2TaskBase {
    using stdToml for string;

    /// @notice The new owner address. This address is unaliased.
    address public newOwnerToAlias;

    /// @notice The aliased L1 PAO owner.
    address public aliasedNewOwner;

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
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory toml = vm.readFile(taskConfigFilePath);

        // New owner address. This address is unaliased.
        newOwnerToAlias = abi.decode(vm.parseToml(toml, ".newOwnerToAlias"), (address));
        // Apply the alias to the new owner.
        aliasedNewOwner = AddressAliasHelper.applyL1ToL2Alias(newOwnerToAlias);

        // Only allow one chain to be modified at a time with this template.
        SuperchainAddressRegistry.ChainInfo[] memory _chains = superchainAddrRegistry.getChains();
        require(_chains.length == 1, "Must specify exactly one chain id to transfer ownership for");
    }

    /// @notice Builds the actions for transferring ownership of the proxy admin on the L2. It does this by calling the L1
    /// OptimismPortal's depositTransaction function.
    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        // Verify that the new owner is the current L1PAO owner. This template assumes that all L1 ownership transfers have already been completed.
        ProxyAdmin proxyAdmin = ProxyAdmin(superchainAddrRegistry.getAddress("ProxyAdmin", chains[0].chainId));
        require(proxyAdmin.owner() == newOwnerToAlias, "New owner is not the current L1PAO owner");

        // See this Tenderly simulation for an example of this gas limit working: https://www.tdly.co/shared/simulation/d5028138-469c-4bb2-97fd-50f5f4bb8515
        uint64 gasLimit = 200000;
        OptimismPortal optimismPortal =
            OptimismPortal(superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[0].chainId));
        optimismPortal.depositTransaction(
            address(Predeploys.PROXY_ADMIN),
            0,
            gasLimit,
            false,
            abi.encodeCall(ProxyAdmin.transferOwnership, (aliasedNewOwner))
        );
    }

    /// @notice Validates that the owner was transferred correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        // We can't currently perform an assertion on the L2 because the transaction is only simulated and not actually executed,
        // so it's up to the user to manually assert that. See the manual post-execution checks documented in the comments
        // at the top of this file.
        // assertEq(ProxyAdmin(l2ProxyAdminPredeploy).owner(), aliasedNewOwner, "aliased new owner not set correctly");
    }

    /// @notice Aliased new owner is a code exception. This is because the aliased address is not a contract.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        address[] memory codeExceptions = new address[](0);
        return codeExceptions;
    }
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
