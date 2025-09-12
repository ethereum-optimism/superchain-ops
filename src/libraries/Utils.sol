// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "lib/forge-std/src/Vm.sol";
import {SafeData, TaskPayload} from "src/libraries/MultisigTypes.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

library Utils {
    using LibString for string;

    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @notice Helper function to simplify feature-flagging by reading an environment variable
    /// @param _feature The name of the feature flag environment variable to check
    /// @return bool True if the feature is enabled (env var is true or 1), false otherwise
    function isFeatureEnabled(string memory _feature) internal view returns (bool) {
        return vm.envOr(_feature, false) || vm.envOr(_feature, uint256(0)) == 1;
    }

    /// @notice Checks if the current Foundry profile is the CI profile.
    function isCiFoundryProfile() internal view returns (bool) {
        return vm.envOr("FOUNDRY_PROFILE", string("")).eq("ci");
    }

    /// @notice Checks if the skip decode and print feature is enabled.
    function skipDecodeAndPrint() internal view returns (bool) {
        // Skip heavy decode/print in CI, or when fast/suppress flags are enabled
        if (isCiFoundryProfile()) return true;
        if (isFeatureEnabled("SKIP_DECODE_AND_PRINT")) return true;
        return false;
    }

    /// @notice Checks that values have code on this chain.
    /// This method is not storage-layout-aware and therefore is not perfect. It may return erroneous
    /// results for cases like packed slots, and silently show that things are okay when they are not.
    function isLikelyAddressThatShouldHaveCode(uint256 value, address[] memory codeExceptions)
        internal
        pure
        returns (bool)
    {
        // If out of range (fairly arbitrary lower bound), return false.
        if (value > type(uint160).max) return false;
        if (value < uint256(uint160(0x00000000fFFFffffffFfFfFFffFfFffFFFfFffff))) return false;
        // If the value is a L2 predeploy address it won't have code on this chain, so return false.
        if (
            value >= uint256(uint160(0x4200000000000000000000000000000000000000))
                && value <= uint256(uint160(0x420000000000000000000000000000000000FffF))
        ) return false;
        // Allow known EOAs.
        for (uint256 i; i < codeExceptions.length; i++) {
            require(
                codeExceptions[i] != address(0),
                "getCodeExceptions includes the zero address, please make sure all entries are populated."
            );
            if (address(uint160(value)) == codeExceptions[i]) return false;
        }
        // Otherwise, this value looks like an address that we'd expect to have code.
        return true;
    }

    /// @notice Returns true if a list contains an address.
    function contains(address[] memory _list, address _addr) internal pure returns (bool) {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _addr) return true;
        }
        return false;
    }

    /// @notice Returns true if a list contains a string.
    function contains(string[] memory _list, string memory _str) internal pure returns (bool) {
        for (uint256 i = 0; i < _list.length; i++) {
            if (LibString.eq(_list[i], _str)) return true;
        }
        return false;
    }

    /// @notice Validate that the safes are in the correct order.
    function validateSafesOrder(address[] memory _allSafes) internal view {
        require(_allSafes.length > 0, "Utils: no safes provided");
        for (uint256 i = 1; i < _allSafes.length; i++) {
            require(
                IGnosisSafe(_allSafes[i]).isOwner(_allSafes[i - 1]),
                string.concat(
                    "Utils: Safe ", vm.toString(_allSafes[i - 1]), " is not an owner of ", vm.toString(_allSafes[i])
                )
            );
        }
    }

    /// @notice Helper function to get the safe, call data, and original nonce for a given index.
    function getSafeData(TaskPayload memory _payload, uint256 _index)
        internal
        pure
        returns (SafeData memory safeData_)
    {
        safeData_.safe = _payload.safes[_index];
        safeData_.callData = _payload.calldatas[_index];
        safeData_.nonce = _payload.originalNonces[_index];
    }

    /// @notice Returns all child safes except the root safe.
    function getChildSafes(TaskPayload memory _payload) internal pure returns (address[] memory) {
        address[] memory childSafes = new address[](_payload.safes.length - 1);
        for (uint256 i = 0; i < _payload.safes.length - 1; i++) {
            childSafes[i] = _payload.safes[i];
        }
        return childSafes;
    }
}
