// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {AddressRegistry} from "src/improvements/AddressRegistry.sol";
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

    function _deployAddressRegistry(string memory taskConfigFilePath) internal override returns (AddressRegistry) {
        return new AddressRegistry(taskConfigFilePath);
    }
}
