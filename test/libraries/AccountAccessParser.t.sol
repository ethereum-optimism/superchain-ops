// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Forge
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {console} from "forge-std/console.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";

// Libraries
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";

contract A {
    uint256 public x;

    function setX(uint256 _x) public {
        x = _x;
    }
}

contract B {
    C public c;
    D public d;

    uint256 b;

    function initB() external {
        c = new C();
        d = new D();
    }

    function write() external {
        c.incrementC();
        d.incrementD();
        b++;
    }
}

contract C {
    uint256 public c;

    function incrementC() external {
        c++;
    }
}

contract D {
    uint256 public d;

    function incrementD() external {
        d++;
    }
}

/// @notice Library to expose the internal functions, to avoid tests stopping after hitting an expected revert.
/// https://book.getfoundry.sh/cheatcodes/expect-revert
library AccountAccessParserHarness {
    function decodeAndPrint(VmSafe.AccountAccess[] memory _accountAccesses) external view {
        return AccountAccessParser.decodeAndPrint(_accountAccesses);
    }
}

contract AccountAccessParser_decodeAndPrint_Test is Test {
    using AccountAccessParser for VmSafe.AccountAccess[];

    bool constant isWrite = true;
    bool constant reverted = true;

    bytes32 constant slot0 = bytes32(0);

    bytes32 constant val0 = bytes32(uint256(0));
    bytes32 constant val1 = bytes32(uint256(1));
    bytes32 constant val2 = bytes32(uint256(2));
    bytes32 constant val3 = bytes32(uint256(3));

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

    function testReproduceBug() public {
        A a = new A();
        Proxy proxy = new Proxy(payable(msg.sender));
        vm.prank(msg.sender);
        proxy.upgradeTo(address(a));

        // Start state diff recording
        vm.startStateDiffRecording();
        A(address(proxy)).setX(10);
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();
        // Stop state diff recording

        // Get decoded transfers and state diffs
        AccountAccessParserHarness.decodeAndPrint(accountAccesses);
    }

    function contains(address[] memory addrs, address target) private pure returns (bool) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addrs[i] == target) return true;
        }
        return false;
    }

    function test_multi_writes_single_call() public {
        B b = new B();
        b.initB();

        vm.label(address(b), "Contract B");
        vm.label(address(b.c()), "Contract C");
        vm.label(address(b.d()), "Contract D");
        vm.label(address(this), "This Contract");

        // Start state diff recording
        vm.startStateDiffRecording();
        b.write();
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();

        // Get decoded transfers and state diffs
        AccountAccessParserHarness.decodeAndPrint(accountAccesses);

        address[] memory accesses = accountAccesses.getUniqueWrites();
        assertEq(accesses.length, 3, "should only write to 3 unique accounts");
        assertTrue(contains(accesses, address(b)), "should write to b");
        assertTrue(contains(accesses, address(b.c())), "should write to c");
        assertTrue(contains(accesses, address(b.d())), "should write to d");
    }

    function test_getUniqueWrites_succeeds() public pure {
        // Test basic case - single account with single changed write
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr0, slot0, isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr0, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites();
            assertEq(uniqueAccounts.length, 1, "10");
            assertEq(uniqueAccounts[0], addr0, "20");
        }

        // Test multiple writes to same account - should only appear once
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
            storageAccesses[0] = storageAccess(addr1, slot0, isWrite, val0, val1);
            storageAccesses[1] = storageAccess(addr1, val1, isWrite, val0, val2);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites();
            assertEq(uniqueAccounts.length, 1, "30");
            assertEq(uniqueAccounts[0], addr1, "40");
        }

        // Test writes with no changes - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr2, slot0, isWrite, val1, val1); // Same value
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr2, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites();
            assertEq(uniqueAccounts.length, 0, "50");
        }

        // Test reads - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr3, slot0, !isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr3, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites();
            assertEq(uniqueAccounts.length, 0, "60");
        }

        // Test reverted writes - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr3, slot0, isWrite, val0, val1);
            storageAccesses[0].reverted = reverted;
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr3, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites();
            assertEq(uniqueAccounts.length, 0, "70");
        }

        // Test multiple accounts with mixed read/writes/reverts
        {
            VmSafe.StorageAccess[] memory storageAccesses1 = new VmSafe.StorageAccess[](3);
            storageAccesses1[0] = storageAccess(addr4, slot0, isWrite, val0, val1); // Changed write
            storageAccesses1[1] = storageAccess(addr4, val1, !isWrite, val0, val1); // Read
            storageAccesses1[2] = storageAccess(addr4, val2, isWrite, val0, val2); // Reverted write
            storageAccesses1[2].reverted = reverted;

            VmSafe.StorageAccess[] memory storageAccesses2 = new VmSafe.StorageAccess[](2);
            storageAccesses2[0] = storageAccess(addr5, slot0, isWrite, val1, val1); // Unchanged write
            storageAccesses2[1] = storageAccess(addr5, val1, isWrite, val0, val2); // Changed write

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(addr4, storageAccesses1);
            accesses[1] = accountAccess(addr5, storageAccesses2);

            address[] memory uniqueAccounts = accesses.getUniqueWrites();
            assertEq(uniqueAccounts.length, 2, "80");
            assertEq(uniqueAccounts[0], addr4, "90");
            assertEq(uniqueAccounts[1], addr5, "100");
        }

        // Test empty storage accesses
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](0);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr6, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites();
            assertEq(uniqueAccounts.length, 0, "110");
        }
        // Test correct unique account is returned when account access account didn't have a storage write directly
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr2, slot0, isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites();
            assertEq(uniqueAccounts.length, 1, "120");
            // When this is working, the following will be true:
            assertEq(uniqueAccounts[0], addr2, "130");
        }
    }

    function test_getStateDiffFor_succeeds() public pure {
        // Test single account with single changed write
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr1, slot0, isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr1);
            assertEq(diffs.length, 1, "10");
            assertEq(diffs[0].slot, slot0, "20");
            assertEq(diffs[0].oldValue, val0, "30");
            assertEq(diffs[0].newValue, val1, "40");
        }

        // Test single account with multiple writes to same slot (should only keep last write)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
            storageAccesses[0] = storageAccess(addr2, slot0, isWrite, val0, val1);
            storageAccesses[1] = storageAccess(addr2, slot0, isWrite, val1, val2);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr2, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr2);
            assertEq(diffs.length, 1, "50");
            assertEq(diffs[0].slot, slot0, "60");
            assertEq(diffs[0].oldValue, val0, "70");
            assertEq(diffs[0].newValue, val2, "80");
        }

        // Test single account with unchanged write (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr3, slot0, isWrite, val1, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr3, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr3);
            assertEq(diffs.length, 0, "90");
        }

        // Test single account with reads (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr4, slot0, !isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr4, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr4);
            assertEq(diffs.length, 0, "100");
        }

        // Test single account with reverted write (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr4, slot0, isWrite, val0, val1);
            storageAccesses[0].reverted = reverted;
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr4, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr4);
            assertEq(diffs.length, 0, "110");
        }

        // Test multiple accounts but only requesting one
        {
            VmSafe.StorageAccess[] memory storageAccesses1 = new VmSafe.StorageAccess[](1);
            storageAccesses1[0] = storageAccess(addr5, slot0, isWrite, val0, val1);
            VmSafe.StorageAccess[] memory storageAccesses2 = new VmSafe.StorageAccess[](1);
            storageAccesses2[0] = storageAccess(addr6, slot0, isWrite, val0, val2);

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(addr5, storageAccesses1);
            accesses[1] = accountAccess(addr6, storageAccesses2);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr5);
            assertEq(diffs.length, 1, "120");
            assertEq(diffs[0].slot, slot0, "130");
            assertEq(diffs[0].oldValue, val0, "140");
            assertEq(diffs[0].newValue, val1, "150");
        }

        // Test requesting non-existent account
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr7, slot0, isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr7, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr8);
            assertEq(diffs.length, 0, "160");
        }

        // Test empty storage accesses
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](0);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr9, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr9);
            assertEq(diffs.length, 0, "170");
        }

        // Test empty accesses array
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](0);
            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr10);
            assertEq(diffs.length, 0, "180");
        }
    }

    function test_getETHTransfer_succeeds() public pure {
        // Test successful ETH transfer
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.value = 100;
            access.accessor = addr2;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getETHTransfer(access);
            assertEq(transfer.from, addr2, "10");
            assertEq(transfer.to, addr1, "20");
            assertEq(transfer.value, 100, "30");
            assertEq(transfer.tokenAddress, AccountAccessParser.ETHER, "40");
        }

        // Test reverted ETH transfer (should return zero values)
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.value = 100;
            access.accessor = addr2;
            access.reverted = reverted;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getETHTransfer(access);
            assertEq(transfer.from, addr0, "50");
            assertEq(transfer.to, addr0, "60");
            assertEq(transfer.value, 0, "70");
            assertEq(transfer.tokenAddress, addr0, "80");
        }

        // Test zero value transfer
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.value = 0;
            access.accessor = addr2;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getETHTransfer(access);
            assertEq(transfer.from, addr0, "90");
            assertEq(transfer.to, addr0, "100");
            assertEq(transfer.value, 0, "110");
            assertEq(transfer.tokenAddress, addr0, "120");
        }

        // Test transfer with max uint256 value
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.value = type(uint256).max;
            access.accessor = addr2;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getETHTransfer(access);
            assertEq(transfer.from, addr2, "130");
            assertEq(transfer.to, addr1, "140");
            assertEq(transfer.value, type(uint256).max, "150");
            assertEq(transfer.tokenAddress, AccountAccessParser.ETHER, "160");
        }

        // Test transfer with zero addresses
        {
            VmSafe.AccountAccess memory access = accountAccess(addr0, new VmSafe.StorageAccess[](0));
            access.value = 100;
            access.accessor = addr0;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getETHTransfer(access);
            assertEq(transfer.from, addr0, "170");
            assertEq(transfer.to, addr0, "180");
            assertEq(transfer.value, 100, "190");
            assertEq(transfer.tokenAddress, AccountAccessParser.ETHER, "200");
        }
    }

    function test_getERC20Transfer_succeeds() public pure {
        // Test ERC20 transfer
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 100);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr2, "10");
            assertEq(transfer.to, addr3, "20");
            assertEq(transfer.value, 100, "30");
            assertEq(transfer.tokenAddress, addr1, "40");
        }

        // Test reverted ERC20 transfer (should return zero values)
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 100);
            access.reverted = reverted;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr0, "50");
            assertEq(transfer.to, addr0, "60");
            assertEq(transfer.value, 0, "70");
            assertEq(transfer.tokenAddress, addr0, "80");
        }

        // Test ERC20 transferFrom
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(IERC20.transferFrom.selector, addr3, addr4, 100);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr3, "90");
            assertEq(transfer.to, addr4, "100");
            assertEq(transfer.value, 100, "110");
            assertEq(transfer.tokenAddress, addr1, "120");
        }

        // Test reverted ERC20 transferFrom (should return zero values)
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(IERC20.transferFrom.selector, addr3, addr4, 100);
            access.reverted = reverted;

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr0, "130");
            assertEq(transfer.to, addr0, "140");
            assertEq(transfer.value, 0, "150");
            assertEq(transfer.tokenAddress, addr0, "160");
        }

        // Test invalid selector (should return zero values)
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(bytes4(keccak256("invalidFunction()")), addr3, 100);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr0, "170");
            assertEq(transfer.to, addr0, "180");
            assertEq(transfer.value, 0, "190");
            assertEq(transfer.tokenAddress, addr0, "200");
        }

        // Test empty data (should return zero values)
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = new bytes(0);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr0, "210");
            assertEq(transfer.to, addr0, "220");
            assertEq(transfer.value, 0, "230");
            assertEq(transfer.tokenAddress, addr0, "240");
        }

        // Test max uint256 value transfer
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.accessor = addr2;
            access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, type(uint256).max);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr2, "250");
            assertEq(transfer.to, addr3, "260");
            assertEq(transfer.value, type(uint256).max, "270");
            assertEq(transfer.tokenAddress, addr1, "280");
        }

        // Test with zero addresses
        {
            VmSafe.AccountAccess memory access = accountAccess(addr0, new VmSafe.StorageAccess[](0));
            access.accessor = addr0;
            access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr0, 100);

            AccountAccessParser.DecodedTransfer memory transfer = AccountAccessParser.getERC20Transfer(access);
            assertEq(transfer.from, addr0, "290");
            assertEq(transfer.to, addr0, "300");
            assertEq(transfer.value, 100, "310");
            assertEq(transfer.tokenAddress, addr0, "320");
        }
    }

    function test_decode_succeeds() public view {
        // Test empty array
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](0);
            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode();

            assertEq(transfers.length, 0, "10");
            assertEq(diffs.length, 0, "20");
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
            ) = accesses.decode();

            assertEq(transfers.length, 1, "30");
            assertEq(transfers[0].from, addr2, "40");
            assertEq(transfers[0].to, addr1, "50");
            assertEq(transfers[0].value, 100, "60");
            assertEq(transfers[0].tokenAddress, AccountAccessParser.ETHER, "70");
            assertEq(diffs.length, 0, "80");
        }

        // Test reverted ETH transfer (should be excluded)
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            accesses[0].accessor = addr2;
            accesses[0].value = 100;
            accesses[0].reverted = reverted;

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode();

            assertEq(transfers.length, 0, "90");
            assertEq(diffs.length, 0, "100");
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
            ) = accesses.decode();

            assertEq(transfers.length, 1, "110");
            assertEq(transfers[0].from, addr2, "120");
            assertEq(transfers[0].to, addr3, "130");
            assertEq(transfers[0].value, 100, "140");
            assertEq(transfers[0].tokenAddress, addr1, "150");
            assertEq(diffs.length, 0, "160");
        }

        // Test reverted ERC20 transfer (should be excluded)
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            accesses[0].accessor = addr2;
            accesses[0].data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 100);
            accesses[0].reverted = reverted;

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode();

            assertEq(transfers.length, 0, "170");
            assertEq(diffs.length, 0, "180");
        }

        // Test state diffs only
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr1, AccountAccessParser.GUARDIAN_SLOT, isWrite, val0, val2);

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode();

            assertEq(transfers.length, 0, "190");
            assertEq(diffs.length, 1, "200");
            assertEq(diffs[0].who, addr1, "210");
            assertEq(diffs[0].raw.slot, AccountAccessParser.GUARDIAN_SLOT, "220");
            assertEq(diffs[0].raw.oldValue, val0, "230");
            assertEq(diffs[0].raw.newValue, val2, "240");
        }

        // Test reverted state diffs (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr1, AccountAccessParser.GUARDIAN_SLOT, isWrite, val0, val2);
            storageAccesses[0].reverted = reverted;

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode();

            assertEq(transfers.length, 0, "250");
            assertEq(diffs.length, 0, "260");
        }

        // Test combination of transfers and state diffs
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, isWrite, val0, val1);

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(addr1, storageAccesses);
            accesses[0].value = 100; // ETH transfer
            accesses[1] = accountAccess(addr2, new VmSafe.StorageAccess[](0));
            accesses[1].data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 200); // ERC20 transfer

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode();

            assertEq(transfers.length, 2, "270");
            assertEq(diffs.length, 1, "280");

            // Check ETH transfer
            assertEq(transfers[0].value, 100, "290");
            assertEq(transfers[0].tokenAddress, AccountAccessParser.ETHER, "300");

            // Check ERC20 transfer
            assertEq(transfers[1].from, addr0, "310");
            assertEq(transfers[1].to, addr3, "320");
            assertEq(transfers[1].value, 200, "330");
            assertEq(transfers[1].tokenAddress, addr2, "340");

            // Check state diff
            assertEq(diffs[0].who, addr1, "350");
            assertEq(diffs[0].raw.slot, AccountAccessParser.PAUSED_SLOT, "360");
            assertEq(diffs[0].raw.oldValue, val0, "370");
            assertEq(diffs[0].raw.newValue, val1, "380");
        }

        // Test combination of reverted and non-reverted operations
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
            storageAccesses[0] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, isWrite, val0, val1);
            storageAccesses[1] = storageAccess(addr1, AccountAccessParser.GUARDIAN_SLOT, isWrite, val0, val2);
            storageAccesses[1].reverted = reverted;

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(addr1, storageAccesses);
            accesses[0].value = 100; // ETH transfer
            accesses[1] = accountAccess(addr2, new VmSafe.StorageAccess[](0));
            accesses[1].data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 200); // ERC20 transfer
            accesses[1].reverted = reverted;

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode();

            assertEq(transfers.length, 1, "390");
            assertEq(transfers[0].value, 100, "400");
            assertEq(transfers[0].tokenAddress, AccountAccessParser.ETHER, "410");
            assertEq(diffs.length, 1, "420");
            assertEq(diffs[0].raw.oldValue, val0, "430");
            assertEq(diffs[0].raw.newValue, val1, "440");
        }

        // Test state changes that revert back to original (should not appear in diffs)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
            storageAccesses[0] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, isWrite, val0, val1);
            storageAccesses[1] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, isWrite, val1, val0);

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode();

            assertEq(transfers.length, 0, "450");
            assertEq(diffs.length, 0, "460");
        }

        // Test multiple accounts with state changes
        {
            VmSafe.StorageAccess[] memory storageAccesses1 = new VmSafe.StorageAccess[](1);
            storageAccesses1[0] = storageAccess(addr1, AccountAccessParser.PAUSED_SLOT, isWrite, val0, val1);

            VmSafe.StorageAccess[] memory storageAccesses2 = new VmSafe.StorageAccess[](1);
            storageAccesses2[0] = storageAccess(addr2, AccountAccessParser.GUARDIAN_SLOT, isWrite, val0, val3);

            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](2);
            accesses[0] = accountAccess(addr1, storageAccesses1);
            accesses[1] = accountAccess(addr2, storageAccesses2);

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode();

            assertEq(transfers.length, 0, "470");
            assertEq(diffs.length, 2, "480");
            assertEq(diffs[0].who, addr1, "490");
            assertEq(diffs[0].raw.slot, AccountAccessParser.PAUSED_SLOT, "500");
            assertEq(diffs[0].raw.oldValue, val0, "510");
            assertEq(diffs[0].raw.newValue, val1, "520");
            assertEq(diffs[1].who, addr2, "530");
            assertEq(diffs[1].raw.slot, AccountAccessParser.GUARDIAN_SLOT, "540");
            assertEq(diffs[1].raw.oldValue, val0, "550");
            assertEq(diffs[1].raw.newValue, val3, "560");
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
