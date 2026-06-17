// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {MockMultisigTask} from "test/tasks/mock/MockMultisigTask.sol";

/// @notice A MockMultisigTask that reports a broadcast (i.e. `just execute`) context.
/// Used to test that the empty-signatures self-approve branch does NOT bump owner
/// nonces when broadcasting (which would otherwise create a broadcast nonce gap).
contract MockBroadcastMultisigTask is MockMultisigTask {
    function _isBroadcastContext() internal pure override returns (bool) {
        return true;
    }
}
