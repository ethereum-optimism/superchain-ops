// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console2 as console} from "forge-std/console2.sol";

library LibStateDiffChecker {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    // The order of the fields in the struct is important, and must be alphabetical for some reason related to
    // how foundry encodes the struct to and from JSON.
    struct StorageDiffSpec {
        address account;
        bytes32 newValue;
        bytes32 previousValue;
        bytes32 slot;
    }

    struct StateDiffSpec {
        uint256 chainId;
        StorageDiffSpec[] storageSpecs;
    }

    error StateDiffMismatch(string field, bytes32 expected, bytes32 actual);

    /// @notice Parses the JSON data to extract account access specifications.
    /// @param _jsonData The JSON string containing the account access specifications.
    /// @return stateDiffSpec_ An array of StorageDiffSpec structs parsed from the JSON data.
    function parseDiffSpecs(string memory _jsonData) internal pure returns (StateDiffSpec memory stateDiffSpec_) {
        stateDiffSpec_ = abi.decode(vm.parseJson(_jsonData), (StateDiffSpec));
    }

    /// @notice Filters account accesses to return only those that modified storage.
    /// @param accountAccesses An array of account accesses recorded by the EVM.
    /// @return stateDiffSpec_ An array of account accesses that modified storage.
    function extractDiffSpecFromAcccountAccesses(VmSafe.AccountAccess[] memory accountAccesses)
        internal
        pure
        returns (StateDiffSpec memory stateDiffSpec_)
    {
        // Get the chain ID from the first account access.
        stateDiffSpec_.chainId = accountAccesses[0].chainInfo.chainId;

        // First iterate through the account accesses and storage accesses to count the number of storage modifications,
        // so that we can allocate the correct amount of memory for the StorageDiffSpec.
        uint256 modifiedCount = 0;
        for (uint256 acctIndex = 0; acctIndex < accountAccesses.length; acctIndex++) {
            for (
                uint256 storageIndex = 0;
                storageIndex < accountAccesses[acctIndex].storageAccesses.length;
                storageIndex++
            ) {
                if (
                    accountAccesses[acctIndex].storageAccesses[storageIndex].previousValue
                        != accountAccesses[acctIndex].storageAccesses[storageIndex].newValue
                ) {
                    modifiedCount++;
                }
            }
        }

        // Allocate memory for the storage modifications.
        stateDiffSpec_.storageSpecs = new StorageDiffSpec[](modifiedCount);

        // Then iterate again through the account accesses and storage accesses to populate the StorageDiffSpec.
        uint256 specIndex = 0; // index for next write to stateDiffSpec_.storageSpecs
        for (uint256 acctIndex = 0; acctIndex < accountAccesses.length; acctIndex++) {
            for (
                uint256 storageIndex = 0;
                storageIndex < accountAccesses[acctIndex].storageAccesses.length;
                storageIndex++
            ) {
                if (
                    accountAccesses[acctIndex].storageAccesses[storageIndex].previousValue
                        != accountAccesses[acctIndex].storageAccesses[storageIndex].newValue
                ) {
                    stateDiffSpec_.storageSpecs[specIndex] = StorageDiffSpec({
                        account: accountAccesses[acctIndex].storageAccesses[storageIndex].account,
                        newValue: accountAccesses[acctIndex].storageAccesses[storageIndex].newValue,
                        previousValue: accountAccesses[acctIndex].storageAccesses[storageIndex].previousValue,
                        slot: accountAccesses[acctIndex].storageAccesses[storageIndex].slot
                    });
                    specIndex++;
                }
            }
        }

        require(specIndex == modifiedCount, "LibStateDiffChecker: found fewer storage modifications than expected.");
    }

    /// @notice Checks if a single expected account access matches the actual account access.
    /// @param expectedDiff The expected account access details.
    /// @param actualDiff   The actual account access details recorded by the EVM.
    function checkStateDiff(StateDiffSpec memory expectedDiff, StateDiffSpec memory actualDiff) internal pure {
        console.log("Checking chainId", expectedDiff.chainId);
        if (expectedDiff.chainId != actualDiff.chainId) {
            revert StateDiffMismatch("chainId", bytes32(expectedDiff.chainId), bytes32(actualDiff.chainId));
        }
        console.log("Checking storage specs length", expectedDiff.storageSpecs.length, actualDiff.storageSpecs.length);
        if (expectedDiff.storageSpecs.length != actualDiff.storageSpecs.length) {
            revert StateDiffMismatch(
                "storageSpecs.length",
                bytes32(expectedDiff.storageSpecs.length),
                bytes32(actualDiff.storageSpecs.length)
            );
        }
        for (uint256 i = 0; i < expectedDiff.storageSpecs.length; i++) {
            console.log("Checking", string.concat("storageSpecs[", vm.toString(i), "].account"));
            console.log("Expected", vm.toString(expectedDiff.storageSpecs[i].account));
            console.log("Actual  ", vm.toString(actualDiff.storageSpecs[i].account));
            if (expectedDiff.storageSpecs[i].account != actualDiff.storageSpecs[i].account) {
                revert StateDiffMismatch(
                    string.concat("storageSpecs[", vm.toString(i), "].account"),
                    bytes32(uint256(uint160(expectedDiff.storageSpecs[i].account))),
                    bytes32(uint256(uint160(actualDiff.storageSpecs[i].account)))
                );
            }

            console.log("Checking", string.concat("storageSpecs[", vm.toString(i), "].slot"));
            console.log("Expected", vm.toString(expectedDiff.storageSpecs[i].slot));
            console.log("Actual  ", vm.toString(actualDiff.storageSpecs[i].slot));
            if (expectedDiff.storageSpecs[i].slot != actualDiff.storageSpecs[i].slot) {
                revert StateDiffMismatch(
                    string.concat("storageSpecs[", vm.toString(i), "].slot"),
                    expectedDiff.storageSpecs[i].slot,
                    actualDiff.storageSpecs[i].slot
                );
            }

            console.log("Checking", string.concat("storageSpecs[", vm.toString(i), "].newValue"));
            console.log("Expected", vm.toString(expectedDiff.storageSpecs[i].newValue));
            console.log("Actual  ", vm.toString(actualDiff.storageSpecs[i].newValue));
            if (expectedDiff.storageSpecs[i].newValue != actualDiff.storageSpecs[i].newValue) {
                revert StateDiffMismatch(
                    string.concat("storageSpecs[", vm.toString(i), "].newValue"),
                    expectedDiff.storageSpecs[i].newValue,
                    actualDiff.storageSpecs[i].newValue
                );
            }

            console.log("Checking", string.concat("storageSpecs[", vm.toString(i), "].previousValue"));
            console.log("Expected", vm.toString(expectedDiff.storageSpecs[i].previousValue));
            console.log("Actual  ", vm.toString(actualDiff.storageSpecs[i].previousValue));
            if (expectedDiff.storageSpecs[i].previousValue != actualDiff.storageSpecs[i].previousValue) {
                revert StateDiffMismatch(
                    string.concat("storageSpecs[", vm.toString(i), "].previousValue"),
                    expectedDiff.storageSpecs[i].previousValue,
                    actualDiff.storageSpecs[i].previousValue
                );
            }
        }
    }
}
