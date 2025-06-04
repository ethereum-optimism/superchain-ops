// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// Forge
import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IResourceMetering} from "@eth-optimism-bedrock/interfaces/L1/IResourceMetering.sol";

// Solady
import {LibString} from "solady/utils/LibString.sol";

// Libraries
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";

/// This is a simple implementation of a contract used in the "test_commonProxyArchitecture_succeeds" test.
/// DO NOT use in production.
contract Impl {
    uint256 public num;
    address public proxyA;
    address public proxyB;

    function initialize(address _proxyA, address _proxyB) public {
        require(proxyA == address(0), "ProxyA already initialized");
        require(proxyB == address(0), "ProxyB already initialized");
        proxyA = _proxyA;
        proxyB = _proxyB;
    }

    function setNum(uint256 _num) public {
        num = _num;
        if (proxyA != address(0)) {
            Impl(payable(proxyA)).setNum(_num + 1);
        }
        if (proxyB != address(0)) {
            Impl(payable(proxyB)).setNum(_num + 1);
        }
    }
}

/// @notice A simple implementation that can send ETH to another address.
contract Impl2 {
    function sendEther(address to) public payable {
        (bool success,) = payable(to).call{value: msg.value}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}

contract AccountAccessParser_decodeAndPrint_Test is Test {
    using AccountAccessParser for VmSafe.AccountAccess[];
    using AccountAccessParser for VmSafe.AccountAccess;

    bool constant isWrite = true;
    bool constant reverted = true;

    bytes32 constant slot0 = bytes32(0);
    bytes32 constant slot1 = bytes32(uint256(1));

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

    // Proxy1 (1 Storage Write) -> Impl1 -> ProxyA (1 Storage Write) -> Impl2
    //                                   -> ProxyB (1 Storage Write) -> Impl2
    // Delegate calling from a proxy to an implementation is a common pattern in our architecture.
    // In this test, we test a more complex version of this pattern where we have three proxies.
    // Each proxy delegates to an implementation, which then updates state on the calling proxy.
    // Internally, Proxy1 contains two storage writes: one to ProxyA and one to ProxyB.
    function test_commonProxyArchitecture_succeeds() public {
        Proxy proxyA = new Proxy(payable(msg.sender));
        Impl impl2 = new Impl();
        vm.prank(address(0));
        proxyA.upgradeTo(address(impl2));

        Proxy proxyB = new Proxy(payable(msg.sender));
        vm.prank(address(0));
        proxyB.upgradeTo(address(impl2));

        Proxy proxy1 = new Proxy(payable(msg.sender));
        Impl impl1 = new Impl();
        vm.prank(address(0));
        proxy1.upgradeToAndCall(
            address(impl1), abi.encodeWithSelector(Impl.initialize.selector, address(proxyA), address(proxyB))
        );

        // Start state diff recording
        vm.startStateDiffRecording();
        Impl(address(proxy1)).setNum(10);
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();
        // Stop state diff recording

        (, AccountAccessParser.DecodedStateDiff[] memory stateDiffs) = accountAccesses.decode(true);
        _assertStateDiffsAscending(stateDiffs);
        accountAccesses.decodeAndPrint(address(0), bytes32(0));

        AccountAccessParser.StateDiff[] memory firstProxyDiffs = accountAccesses.getStateDiffFor(address(proxy1), false);
        assertEq(firstProxyDiffs.length, 1, "10");
        assertEq(firstProxyDiffs[0].slot, slot0, "20");
        assertEq(firstProxyDiffs[0].oldValue, val0, "30");
        assertEq(firstProxyDiffs[0].newValue, bytes32(uint256(10)), "40");

        AccountAccessParser.StateDiff[] memory secondProxyDiffs =
            accountAccesses.getStateDiffFor(address(proxyA), false);
        assertEq(secondProxyDiffs.length, 1, "50");
        assertEq(secondProxyDiffs[0].slot, slot0, "60");
        assertEq(secondProxyDiffs[0].oldValue, val0, "70");
        assertEq(secondProxyDiffs[0].newValue, bytes32(uint256(11)), "80");

        AccountAccessParser.StateDiff[] memory thirdProxyDiffs = accountAccesses.getStateDiffFor(address(proxyB), false);
        assertEq(thirdProxyDiffs.length, 1, "90");
        assertEq(thirdProxyDiffs[0].slot, slot0, "100");
        assertEq(thirdProxyDiffs[0].oldValue, val0, "110");
        assertEq(thirdProxyDiffs[0].newValue, bytes32(uint256(11)), "120");

        address[] memory uniqueAccounts = accountAccesses.getUniqueWrites(true);
        assertEq(uniqueAccounts.length, 3, "130");
        assertEq(uniqueAccounts[0], address(proxyA), "140");
        assertEq(uniqueAccounts[1], address(proxy1), "150");
        assertEq(uniqueAccounts[2], address(proxyB), "160");
    }

    /// @notice Test that a single ETH transfer is recorded correctly. The Foundry account access that
    /// has an access kind of DelegateCall is not a valid ETH transfer and should be ignored.
    function testSingleEtherTransfer() external {
        Proxy sourceProxy = new Proxy(msg.sender);
        Impl2 sourceImpl = new Impl2();
        vm.prank(msg.sender);
        sourceProxy.upgradeTo(address(sourceImpl));

        Proxy destinationProxy = new Proxy(msg.sender);
        Impl2 destinationImpl = new Impl2();
        vm.prank(msg.sender);
        destinationProxy.upgradeTo(address(destinationImpl));

        vm.startStateDiffRecording();
        Impl2(payable(address(sourceProxy))).sendEther{value: 1 ether}(address(destinationProxy));
        VmSafe.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();

        uint256 balanceChanges = 0;
        for (uint256 i = 0; i < accountAccesses.length; i++) {
            if (accountAccesses[i].containsValueTransfer()) {
                balanceChanges++;
            }
        }
        assertEq(balanceChanges, 1);
    }

    function test_getUniqueWrites_succeeds() public pure {
        // Test basic case - single account with single changed write
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr0, slot0, isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr0, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites(false);
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

            address[] memory uniqueAccounts = accesses.getUniqueWrites(false);
            assertEq(uniqueAccounts.length, 1, "30");
            assertEq(uniqueAccounts[0], addr1, "40");
        }

        // Test writes with no changes - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr2, slot0, isWrite, val1, val1); // Same value
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr2, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites(false);
            assertEq(uniqueAccounts.length, 0, "50");
        }

        // Test reads - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr3, slot0, !isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr3, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites(false);
            assertEq(uniqueAccounts.length, 0, "60");
        }

        // Test reverted writes - should not be included
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr3, slot0, isWrite, val0, val1);
            storageAccesses[0].reverted = reverted;
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr3, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites(false);
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

            address[] memory uniqueAccounts = accesses.getUniqueWrites(false);
            assertEq(uniqueAccounts.length, 2, "80");
            assertEq(uniqueAccounts[0], addr4, "90");
            assertEq(uniqueAccounts[1], addr5, "100");
        }

        // Test empty storage accesses
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](0);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr6, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites(false);
            assertEq(uniqueAccounts.length, 0, "110");
        }
        // Test correct unique account is returned when account access account didn't have a storage write directly
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr2, slot0, isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, storageAccesses);

            address[] memory uniqueAccounts = accesses.getUniqueWrites(false);
            assertEq(uniqueAccounts.length, 1, "120");
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

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr1, false);
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

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr2, false);
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

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr3, false);
            assertEq(diffs.length, 0, "90");
        }

        // Test single account with reads (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr4, slot0, !isWrite, val0, val1);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr4, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr4, false);
            assertEq(diffs.length, 0, "100");
        }

        // Test single account with reverted write (should be excluded)
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
            storageAccesses[0] = storageAccess(addr4, slot0, isWrite, val0, val1);
            storageAccesses[0].reverted = reverted;
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr4, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr4, false);
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

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr5, false);
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

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr8, false);
            assertEq(diffs.length, 0, "160");
        }

        // Test empty storage accesses
        {
            VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](0);
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr9, storageAccesses);

            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr9, false);
            assertEq(diffs.length, 0, "170");
        }

        // Test empty accesses array
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](0);
            AccountAccessParser.StateDiff[] memory diffs = accesses.getStateDiffFor(addr10, false);
            assertEq(diffs.length, 0, "180");
        }
    }

    function test_getETHTransfer_succeeds() public pure {
        // Test successful ETH transfer
        {
            VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            access.value = 100;
            access.accessor = addr2;
            access.oldBalance = 0;
            access.newBalance = 100;

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
            access.oldBalance = 0;
            access.newBalance = type(uint256).max;

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
            access.oldBalance = 0;
            access.newBalance = 100;

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
            ) = accesses.decode(false);

            assertEq(transfers.length, 0, "10");
            assertEq(diffs.length, 0, "20");
        }

        // Test ETH transfer only
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            accesses[0].accessor = addr2;
            accesses[0].value = 100;
            accesses[0].oldBalance = 0;
            accesses[0].newBalance = 100;

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode(false);

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
            ) = accesses.decode(false);

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
            ) = accesses.decode(false);

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
            ) = accesses.decode(false);

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
            ) = accesses.decode(false);

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
            ) = accesses.decode(false);

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
            accesses[0].oldBalance = 0;
            accesses[0].newBalance = 100;
            accesses[1] = accountAccess(addr2, new VmSafe.StorageAccess[](0));
            accesses[1].data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 200); // ERC20 transfer

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode(true);
            _assertStateDiffsAscending(diffs);

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
            accesses[0].oldBalance = 0;
            accesses[0].newBalance = 100;
            accesses[1] = accountAccess(addr2, new VmSafe.StorageAccess[](0));
            accesses[1].data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 200); // ERC20 transfer
            accesses[1].reverted = reverted;

            (
                AccountAccessParser.DecodedTransfer[] memory transfers,
                AccountAccessParser.DecodedStateDiff[] memory diffs
            ) = accesses.decode(true);
            _assertStateDiffsAscending(diffs);

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
            ) = accesses.decode(false);

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
            ) = accesses.decode(true);
            _assertStateDiffsAscending(diffs);

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

    function test_getNewContracts_succeeds() public pure {
        // Test empty array
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](0);
            address[] memory newContracts = accesses.getNewContracts();
            assertEq(newContracts.length, 0, "10");
        }

        // Test single successful contract creation
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr1, new VmSafe.StorageAccess[](0));
            accesses[0].kind = VmSafe.AccountAccessKind.Create;

            address[] memory newContracts = accesses.getNewContracts();
            assertEq(newContracts.length, 1, "20");
            assertEq(newContracts[0], addr1, "30");
        }

        // Test reverted contract creation (should not be included)
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
            accesses[0] = accountAccess(addr2, new VmSafe.StorageAccess[](0));
            accesses[0].kind = VmSafe.AccountAccessKind.Create;
            accesses[0].reverted = reverted;

            address[] memory newContracts = accesses.getNewContracts();
            assertEq(newContracts.length, 0, "40");
        }

        // Test multiple contract creations (mix of successful and reverted)
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](4);

            // Successful creation
            accesses[0] = accountAccess(addr3, new VmSafe.StorageAccess[](0));
            accesses[0].kind = VmSafe.AccountAccessKind.Create;

            // Regular call (not creation)
            accesses[1] = accountAccess(addr4, new VmSafe.StorageAccess[](0));
            accesses[1].kind = VmSafe.AccountAccessKind.Call;

            // Reverted creation
            accesses[2] = accountAccess(addr5, new VmSafe.StorageAccess[](0));
            accesses[2].kind = VmSafe.AccountAccessKind.Create;
            accesses[2].reverted = reverted;

            // Successful creation
            accesses[3] = accountAccess(addr6, new VmSafe.StorageAccess[](0));
            accesses[3].kind = VmSafe.AccountAccessKind.Create;

            address[] memory newContracts = accesses.getNewContracts();
            assertEq(newContracts.length, 2, "50");
            assertEq(newContracts[0], addr3, "60");
            assertEq(newContracts[1], addr6, "70");
        }

        // Test non-creation accesses
        {
            VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](3);

            // Call
            accesses[0] = accountAccess(addr7, new VmSafe.StorageAccess[](0));
            accesses[0].kind = VmSafe.AccountAccessKind.Call;

            // DelegateCall
            accesses[1] = accountAccess(addr8, new VmSafe.StorageAccess[](0));
            accesses[1].kind = VmSafe.AccountAccessKind.DelegateCall;

            // StaticCall
            accesses[2] = accountAccess(addr9, new VmSafe.StorageAccess[](0));
            accesses[2].kind = VmSafe.AccountAccessKind.StaticCall;

            address[] memory newContracts = accesses.getNewContracts();
            assertEq(newContracts.length, 0, "80");
        }
    }

    function test_decode_sorts_decoded_state_diffs() public view {
        // Create 5 test accounts with clear numerical values
        address account1 = address(0x1111111111111111111111111111111111111111);
        address account2 = address(0x2222222222222222222222222222222222222222);
        address account3 = address(0x3333333333333333333333333333333333333333);
        address account4 = address(0x4444444444444444444444444444444444444444);

        // account4 storage write at slot0
        VmSafe.StorageAccess[] memory firstStorageAccesses = new VmSafe.StorageAccess[](1);
        firstStorageAccesses[0] = storageAccess(account4, slot0, isWrite, val0, val2);

        // account3 storage write at slot0
        VmSafe.StorageAccess[] memory secondStorageAccesses = new VmSafe.StorageAccess[](1);
        secondStorageAccesses[0] = storageAccess(account3, slot1, isWrite, val0, val2);

        // account2 storage write at slot0
        VmSafe.StorageAccess[] memory thirdStorageAccesses = new VmSafe.StorageAccess[](1);
        thirdStorageAccesses[0] = storageAccess(account2, slot1, isWrite, val0, val2);

        // account2 storage write at slot1
        VmSafe.StorageAccess[] memory fourthStorageAccesses = new VmSafe.StorageAccess[](1);
        fourthStorageAccesses[0] = storageAccess(account2, slot0, isWrite, val0, val2);

        VmSafe.AccountAccess[] memory unsortedAccesses = new VmSafe.AccountAccess[](4);
        unsortedAccesses[0] = accountAccess(account1, firstStorageAccesses);
        unsortedAccesses[1] = accountAccess(account1, secondStorageAccesses);
        unsortedAccesses[2] = accountAccess(account2, thirdStorageAccesses);
        unsortedAccesses[3] = accountAccess(account3, fourthStorageAccesses);

        //Sort the accesses
        (, AccountAccessParser.DecodedStateDiff[] memory diffs) = AccountAccessParser.decode(unsortedAccesses, true);
        _assertStateDiffsAscending(diffs);

        // Verify the accesses are now in ascending numerical order by account address
        assertEq(diffs.length, 4, "Sorted array should have same length");
        assertEq(diffs[0].who, account2, "First should be account2 (0x2222...)");
        assertEq(diffs[1].who, account2, "Second should be account2 (0x2222...)");
        assertEq(diffs[2].who, account3, "Third should be account3 (0x3333...)");
        assertEq(diffs[3].who, account4, "Fourth should be account4 (0x4444...)");
    }

    function test_decode_reverts_if_state_diffs_not_sorted() public view {
        address account1 = address(0x1);
        address account2 = address(0x2);

        // account2 storage write at slot0
        VmSafe.StorageAccess[] memory firstStorageAccesses = new VmSafe.StorageAccess[](1);
        firstStorageAccesses[0] = storageAccess(account2, slot1, isWrite, val0, val2);

        // account2 storage write at slot1
        VmSafe.StorageAccess[] memory secondStorageAccesses = new VmSafe.StorageAccess[](1);
        secondStorageAccesses[0] = storageAccess(account2, slot0, isWrite, val0, val2);

        VmSafe.AccountAccess[] memory unsortedAccesses = new VmSafe.AccountAccess[](2);
        unsortedAccesses[0] = accountAccess(account1, firstStorageAccesses);
        unsortedAccesses[1] = accountAccess(account2, secondStorageAccesses);

        // Unsorted state diffs
        (, AccountAccessParser.DecodedStateDiff[] memory diffs) = AccountAccessParser.decode(unsortedAccesses, false);
        assertEq(diffs.length, 2, "Invalid number of state diffs");
        assertEq(diffs[0].who, diffs[1].who, "State diffs should have same account");
        assertTrue(diffs[0].raw.slot > diffs[1].raw.slot, "Slots should not be sorted");

        // Sorted state diffs
        (, AccountAccessParser.DecodedStateDiff[] memory sortedDiffs) =
            AccountAccessParser.decode(unsortedAccesses, true);
        assertEq(sortedDiffs.length, 2, "Invalid number of state diffs");
        assertEq(sortedDiffs[0].who, sortedDiffs[1].who, "State diffs should have same account");
        assertTrue(sortedDiffs[0].raw.slot < sortedDiffs[1].raw.slot, "Slots should be sorted");
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_containsValueTransfer_revertsWithCreateAccessKind() public {
        VmSafe.AccountAccess memory access;
        // Case 13: ETH transfer with Create access kind
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.value = 100;
        access.oldBalance = 0;
        access.newBalance = 100;
        access.kind = VmSafe.AccountAccessKind.Create;
        vm.expectRevert("ETH transfer with Create is not yet supported");
        access.containsValueTransfer();
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_containsValueTransfer_revertsWithSelfDestructAccessKind() public {
        // Case 14: ETH transfer with SelfDestruct access kind
        VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.value = 100;
        access.oldBalance = 0;
        access.newBalance = 100;
        access.kind = VmSafe.AccountAccessKind.SelfDestruct;
        vm.expectRevert("ETH transfer with SelfDestruct is not yet supported");
        access.containsValueTransfer();
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_containsValueTransfer_revertsWithUnexpectedAccessKind() public {
        // Case 15: ETH transfer with Unexpected access kind
        VmSafe.AccountAccess memory access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.value = 100;
        access.oldBalance = 0;
        access.newBalance = 100;
        access.kind = VmSafe.AccountAccessKind.Resume;
        vm.expectRevert("Expected kind to be DelegateCall.");
        access.containsValueTransfer();
    }

    function test_containsValueTransfer_succeeds() public pure {
        VmSafe.AccountAccess memory access;

        // Case 1: ETH Transfer
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.value = 100;
        access.oldBalance = 0;
        access.newBalance = 100;
        assertTrue(access.containsValueTransfer(), "10");

        // Case 2: Reverted ETH Transfer
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.value = 100;
        access.oldBalance = 0;
        access.newBalance = 0; // Balance doesn't change due to revert
        access.reverted = true;
        assertFalse(access.containsValueTransfer(), "20");

        // Case 3: ERC20 transfer
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0)); // addr1 is token address
        access.accessor = addr2; // from
        access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 100); // to, value
        assertTrue(access.containsValueTransfer(), "30");

        // Case 4: Reverted ERC20 transfer
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.accessor = addr2;
        access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 100);
        access.reverted = true;
        assertFalse(access.containsValueTransfer(), "40");

        // Case 5: ERC20 transferFrom
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0)); // addr1 is token address
        access.accessor = addr2; // spender
        access.data = abi.encodeWithSelector(IERC20.transferFrom.selector, addr3, addr4, 100); // from, to, value
        assertTrue(access.containsValueTransfer(), "50");

        // Case 6: Reverted ERC20 transferFrom
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.accessor = addr2;
        access.data = abi.encodeWithSelector(IERC20.transferFrom.selector, addr3, addr4, 100);
        access.reverted = true;
        assertFalse(access.containsValueTransfer(), "60");

        // Case 7: No transfer (simple call, no value, no relevant data)
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.data = abi.encodeWithSelector(bytes4(keccak256("someOtherFunction()")));
        assertFalse(access.containsValueTransfer(), "70");

        // Case 8: No transfer (storage write only)
        VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
        storageAccesses[0] = storageAccess(addr1, slot0, isWrite, val0, val1);
        access = accountAccess(addr1, storageAccesses);
        assertFalse(access.containsValueTransfer(), "80");

        // Case 9: Both ETH and ERC20 transfer (valid)
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0)); // addr1 is token address
        access.value = 50;
        access.oldBalance = 0;
        access.newBalance = 50;
        access.accessor = addr2; // from for ERC20, accessor for ETH
        access.data = abi.encodeWithSelector(IERC20.transfer.selector, addr3, 100); // to, value for ERC20
        assertTrue(access.containsValueTransfer(), "90");

        // Case 10: ETH transfer indicated by value, but oldBalance == newBalance (getETHTransfer should filter out)
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.value = 100;
        access.oldBalance = 500;
        access.newBalance = 500;
        access.accessor = addr2;
        assertFalse(access.containsValueTransfer(), "100");

        // Case 11: ETH transfer with value, oldBalance != newBalance, but access.reverted is true
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.value = 100;
        access.oldBalance = 0;
        access.newBalance = 100;
        access.reverted = true;
        // Even though newBalance is set as if the transfer happened, getETHTransfer checks for access.reverted
        // and also checks oldBalance != newBalance for the *actual* final state if not reverted.
        assertFalse(access.containsValueTransfer(), "110");

        // Case 12: ETH transfer with delegatecall access kind
        access = accountAccess(addr1, new VmSafe.StorageAccess[](0));
        access.value = 100;
        access.oldBalance = 0;
        access.newBalance = 100;
        access.kind = VmSafe.AccountAccessKind.DelegateCall;
        assertFalse(access.containsValueTransfer(), "120");
    }

    function test_tight_variable_packing_extractions_uint() public pure {
        // [offset: 12, bytes: 4, value: 0x000f79c5, name: blobbasefeeScalar][offset: 8, bytes: 4, value: 0x0000146b, name: basefeeScalar] [offset: 0, bytes: 8, value: 60_000_000, name: gasLimit]
        // Example taken from: lib/optimism/packages/contracts-bedrock/snapshots/storageLayout/SystemConfig.json (slot: 104)
        bytes32 slotValue = bytes32(uint256(0x00000000000000000000000000000000000f79c50000146b0000000003938700));
        string memory gasLimit = AccountAccessParser.toUint64(slotValue, 0);
        assertEq(gasLimit, "60000000", "Failed to extract uint64 from bytes32");
        string memory basefeeScalar = AccountAccessParser.toUint32(slotValue, 8);
        assertEq(basefeeScalar, "5227", "Failed to extract uint32 from bytes32");
        string memory blobbasefeeScalar = AccountAccessParser.toUint32(slotValue, 12);
        assertEq(blobbasefeeScalar, "1014213", "Failed to extract uint32 from bytes32");
    }

    /// The retirementTimestamp is introduced in the AnchorStateRegistry post op-contracts/v3.0.0-rc.2
    function test_normalizeTimestamp_AnchorStateRegistry_retirementTimestamp() public {
        vm.createSelectFork("mainnet", 22319975);
        address anchorStateRegistry = address(0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b); // op mainnet AnchorStateRegistryProxy
        // [offset: 8, bytes: 8, value: 0xFFFFFFFFFFFFFFFF, name: retirementTimestamp]
        bytes32 newValue1 = bytes32(uint256(0x0000000000000000000000000000000000000000FFFFFFFFFFFFFFFF00000000));
        AccountAccessParser.StateDiff memory diff1 = AccountAccessParser.StateDiff({
            slot: bytes32(uint256(6)),
            oldValue: bytes32(uint256(0)),
            newValue: newValue1
        });
        AccountAccessParser.normalizeTimestamp(anchorStateRegistry, diff1);
        assertEq(diff1.newValue, bytes32(uint256(0)));

        bytes32 newValue2 = bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000000));
        AccountAccessParser.StateDiff memory diff2 = AccountAccessParser.StateDiff({
            slot: bytes32(uint256(6)),
            oldValue: bytes32(uint256(0)),
            newValue: newValue2
        });
        AccountAccessParser.normalizeTimestamp(anchorStateRegistry, diff2);
        assertEq(diff2.newValue, bytes32(uint256(0)), "Value changed for op mainnet AnchorStateRegistryProxy");

        bytes32 newValue3 = bytes32(uint256(0x0000000000000000000000000000000000000000FFFFFF0FFFFFFFFF00000000));
        AccountAccessParser.StateDiff memory diff3 = AccountAccessParser.StateDiff({
            slot: bytes32(uint256(6)),
            oldValue: bytes32(uint256(0)),
            newValue: newValue3
        });
        AccountAccessParser.normalizeTimestamp(anchorStateRegistry, diff3);
        assertEq(diff3.newValue, bytes32(uint256(0)), "Value changed for op mainnet AnchorStateRegistryProxy");

        bytes32 newValue4 = bytes32(uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000010000000FFFFFFFF));
        AccountAccessParser.StateDiff memory diff4 = AccountAccessParser.StateDiff({
            slot: bytes32(uint256(6)),
            oldValue: bytes32(uint256(0)),
            newValue: newValue4
        });
        AccountAccessParser.normalizeTimestamp(anchorStateRegistry, diff4);
        assertEq(
            diff4.newValue,
            bytes32(uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000FFFFFFFF)),
            "Value changed for op mainnet AnchorStateRegistryProxy"
        );
    }

    function test_normalizeTimestamp_noChangeOnWrongContract() public view {
        bytes32 original = bytes32(uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF));

        AccountAccessParser.StateDiff memory diff =
            AccountAccessParser.StateDiff({slot: bytes32(uint256(6)), oldValue: bytes32(0), newValue: original});

        diff = AccountAccessParser.normalizeTimestamp(address(0x1234), diff); // wrong contract

        // Should remain unchanged because contract doesn't match
        assertEq(diff.newValue, original, "Value changed for wrong contract");
    }

    function test_normalizeTimestamp_noChangeOnWrongSlot() public view {
        bytes32 original = bytes32(uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF));

        AccountAccessParser.StateDiff memory diff = AccountAccessParser.StateDiff({
            slot: bytes32(uint256(999)), // wrong slot
            oldValue: bytes32(0),
            newValue: original
        });

        diff = AccountAccessParser.normalizeTimestamp(address(0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b), diff);

        // Should remain unchanged because slot doesn't match
        assertEq(diff.newValue, original, "Value changed for wrong slot");
    }

    function test_EmptyLayout() public pure {
        AccountAccessParser.JsonStorageLayout[] memory layout = new AccountAccessParser.JsonStorageLayout[](0);
        assertEq(AccountAccessParser.isSlotShared(layout, 0), false);
    }

    function test_SingleSlotNotShared() public pure {
        AccountAccessParser.JsonStorageLayout[] memory layout = new AccountAccessParser.JsonStorageLayout[](1);
        layout[0] = AccountAccessParser.JsonStorageLayout("32", "a", 0, "0", "uint256");
        assertEq(AccountAccessParser.isSlotShared(layout, 0), false);
    }

    function test_SharedSlot() public pure {
        AccountAccessParser.JsonStorageLayout[] memory layout = new AccountAccessParser.JsonStorageLayout[](2);
        layout[0] = AccountAccessParser.JsonStorageLayout("32", "a", 0, "0", "uint256");
        layout[1] = AccountAccessParser.JsonStorageLayout("32", "b", 32, "0", "uint256");
        assertEq(AccountAccessParser.isSlotShared(layout, 0), true);
    }

    function test_HexSlotFormat() public pure {
        AccountAccessParser.JsonStorageLayout[] memory layout = new AccountAccessParser.JsonStorageLayout[](2);
        layout[0] = AccountAccessParser.JsonStorageLayout("32", "a", 0, "0x0", "uint256");
        layout[1] = AccountAccessParser.JsonStorageLayout("32", "b", 32, "0x0", "uint256");
        assertEq(AccountAccessParser.isSlotShared(layout, 0), true);
    }

    function test_NonExistentSlot() public pure {
        AccountAccessParser.JsonStorageLayout[] memory layout = new AccountAccessParser.JsonStorageLayout[](2);
        layout[0] = AccountAccessParser.JsonStorageLayout("32", "a", 0, "1", "uint256");
        layout[1] = AccountAccessParser.JsonStorageLayout("32", "b", 32, "2", "uint256");
        assertEq(AccountAccessParser.isSlotShared(layout, 0), false);
    }

    function test_MultipleOccurrences() public pure {
        AccountAccessParser.JsonStorageLayout[] memory layout = new AccountAccessParser.JsonStorageLayout[](3);
        layout[0] = AccountAccessParser.JsonStorageLayout("32", "a", 0, "0", "uint256");
        layout[1] = AccountAccessParser.JsonStorageLayout("32", "b", 32, "0", "uint256");
        layout[2] = AccountAccessParser.JsonStorageLayout("32", "c", 64, "0", "uint256");
        assertEq(AccountAccessParser.isSlotShared(layout, 0), true);
    }

    function test_ReturnsSingleMatch() public pure {
        AccountAccessParser.JsonStorageLayout[] memory input = new AccountAccessParser.JsonStorageLayout[](1);
        input[0] = AccountAccessParser.JsonStorageLayout("32", "label1", 0, "123", "uint256");

        AccountAccessParser.JsonStorageLayout[] memory result =
            AccountAccessParser.getSharedSlotLayouts(input, bytes32(uint256(123)));

        assertEq(result.length, 1);
        assertEq(result[0]._slot, "123");
    }

    function test_ReturnsMultipleMatches() public pure {
        AccountAccessParser.JsonStorageLayout[] memory input = new AccountAccessParser.JsonStorageLayout[](3);
        input[0] = AccountAccessParser.JsonStorageLayout("32", "label1", 0, "456", "uint256");
        input[1] = AccountAccessParser.JsonStorageLayout("32", "label2", 32, "456", "address");
        input[2] = AccountAccessParser.JsonStorageLayout("32", "label3", 64, "456", "bytes32");

        AccountAccessParser.JsonStorageLayout[] memory result =
            AccountAccessParser.getSharedSlotLayouts(input, bytes32(uint256(456)));

        assertEq(result.length, 3);
        for (uint256 i = 0; i < 3; i++) {
            assertEq(result[i]._slot, "456");
        }
    }

    function test_ReturnsEmptyForNoMatches() public pure {
        AccountAccessParser.JsonStorageLayout[] memory input = new AccountAccessParser.JsonStorageLayout[](2);
        input[0] = AccountAccessParser.JsonStorageLayout("32", "label1", 0, "789", "uint256");
        input[1] = AccountAccessParser.JsonStorageLayout("32", "label2", 32, "999", "address");

        AccountAccessParser.JsonStorageLayout[] memory result =
            AccountAccessParser.getSharedSlotLayouts(input, bytes32(uint256(111)));

        assertEq(result.length, 0);
    }

    function test_FiltersNonMatchingEntries() public pure {
        AccountAccessParser.JsonStorageLayout[] memory input = new AccountAccessParser.JsonStorageLayout[](5);
        input[0] = AccountAccessParser.JsonStorageLayout("32", "match1", 0, "0x123", "uint256");
        input[1] = AccountAccessParser.JsonStorageLayout("20", "nonmatch", 32, "456", "address");
        input[2] = AccountAccessParser.JsonStorageLayout("32", "match2", 64, "0x123", "bytes32");
        input[3] = AccountAccessParser.JsonStorageLayout("1", "nonmatch", 96, "789", "bool");
        input[4] = AccountAccessParser.JsonStorageLayout("32", "match3", 128, "0x123", "string");

        AccountAccessParser.JsonStorageLayout[] memory result =
            AccountAccessParser.getSharedSlotLayouts(input, bytes32(uint256(0x123)));

        assertEq(result.length, 3);
        assertEq(result[0]._label, "match1");
        assertEq(result[1]._label, "match2");
        assertEq(result[2]._label, "match3");
    }

    function test_HandlesEmptyInput() public pure {
        AccountAccessParser.JsonStorageLayout[] memory input = new AccountAccessParser.JsonStorageLayout[](0);

        AccountAccessParser.JsonStorageLayout[] memory result =
            AccountAccessParser.getSharedSlotLayouts(input, bytes32(uint256(123)));

        assertEq(result.length, 0);
    }

    function test_MatchesZeroSlot() public pure {
        AccountAccessParser.JsonStorageLayout[] memory input = new AccountAccessParser.JsonStorageLayout[](2);
        input[0] = AccountAccessParser.JsonStorageLayout("32", "zero1", 0, "0", "uint256");
        input[1] = AccountAccessParser.JsonStorageLayout("32", "nonzero", 32, "1", "address");

        AccountAccessParser.JsonStorageLayout[] memory result =
            AccountAccessParser.getSharedSlotLayouts(input, bytes32(uint256(0)));

        assertEq(result.length, 1);
        assertEq(result[0]._label, "zero1");
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

    function _assertStateDiffsAscending(AccountAccessParser.DecodedStateDiff[] memory _diffs) internal pure {
        if (_diffs.length == 0) {
            return;
        }
        for (uint256 i = 0; i < _diffs.length - 1; i++) {
            // Less than or equal to because storage writes can exist at multiple slots for the same account.
            assertTrue(
                uint256(uint160(_diffs[i].who)) <= uint256(uint160(_diffs[i + 1].who)),
                string.concat(
                    "Addresses in state diffs are not in ascending order: ",
                    LibString.toHexString(_diffs[i].who),
                    " > ",
                    LibString.toHexString(_diffs[i + 1].who)
                )
            );
            // If the accounts are the same, the slots should also be in ascending order.
            if (_diffs[i].who == _diffs[i + 1].who) {
                assertTrue(
                    uint256(_diffs[i].raw.slot) <= uint256(_diffs[i + 1].raw.slot),
                    string.concat(
                        "Slots for address ",
                        LibString.toHexString(_diffs[i].who),
                        " are not in ascending order: ",
                        LibString.toHexString(uint256(_diffs[i].raw.slot)),
                        " > ",
                        LibString.toHexString(uint256(_diffs[i + 1].raw.slot))
                    )
                );
            }
        }
    }
}

