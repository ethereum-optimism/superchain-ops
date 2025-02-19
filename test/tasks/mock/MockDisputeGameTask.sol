// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {IProxy} from "@eth-optimism-bedrock/interfaces/universal/IProxy.sol";
import {VmSafe} from "forge-std/Vm.sol";

import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {DisputeGameUpgradeTemplate} from "src/improvements/template/DisputeGameUpgradeTemplate.sol";

/// Mock task that upgrades the Dispute Game implementation
/// to an example implementation address without code
contract MockDisputeGameTask is DisputeGameUpgradeTemplate {
    /// @notice code exceptions for this template is address 0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        address[] memory addresses = new address[](1);
        addresses[0] = address(0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf);

        return addresses;
    }
}
