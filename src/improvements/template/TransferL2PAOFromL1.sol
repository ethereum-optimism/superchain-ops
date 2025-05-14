// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

/// @notice Template contract to transfer ownership of the L2 ProxyAdmin to the aliased L1 ProxyAdmin owner.
/// The user provides the unaliased L1 PAO owner, and this template aliases the address and transfers ownership.
/// This template creates a transaction that executes on L1 via the OptimismPortal which is then forwarded to the L2.
/// See: https://docs.optimism.io/stack/transactions/deposit-flow
/// ATTENTION: Please use caution when using this template. Transferring ownership is high risk.
///
/// Post-Execution Checks
/// 1. Find the L2 deposit transaction by identifying the alias of the L1 ProxyAdmin owner safe.
/// 2. The transaction you're looking for should be the most recent transaction sent from the aliased L1PAO adress on L2. If it's not, then it should be a recent transaction from that was interacting with the L1 ProxyAdmin 0x4200000000000000000000000000000000000018.
/// 3. Once you've found the correct transaction, verify that the expected log event was emitted i.e. 'emit OwnershipTransferred(oldOwner, newOwner)'.
contract TransferL2PAOfromL1 is L2TaskBase {
    using stdToml for string;

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
        address newOwnerToAlias = abi.decode(vm.parseToml(toml, ".newOwnerToAlias"), (address));
        // Apply the alias to the new owner.
        aliasedNewOwner = AddressAliasHelper.applyL1ToL2Alias(newOwnerToAlias);

        // Only allow one chain to be modified at a time with this template.
        SuperchainAddressRegistry.ChainInfo[] memory _chains =
            abi.decode(vm.parseToml(toml, ".l2chains"), (SuperchainAddressRegistry.ChainInfo[]));
        require(_chains.length == 1, "Must specify exactly one chain id to transfer ownership for");
    }

    /// @notice Builds the actions for transferring ownership of the proxy admin on the L2.
    function _build() internal override {
        uint64 gasLimit = 200000; // This gas limit was used for an example task previously: tasks/sep/010-op-l2-predeploy-upgrade-from-l1/input.json
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        OptimismPortal optimismPortal =
            OptimismPortal(superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[0].chainId));
        optimismPortal.depositTransaction(
            address(Predeploys.PROXY_ADMIN),
            0,
            gasLimit,
            false,
            abi.encodeWithSelector(ProxyAdmin.transferOwnership.selector, aliasedNewOwner)
        );
    }

    /// @notice Validates that the owner was transferred correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        // TODO: We can't currently perform an assertion on the L2 because the transaction is only simulated and not actually executed.
        // assertEq(ProxyAdmin(l2ProxyAdminPredeploy).owner(), aliasedNewOwner, "aliased new owner not set correctly");
    }

    /// @notice Aliased new owner is a code exception. This is because the aliased address is not a contract.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        address[] memory codeExceptions = new address[](1);
        codeExceptions[0] = aliasedNewOwner;
        return codeExceptions;
    }
}

/// OptimismPortal2.sol
interface OptimismPortal {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface ProxyAdmin {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}
