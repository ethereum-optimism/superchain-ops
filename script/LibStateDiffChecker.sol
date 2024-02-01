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

    // add the address here and everything gets much simpler
    struct StorageAccessSpec {
        bytes32 newValue;
        bytes32 slot;
    }

    struct AccountAccessSpec {
        address account;
        bytes data;
        StorageAccessSpec[] storageAccesses;
    }

    error StateDiffMismatch(string field, bytes32 expected, bytes32 actual);

    function length(string memory _jsonArray) internal pure returns (uint256) {
        uint256 MAX_LENGTH_SUPPORTED = 999;
        uint256 entries = MAX_LENGTH_SUPPORTED;
        for (uint256 i = 0; entries == MAX_LENGTH_SUPPORTED; i++) {
            require(
                i < MAX_LENGTH_SUPPORTED,
                "Transaction list longer than MAX_LENGTH_SUPPORTED is not "
                "supported, to support it, simply bump the value of " "MAX_LENGTH_SUPPORTED to a bigger one."
            );
            try vm.parseJsonAddress(_jsonArray, string.concat("$.[", vm.toString(i), "].account")) returns (address) {}
            catch {
                entries = i;
            }
        }

        return entries;
    }

    /// @notice Parses the JSON data to extract account access specifications.
    /// @param _jsonData     The JSON string containing the account access specifications.
    /// @return accountSpecs_ An array of AccountAccessSpec structs parsed from the JSON data.
    function parseDiffSpecs(string memory _jsonData) internal pure returns (AccountAccessSpec[] memory accountSpecs_) {
        uint256 numAccountAccesses = length(_jsonData);
        AccountAccessSpec[] memory accountSpecs = new AccountAccessSpec[](numAccountAccesses);

        for (uint256 i = 0; i < numAccountAccesses; i++) {
            string memory key = string.concat("$.[", vm.toString(i), "].account");
            accountSpecs[i].account = stdJson.readAddress(_jsonData, key);

            bytes memory storageAccessesJson =
                stdJson.parseRaw(_jsonData, string.concat("$.[", vm.toString(i), "].storageAccesses"));
            StorageAccessSpec[] memory storageSpecs = abi.decode(storageAccessesJson, (StorageAccessSpec[]));
            accountSpecs[i].storageAccesses = storageSpecs;
        }

        accountSpecs_ = accountSpecs;
    }

    /// @notice Filters account accesses to return only those that modified storage.
    /// @param accesses An array of account accesses recorded by the EVM.
    /// @return modifyingAccesses An array of account accesses that modified storage.
    function filterStorageModifyingAccesses(VmSafe.AccountAccess[] memory accesses)
        internal
        pure
        returns (VmSafe.AccountAccess[] memory modifyingAccesses)
    {
        uint256 modifiedCount = 0;
        for (uint256 i = 0; i < accesses.length; i++) {
            if (accesses[i].storageAccesses.length > 0) {
                bool hasModifications = false;
                for (uint256 j = 0; j < accesses[i].storageAccesses.length; j++) {
                    if (accesses[i].storageAccesses[j].isWrite) {
                        accesses[i].storageAccesses[j].previousValue != accesses[i].storageAccesses[j].newValue;
                        hasModifications = true;
                        break;
                    }
                }
                if (hasModifications) {
                    modifiedCount++;
                }
            }
        }

        modifyingAccesses = new VmSafe.AccountAccess[](modifiedCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < accesses.length; i++) {
            if (accesses[i].storageAccesses.length > 0) {
                bool hasModifications = false;
                for (uint256 j = 0; j < accesses[i].storageAccesses.length; j++) {
                    if (accesses[i].storageAccesses[j].isWrite) {
                        hasModifications = true;
                        break;
                    }
                }
                if (hasModifications) {
                    modifyingAccesses[counter] = accesses[i];
                    counter++;
                }
            }
        }
    }

    /// @notice Compares expected account accesses with actual account accesses to ensure they match.
    /// @param  expectedAccesses An array of expected account accesses.
    /// @param  actualAccesses An array of actual account accesses recorded by the EVM.
    function checkStateDiffs(AccountAccessSpec[] memory expectedAccesses, VmSafe.AccountAccess[] memory actualAccesses)
        internal
        view
    {
        if (expectedAccesses.length != actualAccesses.length) {
            revert StateDiffMismatch("length", bytes32(expectedAccesses.length), bytes32(actualAccesses.length));
        }
        for (uint256 i = 0; i < expectedAccesses.length; i++) {
            AccountAccessSpec memory expectedAccess = expectedAccesses[i];
            VmSafe.AccountAccess memory actualAccess = actualAccesses[i];
            checkStateDiff(expectedAccess, actualAccess);
        }
    }

    /// @notice Checks if a single expected account access matches the actual account access.
    /// @param expectedAccess The expected account access details.
    /// @param actualAccess   The actual account access details recorded by the EVM.
    function checkStateDiff(AccountAccessSpec memory expectedAccess, VmSafe.AccountAccess memory actualAccess)
        internal
        view
    {
        if (expectedAccess.storageAccesses.length != actualAccess.storageAccesses.length) {
            revert StateDiffMismatch(
                "length", bytes32(expectedAccess.storageAccesses.length), bytes32(actualAccess.storageAccesses.length)
            );
        }
        require(expectedAccess.account == actualAccess.account, "StateDiffChecker: account mismatch");

        for (uint256 i = 0; i < expectedAccess.storageAccesses.length; i++) {
            StorageAccessSpec memory expectedStorageAccess = expectedAccess.storageAccesses[i];
            VmSafe.StorageAccess memory actualStorageAccess = actualAccess.storageAccesses[i];
            if (expectedStorageAccess.slot != actualStorageAccess.slot) {
                revert StateDiffMismatch("slot", bytes32(expectedStorageAccess.slot), bytes32(actualStorageAccess.slot));
            }
            if (expectedStorageAccess.newValue != actualStorageAccess.newValue) {
                revert StateDiffMismatch(
                    "newValue", bytes32(expectedStorageAccess.slot), bytes32(actualStorageAccess.slot)
                );
            }
        }
    }
}

// struct AccountAccess {
//   ChainInfo chainInfo;
//   AccountAccessKind kind;
//   address account;
//   address accessor;
//   bool initialized;
//   uint256 oldBalance;
//   uint256 newBalance;
//   bytes deployedCode;
//   uint256 value;
//   bytes data;
//   bool reverted;
//   StorageAccess[] storageAccesses;
// }

//     struct StorageAccess {
//       address account;
//       bytes32 slot;
//       bool isWrite;
//       bytes32 previousValue;
//       bytes32 newValue;
//       bool reverted;
//   }