// TODO Add integration tests in a follow up PR that actually send transactions and use the recorded state diff.
contract AccountAccessParser_normalizedStateDiffHash_Test is Test {
    using AccountAccessParser for VmSafe.AccountAccess[];

    bytes32 internal constant GNOSIS_SAFE_NONCE_SLOT = bytes32(uint256(5));
    bytes32 internal constant GNOSIS_SAFE_APPROVE_HASHES_SLOT = bytes32(uint256(8));
    bytes32 internal constant LIVENESS_GUARD_LAST_LIVE_SLOT = bytes32(uint256(0));
    bytes32 internal constant OPTIMISM_PORTAL_RESOURCE_PARAMS_SLOT = bytes32(uint256(1));

    bool constant isWrite = true;
    bool constant reverted = true;

    bytes32 constant slot0 = bytes32(uint256(0));
    bytes32 constant slot1 = bytes32(uint256(1));
    bytes32 constant slot2 = bytes32(uint256(2));

    bytes32 constant val0 = bytes32(uint256(0));
    bytes32 constant val1 = bytes32(uint256(1));
    bytes32 constant val2 = bytes32(uint256(2));

    address constant EOA_ADDR = address(0x1111);
    address constant SAFE_ADDR = address(0x2222);
    address constant RANDOM_CONTRACT_ADDR = address(0x3333);

    function setupTests() public {
        bytes memory safeCode = hex"01";
        vm.etch(SAFE_ADDR, safeCode);
        vm.mockCall(SAFE_ADDR, abi.encodeWithSignature("getThreshold()"), abi.encode(uint256(1)));

        assertTrue(AccountAccessParser.isGnosisSafe(SAFE_ADDR), "SAFE_ADDR should be detected as a Gnosis Safe");
        assertEq(EOA_ADDR.code.length, 0, "EOA_ADDR should have no code");
    }

    function test_normalizedStateDiffHash_EOANonceIncrement() public {
        setupTests();

        // Create a state diff for an EOA nonce increment (should be removed)
        VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
        storageAccesses[0] = storageAccess(EOA_ADDR, slot0, isWrite, val0, val1); // nonce 0 -> 1

        VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
        accesses[0] = accountAccess(EOA_ADDR, storageAccesses);

        // Get the normalized hash
        bytes32 hash = accesses.normalizedStateDiffHash(address(0), bytes32(0));

        // Since this is just an EOA nonce increment, the normalized array should be empty
        // and the hash should match an empty array
        AccountAccessParser.AccountStateDiff[] memory emptyArray = new AccountAccessParser.AccountStateDiff[](0);
        bytes32 expectedHash = keccak256(abi.encode(emptyArray));

        assertEq(hash, expectedHash, "EOA nonce increment should be removed");
    }

    function test_normalizedStateDiffHash_GnosisSafeNonceIncrement() public {
        setupTests();

        // Create a state diff for a Gnosis Safe nonce increment (should be removed)
        VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
        storageAccesses[0] = storageAccess(SAFE_ADDR, GNOSIS_SAFE_NONCE_SLOT, isWrite, val0, val1); // nonce 0 -> 1

        VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
        accesses[0] = accountAccess(SAFE_ADDR, storageAccesses);

        // Get the normalized hash
        bytes32 hash = accesses.normalizedStateDiffHash(address(0), bytes32(0));

        // Since this is just a Safe nonce increment, the normalized array should be empty
        // and the hash should match an empty array
        AccountAccessParser.AccountStateDiff[] memory emptyArray = new AccountAccessParser.AccountStateDiff[](0);
        bytes32 expectedHash = keccak256(abi.encode(emptyArray));

        assertEq(hash, expectedHash, "Gnosis Safe nonce increment should be removed");
    }

    /// This test uses a real transaction that was approved on mainnet.
    /// Find more details here: https://github.com/ethereum-optimism/superchain-ops/blob/main/src/improvements/tasks/eth/003-opcm-upgrade-v300-op-ink-soneium/VALIDATION.md
    function test_normalizedStateDiffHash_GnosisSafeApproveHash() public {
        vm.createSelectFork("mainnet", 22319975);

        address multisig = address(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A);
        bytes32 approveHashSlot = 0xb83cd9f113d329914a61adce818feb77eb750bf02115fdb71f059425216265be;

        // Create a state diff for a Gnosis Safe approve hash (should be removed)
        VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
        storageAccesses[0] = storageAccess(multisig, approveHashSlot, isWrite, val0, val1); // approve hash

        VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
        accesses[0] = accountAccess(multisig, storageAccesses);

        bytes32 txHash = 0x0d1a3b425e64a0c9bd90f6933632c1cc0042896a1c5831ac8ef290cab8205e83;
        bytes32 hash = accesses.normalizedStateDiffHash(multisig, txHash);

        // Since this is just a Safe approve hash, the normalized array should be empty
        // and the hash should match an empty array
        AccountAccessParser.AccountStateDiff[] memory emptyArray = new AccountAccessParser.AccountStateDiff[](0);
        bytes32 expectedHash = keccak256(abi.encode(emptyArray));

        assertEq(hash, expectedHash, "Gnosis Safe approve hash should be removed");
    }

    function test_normalizedStateDiffHash_OtherChanges() public {
        setupTests();

        // Create a state diff for a regular contract (should be included)
        VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
        storageAccesses[0] = storageAccess(RANDOM_CONTRACT_ADDR, slot1, isWrite, val0, val2); // some random change

        VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
        accesses[0] = accountAccess(RANDOM_CONTRACT_ADDR, storageAccesses);

        // Get the normalized hash
        bytes32 hash = accesses.normalizedStateDiffHash(address(0), bytes32(0));

        // This should be included in the normalized array
        AccountAccessParser.AccountStateDiff[] memory emptyArray = new AccountAccessParser.AccountStateDiff[](0);
        assertNotEq(hash, keccak256(abi.encode(emptyArray)), "Regular state change should be included");

        // Create the expected AccountStateDiff array
        AccountAccessParser.AccountStateDiff[] memory expectedArray = new AccountAccessParser.AccountStateDiff[](1);
        expectedArray[0] = AccountAccessParser.AccountStateDiff({
            who: RANDOM_CONTRACT_ADDR,
            slot: slot1,
            firstOld: val0,
            lastNew: val2
        });

        bytes32 expectedHash = keccak256(abi.encode(expectedArray));
        assertEq(hash, expectedHash, "Hash should match the expected AccountStateDiff");
    }

    function test_normalizedStateDiffHash_MixedChanges() public {
        vm.createSelectFork("mainnet", 22319975);
        setupTests();

        address multisig = address(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A);
        bytes32 txHash = keccak256("fake tx hash");
        bytes32 ownerSlot = keccak256(abi.encode(IGnosisSafe(multisig).getOwners()[0], GNOSIS_SAFE_APPROVE_HASHES_SLOT));
        bytes32 fakeApproveHashSlot = keccak256(abi.encode(txHash, ownerSlot));
        // Create the combined account accesses array with all our test cases
        VmSafe.AccountAccess[] memory allAccesses = new VmSafe.AccountAccess[](3);

        // 1. EOA nonce increment (should be filtered out)
        VmSafe.StorageAccess[] memory eoaStorageAccesses = new VmSafe.StorageAccess[](1);
        eoaStorageAccesses[0] = storageAccess(EOA_ADDR, slot0, isWrite, val0, val1);
        allAccesses[0] = accountAccess(EOA_ADDR, eoaStorageAccesses);

        // 2. Gnosis Safe changes (should be filtered out)
        VmSafe.StorageAccess[] memory safeStorageAccesses = new VmSafe.StorageAccess[](2);
        safeStorageAccesses[0] = storageAccess(multisig, GNOSIS_SAFE_NONCE_SLOT, isWrite, val0, val1); // nonce increment
        safeStorageAccesses[1] = storageAccess(multisig, fakeApproveHashSlot, isWrite, val0, val1); // approve hash
        allAccesses[1] = accountAccess(multisig, safeStorageAccesses);

        // 3. Regular contract change (should be kept)
        VmSafe.StorageAccess[] memory regularStorageAccesses = new VmSafe.StorageAccess[](1);
        regularStorageAccesses[0] = storageAccess(RANDOM_CONTRACT_ADDR, slot1, isWrite, val0, val2);
        allAccesses[2] = accountAccess(RANDOM_CONTRACT_ADDR, regularStorageAccesses);

        // Get the normalized hash
        bytes32 hash = allAccesses.normalizedStateDiffHash(multisig, txHash);

        // Manually construct what we expect the normalized state to be using AccountStateDiff
        AccountAccessParser.AccountStateDiff[] memory expectedArray = new AccountAccessParser.AccountStateDiff[](1);
        expectedArray[0] = AccountAccessParser.AccountStateDiff({
            who: RANDOM_CONTRACT_ADDR,
            slot: slot1,
            firstOld: val0,
            lastNew: val2
        });

        bytes32 expectedHash = keccak256(abi.encode(expectedArray));

        // Now let's check that the regular contract write is included and other writes are excluded
        AccountAccessParser.AccountStateDiff[] memory emptyArray = new AccountAccessParser.AccountStateDiff[](0);
        assertTrue(
            hash != keccak256(abi.encode(emptyArray)),
            "Hash should not be of an empty array (regular writes should be included)"
        );

        assertEq(hash, expectedHash, "Normalized hash should match expected state with only regular contract changes");
    }

    /// This test uses data from a real liveness guard timestamp update on mainnet.
    /// Find more details here: https://github.com/ethereum-optimism/superchain-ops/blob/main/src/improvements/tasks/eth/003-opcm-upgrade-v300-op-ink-soneium/VALIDATION.md
    function test_normalizedStateDiffHash_LivenessGuardTimestamp() public {
        vm.createSelectFork("mainnet", 22319975);
        setupTests();

        address livenessGuard = address(0x24424336F04440b1c28685a38303aC33C9D14a25);
        address firstOwnerOnSecurityCouncil = address(0x07dC0893cAfbF810e3E72505041f2865726Fd073);
        bytes32 lastLiveSlot = keccak256(abi.encode(firstOwnerOnSecurityCouncil, LIVENESS_GUARD_LAST_LIVE_SLOT));

        VmSafe.AccountAccess[] memory allAccesses = new VmSafe.AccountAccess[](1);
        // Create a state diff for a LivenessGuard timestamp (should be removed)
        VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
        storageAccesses[0] = storageAccess(livenessGuard, lastLiveSlot, isWrite, val0, val1);
        allAccesses[0] = accountAccess(livenessGuard, storageAccesses);

        address parentMultisig = address(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A);
        bytes32 hash = allAccesses.normalizedStateDiffHash(parentMultisig, bytes32(0));

        // Since this is just a LivenessGuard timestamp update, the normalized array should be empty
        // and the hash should match an empty array
        AccountAccessParser.AccountStateDiff[] memory emptyArray = new AccountAccessParser.AccountStateDiff[](0);
        bytes32 expectedHash = keccak256(abi.encode(emptyArray));

        assertEq(hash, expectedHash, "LivenessGuard timestamp update should be removed");
    }

    function test_normalizedStateDiffHash_AnchorStateRegistryRetirementTimestamp() public {
        vm.createSelectFork("mainnet", 22319975);
        setupTests();

        address anchorStateRegistry = address(0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b);
        bytes32 retirementTimestampSlot = bytes32(uint256(6));
        bytes32 retirementTimestamp =
            bytes32(uint256(0x0000000000000000000000000000000000000000FFFFFFFFFFFFFFFF00000000));
        VmSafe.AccountAccess[] memory allAccesses = new VmSafe.AccountAccess[](1);
        VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
        storageAccesses[0] =
            storageAccess(anchorStateRegistry, retirementTimestampSlot, isWrite, val0, retirementTimestamp);
        allAccesses[0] = accountAccess(anchorStateRegistry, storageAccesses);

        address parentMultisig = address(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A);
        bytes32 hash = allAccesses.normalizedStateDiffHash(parentMultisig, bytes32(0));
        bytes32 expectedHash = bytes32(0x241e6b7219e7929518322ed65cbe52a5d3f6c3e61439ae8fdae8e842d3f8f500);

        assertEq(hash, expectedHash, "AnchorStateRegistry should match the expected hash");

        bytes32 retirementTimestamp2 =
            bytes32(uint256(0x0000000000000000000000000000000000000000AAAAAAAAAAAAAAAA00000000));
        storageAccesses[0] =
            storageAccess(anchorStateRegistry, retirementTimestampSlot, isWrite, val0, retirementTimestamp2);
        allAccesses[0] = accountAccess(anchorStateRegistry, storageAccesses);

        bytes32 hash2 = allAccesses.normalizedStateDiffHash(parentMultisig, bytes32(0));
        assertEq(hash2, expectedHash, "AnchorStateRegistry should still match the expected hash");
    }

    function test_normalizedStateDiffHash_AnchorStateRegistryProposal() public {
        vm.createSelectFork("mainnet", 22319975);
        setupTests();

        address anchorStateRegistry = address(0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b);
        bytes32 proposalRootSlot = bytes32(uint256(3));
        bytes32 proposalRoot = bytes32(uint256(0x08ce0a407e15a1776bd43cd669328edc6825fcab988b8e2052258774251c25d2));
        bytes32 proposalL2SequenceNumberSlot = bytes32(uint256(4));
        bytes32 proposalL2SequenceNumber =
            bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000001287b8d));

        VmSafe.AccountAccess[] memory allAccesses = new VmSafe.AccountAccess[](1);
        VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](2);
        storageAccesses[0] = storageAccess(anchorStateRegistry, proposalRootSlot, isWrite, val0, proposalRoot);
        storageAccesses[1] =
            storageAccess(anchorStateRegistry, proposalL2SequenceNumberSlot, isWrite, val0, proposalL2SequenceNumber);
        allAccesses[0] = accountAccess(anchorStateRegistry, storageAccesses);

        address parentMultisig = address(0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A);
        bytes32 hash = allAccesses.normalizedStateDiffHash(parentMultisig, bytes32(0));

        AccountAccessParser.AccountStateDiff[] memory emptyArray = new AccountAccessParser.AccountStateDiff[](0);
        bytes32 expectedHash = keccak256(abi.encode(emptyArray));

        assertEq(hash, expectedHash, "AnchorStateRegistry proposal should be removed");
    }

    /// It's possible for there to be more storage writes than accesses.
    /// This test checks that the function handles this case correctly.
    function test_more_storage_writes_than_accesses_passes() public pure {
        address who = address(0xabcd);
        VmSafe.AccountAccess[] memory accesses = new VmSafe.AccountAccess[](1);
        VmSafe.StorageAccess[] memory sa = new VmSafe.StorageAccess[](2);
        sa[0] = storageAccess(who, bytes32(uint256(0x1)), isWrite, val0, val1);
        sa[1] = storageAccess(who, bytes32(uint256(0x2)), isWrite, val0, val1);
        accesses[0] = accountAccess(who, sa);

        AccountAccessParser.StateDiff[] memory diffs = AccountAccessParser.getStateDiffFor(accesses, who, false);
        assertEq(diffs.length, sa.length, "The number of diffs should be equal to the number of storage writes");
    }

    function test_normalizedStateDiffHash_OptimismPortalResourceMetering() public {
        setupTests();
        vm.createSelectFork("mainnet", 22319975); // Use a realistic block number
        VmSafe.AccountAccess[] memory allAccesses = new VmSafe.AccountAccess[](1);
        // Create a state diff for OptimismPortal ResourceMetering
        address who = address(0xabcd);
        VmSafe.StorageAccess[] memory storageAccesses = new VmSafe.StorageAccess[](1);
        IResourceMetering.ResourceParams memory resourceParams = IResourceMetering.ResourceParams({
            prevBaseFee: uint128(5),
            prevBoughtGas: uint64(6),
            prevBlockNum: uint64(block.number)
        });
        bytes32 resourceParamsSlot = packResourceParams(resourceParams);
        storageAccesses[0] =
            storageAccess(who, OPTIMISM_PORTAL_RESOURCE_PARAMS_SLOT, isWrite, bytes32(uint256(0)), resourceParamsSlot);
        allAccesses[0] = accountAccess(who, storageAccesses);
        bytes32 hash = allAccesses.normalizedStateDiffHash(address(1), bytes32(0));

        AccountAccessParser.AccountStateDiff[] memory emptyArray = new AccountAccessParser.AccountStateDiff[](0);
        bytes32 expectedHash = keccak256(abi.encode(emptyArray));
        assertEq(hash, expectedHash, "OptimismPortal ResourceParams update should be removed");
    }

    /// @notice Packs the resource params into a bytes32. Where prevBlockNum is the most significant 64 bits, prevBoughtGas is the next 64 bits, and prevBaseFee is the least significant 128 bits.
    function packResourceParams(IResourceMetering.ResourceParams memory _resourceParams)
        internal
        pure
        returns (bytes32)
    {
        return (bytes32(uint256(_resourceParams.prevBlockNum)) << (128 + 64))
            | (bytes32(uint256(_resourceParams.prevBoughtGas)) << 128) | (bytes32(uint256(_resourceParams.prevBaseFee)));
    }

    /// Helper functions similar to those in AccountAccessParser.t.sol
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
