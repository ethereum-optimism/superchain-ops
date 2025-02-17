// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Forge
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "lib/forge-std/src/Vm.sol";

// Libraries
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";

contract AccountAccessParser_decodeAndPrint_Test is Test {
    bytes32 one = bytes32(uint256(1));
    bytes32 two = bytes32(uint256(2));

    function test_getUniqueWrites_succeeds() public view {
        // Test basic case - single account with single changed write
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(address(0), bytes32(0), true, bytes32(0), one);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(0), storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 1);
            assertEq(uniqueAccounts[0], address(0));
        }

        // Test multiple writes to same account - should only appear once
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
            storageAccesses[0] = storageAccess(address(1), bytes32(0), true, bytes32(0), one);
            storageAccesses[1] = storageAccess(address(1), one, true, bytes32(0), two);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(1), storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 1);
            assertEq(uniqueAccounts[0], address(1));
        }

        // Test writes with no changes - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(address(2), bytes32(0), true, one, one); // Same value
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(2), storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 0);
        }

        // Test reads - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(address(3), bytes32(0), false, bytes32(0), one); // isWrite = false
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(3), storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 0);
        }

        // Test multiple accounts with mixed read/writes
        {
            VmSafe.StorageAccess[] memory storageAccesses1 = new VmSafe.StorageAccess[](2);
            storageAccesses1[0] = storageAccess(address(4), bytes32(0), true, bytes32(0), one); // Changed write
            storageAccesses1[1] = storageAccess(address(4), one, false, bytes32(0), one); // Read

            VmSafe.StorageAccess[] memory storageAccesses2 = new VmSafe.StorageAccess[](2);
            storageAccesses2[0] = storageAccess(address(5), bytes32(0), true, one, one); // Unchanged write
            storageAccesses2[1] = storageAccess(address(5), one, true, bytes32(0), two); // Changed write

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(address(4), storageAccesses1);
            accesses[1] = accountAccess(address(5), storageAccesses2);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 2);
            assertEq(uniqueAccounts[0], address(4));
            assertEq(uniqueAccounts[1], address(5));
        }

        // Test empty storage accesses
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](0);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(6), storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 0);
        }
    }

    function test_getStateDiffFor_succeeds() public view {
        // Test single account with single changed write
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(address(1), bytes32(0), true, bytes32(0), one);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(1), storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, address(1));
            assertEq(diffs.length, 1);
            assertEq(diffs[0].slot, bytes32(0));
            assertEq(diffs[0].oldValue, bytes32(0));
            assertEq(diffs[0].newValue, one);
        }

        // Test single account with multiple writes to same slot (should only keep last write)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
            storageAccesses[0] = storageAccess(address(2), bytes32(0), true, bytes32(0), one);
            storageAccesses[1] = storageAccess(address(2), bytes32(0), true, one, two);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(2), storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, address(2));
            assertEq(diffs.length, 1);
            assertEq(diffs[0].slot, bytes32(0));
            assertEq(diffs[0].oldValue, bytes32(0));
            assertEq(diffs[0].newValue, two);
        }

        // Test single account with unchanged write (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(address(3), bytes32(0), true, one, one);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(3), storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, address(3));
            assertEq(diffs.length, 0);
        }

        // Test single account with reads (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(address(4), bytes32(0), false, bytes32(0), one);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(4), storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, address(4));
            assertEq(diffs.length, 0);
        }

        // Test multiple accounts but only requesting one
        {
            VmSafe.StorageAccess[] memory storageAccesses1 = new VmSafe.StorageAccess[](1);
            storageAccesses1[0] = storageAccess(address(5), bytes32(0), true, bytes32(0), one);
            VmSafe.StorageAccess[] memory storageAccesses2 = new VmSafe.StorageAccess[](1);
            storageAccesses2[0] = storageAccess(address(6), bytes32(0), true, bytes32(0), two);

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(address(5), storageAccesses1);
            accesses[1] = accountAccess(address(6), storageAccesses2);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, address(5));
            assertEq(diffs.length, 1);
            assertEq(diffs[0].slot, bytes32(0));
            assertEq(diffs[0].oldValue, bytes32(0));
            assertEq(diffs[0].newValue, one);
        }

        // Test requesting non-existent account
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(address(7), bytes32(0), true, bytes32(0), one);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(7), storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, address(8));
            assertEq(diffs.length, 0);
        }

        // Test empty storage accesses
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](0);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(address(9), storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, address(9));
            assertEq(diffs.length, 0);
        }

        // Test empty accesses array
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](0);
            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, address(10));
            assertEq(diffs.length, 0);
        }
    }

    function accountAccess(address _account, VmSafe.StorageAccess[] memory _storageAccesses)
        internal
        pure
        returns (VmSafe.AccountAccess memory)
    {
        return VmSafe.AccountAccess({
            chainInfo: VmSafe.ChainInfo({chainId: 1, forkId: 1}),
            kind: VmSafe.AccountAccessKind.Call,
            account: _account,
            accessor: address(0),
            initialized: true,
            oldBalance: 0,
            newBalance: 0,
            deployedCode: new bytes(0),
            value: 0,
            data: new bytes(0),
            reverted: false,
            storageAccesses: _storageAccesses,
            depth: 0
        });
    }

    function storageAccess(address _account, bytes32 _slot, bool _isWrite, bytes32 _previousValue, bytes32 _newValue)
        internal
        pure
        returns (VmSafe.StorageAccess memory)
    {
        return VmSafe.StorageAccess({
            account: _account,
            slot: _slot,
            isWrite: _isWrite,
            previousValue: _previousValue,
            newValue: _newValue,
            reverted: false
        });
    }
}
