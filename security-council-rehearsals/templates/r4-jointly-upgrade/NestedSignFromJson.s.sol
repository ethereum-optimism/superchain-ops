// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

// This import path should be relative to where the rehearsal script will be located after a new rehearsal is setup,
// which is one level above the current location in
//  repo_root/security-council-rehearsals/<rehearsal-dir>/NestedSignFromJson.s.sol
import {NestedSignFromJson as OriginalNestedSignFromJson} from "../../script/NestedSignFromJson.s.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

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
