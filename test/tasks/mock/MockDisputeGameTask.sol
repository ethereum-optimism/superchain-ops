// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {DisputeGameUpgradeTemplate} from "test/tasks/mock/template/DisputeGameUpgradeTemplate.sol";

/// Mock task that upgrades the Dispute Game implementation
/// to an example implementation address without code
contract MockDisputeGameTask is DisputeGameUpgradeTemplate {
    /// @notice code exceptions for this template is address 0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf
    function _getCodeExceptions(address) internal view virtual override returns (address[] memory) {
        address[] memory addresses = new address[](1);
        addresses[0] = address(0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf);
        return addresses;
    }
}
