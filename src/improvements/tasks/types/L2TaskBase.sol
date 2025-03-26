// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MultisigTask, AddressRegistry} from "src/improvements/tasks/MultisigTask.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {console} from "forge-std/console.sol";

abstract contract L2TaskBase is MultisigTask {
    using EnumerableSet for EnumerableSet.AddressSet;

    SuperchainAddressRegistry public superchainAddrRegistry;

    /// @notice Returns the type of task. L2TaskBase.
    /// Overrides the taskType function in the MultisigTask contract.
    function taskType() public pure override returns (TaskType) {
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
        multicallTarget_ = MULTICALL3_NO_VALUE_CHECK_ADDRESS;

        superchainAddrRegistry = new SuperchainAddressRegistry(taskConfigFilePath);
        addrRegistry_ = AddressRegistry.wrap(address(superchainAddrRegistry));

        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        parentMultisig_ = IGnosisSafe(superchainAddrRegistry.getAddress(config.safeAddressString, chains[0].chainId));
        // Ensure that all chains have the same parentMultisig.
        for (uint256 i = 1; i < chains.length; i++) {
            require(
                address(parentMultisig_)
                    == superchainAddrRegistry.getAddress(config.safeAddressString, chains[i].chainId),
                string.concat(
                    "MultisigTask: safe address mismatch. Caller: ",
                    getAddressLabel(address(parentMultisig_)),
                    ". Actual address: ",
                    getAddressLabel(superchainAddrRegistry.getAddress(config.safeAddressString, chains[i].chainId))
                )
            );
        }
    }

    /// @notice We use this function to add allowed storage accesses.
    function _templateSetup(string memory) internal virtual override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < config.allowedStorageKeys.length; i++) {
            for (uint256 j = 0; j < chains.length; j++) {
                require(gasleft() > 500_000, "MultisigTask: Insufficient gas for initial getAddress() call"); // Ensure try/catch is EIP-150 safe.
                try superchainAddrRegistry.getAddress(config.allowedStorageKeys[i], chains[j].chainId) returns (
                    address addr
                ) {
                    _allowedStorageAccesses.add(addr);
                } catch {
                    require(gasleft() > 500_000, "MultisigTask: Insufficient gas for fallback get() call"); // Ensure try/catch is EIP-150 safe.
                    try superchainAddrRegistry.get(config.allowedStorageKeys[i]) returns (address addr) {
                        _allowedStorageAccesses.add(addr);
                    } catch {
                        console.log(
                            "\x1B[33m[WARN]\x1B[0m Contract: %s not found for chain: '%s'",
                            config.allowedStorageKeys[i],
                            chains[j].name
                        );
                        console.log(
                            "\x1B[33m[WARN]\x1B[0m Contract will not be added to allowed storage accesses: '%s' for chain: '%s'",
                            config.allowedStorageKeys[i],
                            chains[j].name
                        );
                    }
                }
            }
        }
    }
}
