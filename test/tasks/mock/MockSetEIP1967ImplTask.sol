// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {SetEIP1967Implementation} from "src/template/SetEIP1967Implementation.sol";

/// Mock task that sets the implementation of a EIP1967 compliant proxy
/// to an example implementation address without code
contract MockSetEIP1967ImplTask is SetEIP1967Implementation {
    /// @notice code exceptions for this template is address 0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        address[] memory addresses = new address[](1);
        addresses[0] = address(0x0000000FFfFFfffFffFfFffFFFfffffFffFFffFf);
        return addresses;
    }
}
