// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OPCMUpgradeV700} from "src/template/OPCMUpgradeV700.sol";

/// @title OPCMConfigureStandardGamesV700
/// @notice Configures the three non-super-root Standard dispute game types through OPCMv2.
/// @dev This template intentionally preserves PERMISSIONED_CANNON as the respected game type
///      while installing CANNON, PERMISSIONED_CANNON, and CANNON_KONA. A later, separately
///      reviewed Guardian task may rotate the respected game type after challenger testing and
///      outstanding withdrawals complete.
contract OPCMConfigureStandardGamesV700 is OPCMUpgradeV700 {
    /// @notice This staged configuration keeps all three non-super-root games available.
    function _isEnabled(uint32 gt, bool) internal pure override returns (bool) {
        return gt == CANNON || gt == PERMISSIONED_CANNON || gt == CANNON_KONA;
    }

    /// @notice Kona is installed even while permissioned Cannon remains respected.
    function _isKonaEnabledForRespectedGameType(uint32) internal pure override returns (bool) {
        return true;
    }
}
