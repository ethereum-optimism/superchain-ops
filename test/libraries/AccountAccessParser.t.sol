// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Forge
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// Libraries
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";

contract AccountAccessParser_decodeAndPrint_Test is Test {
    bytes32 constant slot0 = bytes32(0);

    bytes32 constant byte1 = bytes32(uint256(1));
    bytes32 constant byte2 = bytes32(uint256(2));

    address constant addr0 = address(0);
    address constant addr1 = address(1);
    address constant addr2 = address(2);
    address constant addr3 = address(3);
    address constant addr4 = address(4);
    address constant addr5 = address(5);
    address constant addr6 = address(6);
    address constant addr7 = address(7);
    address constant addr8 = address(8);
    address constant addr9 = address(9);
    address constant addr10 = address(10);

    function test_getUniqueWrites_succeeds() public pure {
        // Test basic case - single account with single changed write
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr0, slot0, true, slot0, byte1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr0, storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 1);
            assertEq(uniqueAccounts[0], addr0);
        }

        // Test multiple writes to same account - should only appear once
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
            storageAccesses[0] = storageAccess(addr1, slot0, true, slot0, byte1);
            storageAccesses[1] = storageAccess(addr1, byte1, true, slot0, byte2);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 1);
            assertEq(uniqueAccounts[0], addr1);
        }

        // Test writes with no changes - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr2, slot0, true, byte1, byte1); // Same value
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr2, storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 0);
        }

        // Test reads - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr3, slot0, false, slot0, byte1); // isWrite = false
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr3, storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 0);
        }

        // Test multiple accounts with mixed read/writes
        {
            VmSafe.StorageAccess[] memory storageAccesses1 = new VmSafe.StorageAccess[](2);
            storageAccesses1[0] = storageAccess(addr4, slot0, true, slot0, byte1); // Changed write
            storageAccesses1[1] = storageAccess(addr4, byte1, false, slot0, byte1); // Read

            VmSafe.StorageAccess[] memory storageAccesses2 = new VmSafe.StorageAccess[](2);
            storageAccesses2[0] = storageAccess(addr5, slot0, true, byte1, byte1); // Unchanged write
            storageAccesses2[1] = storageAccess(addr5, byte1, true, slot0, byte2); // Changed write

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(addr4, storageAccesses1);
            accesses[1] = accountAccess(addr5, storageAccesses2);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 2);
            assertEq(uniqueAccounts[0], addr4);
            assertEq(uniqueAccounts[1], addr5);
        }

        // Test empty storage accesses
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](0);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr6, storageAccesses);

            address[] memory uniqueAccounts = AccountAccessParser.getUniqueWrites(accesses);
            assertEq(uniqueAccounts.length, 0);
        }
    }

    function test_getStateDiffFor_succeeds() public pure {
        // Test single account with single changed write
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr1, slot0, true, slot0, byte1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, addr1);
            assertEq(diffs.length, 1);
            assertEq(diffs[0].slot, slot0);
            assertEq(diffs[0].oldValue, slot0);
            assertEq(diffs[0].newValue, byte1);
        }

        // Test single account with multiple writes to same slot (should only keep last write)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
            storageAccesses[0] = storageAccess(addr2, slot0, true, slot0, byte1);
            storageAccesses[1] = storageAccess(addr2, slot0, true, byte1, byte2);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr2, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, addr2);
            assertEq(diffs.length, 1);
            assertEq(diffs[0].slot, slot0);
            assertEq(diffs[0].oldValue, slot0);
            assertEq(diffs[0].newValue, byte2);
        }

        // Test single account with unchanged write (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr3, slot0, true, byte1, byte1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr3, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, addr3);
            assertEq(diffs.length, 0);
        }

        // Test single account with reads (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr4, slot0, false, slot0, byte1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr4, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, addr4);
            assertEq(diffs.length, 0);
        }

        // Test multiple accounts but only requesting one
        {
            VmSafe.StorageAccess[] memory storageAccesses1 = new VmSafe.StorageAccess[](1);
            storageAccesses1[0] = storageAccess(addr5, slot0, true, slot0, byte1);
            VmSafe.StorageAccess[] memory storageAccesses2 = new VmSafe.StorageAccess[](1);
            storageAccesses2[0] = storageAccess(addr6, slot0, true, slot0, byte2);

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(addr5, storageAccesses1);
            accesses[1] = accountAccess(addr6, storageAccesses2);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, addr5);
            assertEq(diffs.length, 1);
            assertEq(diffs[0].slot, slot0);
            assertEq(diffs[0].oldValue, slot0);
            assertEq(diffs[0].newValue, byte1);
        }

        // Test requesting non-existent account
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr7, slot0, true, slot0, byte1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr7, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, addr8);
            assertEq(diffs.length, 0);
        }

        // Test empty storage accesses
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](0);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr9, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, addr9);
            assertEq(diffs.length, 0);
        }

        // Test empty accesses array
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](0);
            AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, addr10);
            assertEq(diffs.length, 0);
        }
    }

    function test_getETHTransfer_succeeds() public pure {
        // Test successful ETH transfer
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.value = 100;
            access.accessor = addr2;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getETHTransfer(access);
            assertEq(transfer.from, addr2);
            assertEq(transfer.to, addr1);
            assertEq(transfer.value, 100);
            assertEq(transfer.tokenAddress, AccountAccessParser.ETH_TOKEN);
        }

        // Test zero value transfer
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.value = 0;
            access.accessor = addr2;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getETHTransfer(access);
            assertEq(transfer.from, addr0);
            assertEq(transfer.to, addr0);
            assertEq(transfer.value, 0);
            assertEq(transfer.tokenAddress, addr0);
        }

        // Test transfer with max uint256 value
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.value = type(uint256).max;
            access.accessor = addr2;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getETHTransfer(access);
            assertEq(transfer.from, addr2);
            assertEq(transfer.to, addr1);
            assertEq(transfer.value, type(uint256).max);
            assertEq(transfer.tokenAddress, AccountAccessParser.ETH_TOKEN);
        }

        // Test transfer with zero addresses
        {
            VmSafe.AccountAccess memory access = accountAccess(addr0, new VmSafe.StorageAccess[](0));
            access.value = 100;
            access.accessor = addr0;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getETHTransfer(access);
            assertEq(transfer.from, addr0);
            assertEq(transfer.to, addr0);
            assertEq(transfer.value, 100);
            assertEq(transfer.tokenAddress, AccountAccessParser.ETH_TOKEN);
        }
    }

    function test_getERC20Transfer_succeeds() public pure {
        // Test ERC20 transfer
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 100);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr2);
            assertEq(transfer.to, addr3);
            assertEq(transfer.value, 100);
            assertEq(transfer.tokenAddress, addr1);
        }

        // Test ERC20 transferFrom
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(IERC20.transferFrom.selector, addr3, addr4, 100);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr3);
            assertEq(transfer.to, addr4);
            assertEq(transfer.value, 100);
            assertEq(transfer.tokenAddress, addr1);
        }

        // Test invalid selector (should return zero values)
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(bytes4(keccak256("invalidFunction()")), addr3, 100);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr0);
            assertEq(transfer.to, addr0);
            assertEq(transfer.value, 0);
            assertEq(transfer.tokenAddress, addr0);
        }

        // Test empty data (should return zero values)
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = new bytes(0);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr0);
            assertEq(transfer.to, addr0);
            assertEq(transfer.value, 0);
            assertEq(transfer.tokenAddress, addr0);
        }

        // Test max uint256 value transfer
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, type(uint256).max);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr2);
            assertEq(transfer.to, addr3);
            assertEq(transfer.value, type(uint256).max);
            assertEq(transfer.tokenAddress, addr1);
        }

        // Test with zero addresses
        {
            VmSafe.AccountAccess memory access = accountAccess(addr0, new VmSafe.StorageAccess[](0));
            access.accessor = addr0;
            access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr0, 100);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr0);
            assertEq(transfer.to, addr0);
            assertEq(transfer.value, 100);
            assertEq(transfer.tokenAddress, addr0);
        }
    }

    function test_decode_succeeds() public view {
        // Test empty array
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](0);
            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = AccountAccessParser.decode(accesses);

            assertEq(transfers.length, 0);
            assertEq(diffs.length, 0);
        }

        // Test ETH transfer only
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            accesses[0].accessor = addr2;
            accesses[0].value = 100;

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = AccountAccessParser.decode(accesses);

            assertEq(transfers.length, 1);
            assertEq(transfers[0].from, addr2);
            assertEq(transfers[0].to, addr1);
            assertEq(transfers[0].value, 100);
            assertEq(transfers[0].tokenAddress, AccountAccessParser.ETH_TOKEN);
            assertEq(diffs.length, 0);
        }

        // Test ERC20 transfer only
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            accesses[0].accessor = addr2;
            accesses[0].data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 100);

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = AccountAccessParser.decode(accesses);

            assertEq(transfers.length, 1);
            assertEq(transfers[0].from, addr2);
            assertEq(transfers[0].to, addr3);
            assertEq(transfers[0].value, 100);
            assertEq(transfers[0].tokenAddress, addr1);
            assertEq(diffs.length, 0);
        }

        // Test state diffs only
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] =
                storageAccess(addr1, AccountAccessParser.GUARDIAN_SLOT, true, slot0, bytes32(uint256(uint160(addr2))));

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = AccountAccessParser.decode(accesses);

            assertEq(transfers.length, 0);
            assertEq(diffs.length, 1);
            assertEq(diffs[0].who, addr1);
            assertEq(diffs[0].raw.slot, AccountAccessParser.GUARDIAN_SLOT);
            assertEq(diffs[0].raw.oldValue, slot0);
            assertEq(diffs[0].raw.newValue, bytes32(uint256(uint160(addr2))));
        }

        // Test combination of transfers and state diffs
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, true, bytes32(uint256(0)), byte1);

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(addr1, storageAccesses);
            accesses[0].value = 100; // ETH transfer
            accesses[1] = accountAccess(addr2, new VmSafe.StorageAccess[](0));
            accesses[1].data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 200); // ERC20 transfer

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = AccountAccessParser.decode(accesses);

            assertEq(transfers.length, 2);
            assertEq(diffs.length, 1);

            // Check ETH transfer
            assertEq(transfers[0].value, 100);
            assertEq(transfers[0].tokenAddress, AccountAccessParser.ETH_TOKEN);

            // Check ERC20 transfer
            assertEq(transfers[1].from, addr0);
            assertEq(transfers[1].to, addr3);
            assertEq(transfers[1].value, 200);
            assertEq(transfers[1].tokenAddress, addr2);

            // Check state diff
            assertEq(diffs[0].who, addr1);
            assertEq(diffs[0].raw.slot, AccountAccessParser.PAUSED_SLOT);
            assertEq(diffs[0].raw.oldValue, bytes32(uint256(0)));
            assertEq(diffs[0].raw.newValue, byte1);
        }

        // Test multiple state diffs to same slot (should only keep final value)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](3);
            storageAccesses[0] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, true, bytes32(uint256(0)), byte1);
            storageAccesses[1] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, true, byte1, byte2);
            storageAccesses[2] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, true, byte2, bytes32(uint256(3)));

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = AccountAccessParser.decode(accesses);

            assertEq(transfers.length, 0);
            assertEq(diffs.length, 1);
            assertEq(diffs[0].raw.oldValue, bytes32(uint256(0)));
            assertEq(diffs[0].raw.newValue, bytes32(uint256(3)));
        }

        // Test state changes that revert back to original (should not appear in diffs)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
            storageAccesses[0] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, true, bytes32(uint256(0)), byte1);
            storageAccesses[1] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, true, byte1, bytes32(uint256(0)));

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = AccountAccessParser.decode(accesses);

            assertEq(transfers.length, 0);
            assertEq(diffs.length, 0);
        }

        // Test multiple accounts with state changes
        {
            VmSafe.StorageAccess[] memory storageAccesses1 = new VmSafe.StorageAccess[](1);
            storageAccesses1[0] =
                storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, true, bytes32(uint256(0)), byte1);

            VmSafe.StorageAccess[] memory storageAccesses2 = new VmSafe.StorageAccess[](1);
            storageAccesses2[0] = storageAccess(
                addr2, AccountAccessParser.GUARDIAN_SLOT, true, bytes32(uint256(0)), bytes32(uint256(uint160(addr3)))
            );

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(addr1, storageAccesses1);
            accesses[1] = accountAccess(addr2, storageAccesses2);

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = AccountAccessParser.decode(accesses);

            assertEq(transfers.length, 0);
            assertEq(diffs.length, 2);
            assertEq(diffs[0].who, addr1);
            assertEq(diffs[0].raw.slot, AccountAccessParser.PAUSED_SLOT);
            assertEq(diffs[0].raw.oldValue, bytes32(uint256(0)));
            assertEq(diffs[0].raw.newValue, byte1);
            assertEq(diffs[1].who, addr2);
            assertEq(diffs[1].raw.slot, AccountAccessParser.GUARDIAN_SLOT);
            assertEq(diffs[1].raw.oldValue, bytes32(uint256(0)));
            assertEq(diffs[1].raw.newValue, bytes32(uint256(uint160(addr3))));
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
            accessor: addr0,
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
