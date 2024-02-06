// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console2 as console} from "forge-std/console2.sol";

/*
- consider adding StorageAccess.previousValue, avoid surprises with interspersed upgrades
- diff spec could be auto generated and then annotated by hand.
- https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/test/kontrol/scripts/json/clean_json.py#L1
    - Ask mofi why it prints with all that escaping
    - also about the account field in the access structs
- cheatcodes to keep in mind:
    - loadAllocs <-> dumpState
*/

library LibStateDiffChecker {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct StorageDiffSpec {
        address account;
        bytes32 newValue;
        bytes32 previousValue;
        bytes32 slot;
    }

    struct StateDiffSpec {
        uint256 chainId;
        StorageDiffSpec[] storageAccesses;
    }

    error StateDiffMismatch(string field, bytes32 expected, bytes32 actual);

    /// @notice Parses the JSON data to extract account access specifications.
    /// @param _jsonData     The JSON string containing the account access specifications.
    /// @return stateDiffSpec_ An array of StorageDiffSpec structs parsed from the JSON data.
    function parseDiffSpecs(string memory _jsonData) internal pure returns (StateDiffSpec memory stateDiffSpec_) {
        stateDiffSpec_ = abi.decode(vm.parseJson(_jsonData), (StateDiffSpec));
    }

    /// @notice Filters account accesses to return only those that modified storage.
    /// @param accesses An array of account accesses recorded by the EVM.
    /// @return stateDiffSpec_ An array of account accesses that modified storage.
    function extractDiffSpecFromAcccountAccesses(VmSafe.AccountAccess[] memory accesses)
        internal
        pure
        returns (StateDiffSpec memory stateDiffSpec_)
    {
        // todo
    }

    /// @notice Checks if a single expected account access matches the actual account access.
    /// @param expectedDiff The expected account access details.
    /// @param actualDiff   The actual account access details recorded by the EVM.
    function checkStateDiff(StateDiffSpec memory expectedDiff, StateDiffSpec memory actualDiff) internal pure {
        // todo
    }
}
