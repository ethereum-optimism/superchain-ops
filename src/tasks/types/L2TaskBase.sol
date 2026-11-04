// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigTask, AddressRegistry} from "src/tasks/MultisigTask.sol";
import {MultisigTaskPrinter} from "src/libraries/MultisigTaskPrinter.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {console} from "forge-std/console.sol";
import {StdStyle} from "forge-std/StdStyle.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {TaskType} from "src/libraries/MultisigTypes.sol";

/// @notice This contract is used for all L2 task types. It overrides various functions in the MultisigTask contract.
abstract contract L2TaskBase is MultisigTask {
    using EnumerableSet for EnumerableSet.AddressSet;
    using StdStyle for string;
    using stdToml for string;

    /// @notice The superchain address registry.
    SuperchainAddressRegistry public superchainAddrRegistry;

    /// @notice Blocks behind the reported L2 head at which `_createL2PreflightFork` forks. Set by the
    ///         optional `l2ForkHeadLag` config key; 0 (the default) forks at latest. Use it for L2 RPCs
    ///         whose load-balanced backends can lag the head they report.
    uint256 public l2ForkHeadLag;

    /// @notice Returns the type of task. L2TaskBase.
    /// Overrides the taskType function in the MultisigTask contract.
    function taskType() public pure virtual override returns (TaskType) {
        return TaskType.L2TaskBase;
    }

    /// @notice Configures the task for L2TaskBase type tasks.
    /// Overrides the configureTask function in the MultisigTask contract.
    /// For L2TaskBase, we need to configure the superchain address registry.
    function _configureTask(string memory taskConfigFilePath)
        internal
        virtual
        override
        returns (AddressRegistry addrRegistry_, IGnosisSafe parentMultisig_, address multicallTarget_)
    {
        multicallTarget_ = MULTICALL3_ADDRESS;
        l2ForkHeadLag = _readL2ForkHeadLag(taskConfigFilePath);

        superchainAddrRegistry = new SuperchainAddressRegistry(taskConfigFilePath);
        addrRegistry_ = AddressRegistry.wrap(address(superchainAddrRegistry));

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        // Try to get the parentMultisig globally first. If it exists globally, return it.
        // Otherwise we assume that the safe address is defined per-chain and we need to check for
        // each chain that all of the addresses are the same.
        try superchainAddrRegistry.get(templateConfig.safeAddressString) returns (address addr) {
            parentMultisig_ = IGnosisSafe(addr);
        } catch {
            parentMultisig_ =
                IGnosisSafe(superchainAddrRegistry.getAddress(templateConfig.safeAddressString, chains[0].chainId));
            // Ensure that all chains have the same parentMultisig.
            for (uint256 i = 1; i < chains.length; i++) {
                require(
                    address(parentMultisig_)
                        == superchainAddrRegistry.getAddress(templateConfig.safeAddressString, chains[i].chainId),
                    string.concat(
                        "MultisigTask: safe address mismatch. Caller: ",
                        MultisigTaskPrinter.getAddressLabel(address(parentMultisig_)),
                        ". Actual address: ",
                        MultisigTaskPrinter.getAddressLabel(
                            superchainAddrRegistry.getAddress(templateConfig.safeAddressString, chains[i].chainId)
                        )
                    )
                );
            }
        }
    }

    /// @notice Reads the optional `l2ForkHeadLag` config key, defaulting to 0.
    function _readL2ForkHeadLag(string memory _taskConfigFilePath) private view returns (uint256) {
        string memory toml = vm.readFile(_taskConfigFilePath);
        return toml.keyExists(".l2ForkHeadLag") ? toml.readUint(".l2ForkHeadLag") : 0;
    }

    /// @notice Creates and selects a fork of `_l2RpcUrl` at latest, or `l2ForkHeadLag` blocks behind
    ///         the head it reports.
    function _createL2PreflightFork(string memory _l2RpcUrl) internal {
        if (l2ForkHeadLag == 0) {
            vm.createSelectFork(_l2RpcUrl);
            return;
        }
        bytes memory raw = vm.rpc(_l2RpcUrl, "eth_blockNumber", "[]");
        uint256 head;
        for (uint256 i; i < raw.length; i++) {
            head = (head << 8) | uint8(raw[i]);
        }
        vm.createSelectFork(_l2RpcUrl, head - l2ForkHeadLag);
    }

    /// @notice Empty override to satisfy the MultisigTask contract. May include common logic at a later date.
    function _templateSetup(string memory, address) internal virtual override {}

    /// @notice Sets the allowed storage keys.
    function _setAllowedStorageAccesses() internal virtual override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        // Add allowed storage accesses
        for (uint256 i = 0; i < templateConfig.allowedStorageKeys.length; i++) {
            for (uint256 j = 0; j < chains.length; j++) {
                _tryAddAddress(
                    templateConfig.allowedStorageKeys[i], chains[j], _allowedStorageAccesses, "allowed storage accesses"
                );
            }
        }
    }

    /// @notice Sets the allowed balance changes.
    function _setAllowedBalanceChanges() internal virtual override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        // Add allowed balance changes
        for (uint256 i = 0; i < templateConfig.allowedBalanceChanges.length; i++) {
            for (uint256 j = 0; j < chains.length; j++) {
                _tryAddAddress(
                    templateConfig.allowedBalanceChanges[i],
                    chains[j],
                    _allowedBalanceChanges,
                    "allowed balance changes"
                );
            }
        }
    }

    /// @notice Attempts to add an address to the target set for a given key and chain.
    /// The order of resolution is important: we first call `superchainAddrRegistry.get()`,
    /// which checks config-defined addresses (e.g. `[addresses]` in `config.toml` or `addresses.toml`).
    /// If that fails, we fall back to `superchainAddrRegistry.getAddress()`, which discovers addresses onchain.
    /// This ensures config-defined addresses take precedence over onchain discovery.
    function _tryAddAddress(
        string memory key,
        SuperchainAddressRegistry.ChainInfo memory chain,
        EnumerableSet.AddressSet storage targetSet,
        string memory context
    ) private {
        require(gasleft() > 500_000, "MultisigTask: Insufficient gas for initial getAddress() call"); // Ensure try/catch is EIP-150 safe.
        // Addresses that are not discovered automatically (e.g. OPCM, StandardValidator, or safes missing from addresses.toml).
        try superchainAddrRegistry.get(key) returns (address addr) {
            targetSet.add(addr);
        } catch {
            require(gasleft() > 500_000, "MultisigTask: Insufficient gas for fallback get() call"); // Ensure try/catch is EIP-150 safe.
            try superchainAddrRegistry.getAddress(key, chain.chainId) returns (address addr) {
                targetSet.add(addr);
            } catch {
                string memory warn = string("[WARN]").yellow().bold();
                // forgefmt: disable-start
                console.log(string.concat(warn, " Contract: ", key, " not found for chain: ", chain.name));
                console.log(string.concat(warn, " Contract will not be added to ", context, ": ", key, " for chain: ", chain.name));
                // forgefmt: disable-end
            }
        }
    }
}
