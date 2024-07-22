// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "../../../scripts/NestedSignFromJson.s.sol"

contract NestedSignFromJson is OriginalNestedSignFromJson {
    // Since after _postCheck hook `require(false)`, the transaction will revert
    // contract extending NestedSignFromJson must implement its own _postCheck method, thus enforcing a more robust implementation pattern.
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory simPayload)
        internal
        virtual
        override
    {
        // Empty implementation for CI tasks
        accesses; // Silences compiler warnings.
        simPayload;
    }
}
