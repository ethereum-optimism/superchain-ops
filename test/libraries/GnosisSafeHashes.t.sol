// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import "forge-std/Test.sol";
import {GnosisSafeHashes} from "src/libraries/GnosisSafeHashes.sol";
import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {VmSafe} from "forge-std/Vm.sol";

contract GnosisSafeHashes_Test is Test {
    using GnosisSafeHashes for bytes;

    /// @notice Test calculateMessageHashFromCalldata with valid input
    function testCalculateMessageHashFromCalldata_ValidInput() public pure {
        address to = address(0x1234567890123456789012345678901234567890);
        uint256 value = 0;
        bytes memory data = hex"12345678";
        uint8 operation = 0;
        uint256 safeTxGas = 100000;
        uint256 baseGas = 50000;
        uint256 gasPrice = 20000000000;
        address gasToken = address(0);
        address refundReceiver = address(0);
        uint256 nonce = 42;

        bytes memory callData =
            createSafeTxCalldata(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver);

        // Calculate the expected message hash manually
        bytes32 dataHash = keccak256(data);
        bytes32 expectedHash = keccak256(
            abi.encode(
                GnosisSafeHashes.SAFE_TX_TYPEHASH,
                to,
                value,
                dataHash,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                nonce
            )
        );

        // Test the function
        bytes32 actualHash = callData.calculateMessageHashFromCalldata(nonce);
        assertEq(actualHash, expectedHash, "Message hash should match expected value");
    }

    /// @notice Test calculateDomainSeparator for old Safe version (< 1.3.0) - Our FoundationOperationsSafe is old.
    function testCalculateDomainSeparator_OldVersion() public {
        vm.createSelectFork("mainnet", 23147844);
        address foundationOperationsSafe = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

        // Calculate domain separator using the library
        bytes32 actualDomainSeparator = GnosisSafeHashes.calculateDomainSeparator(1, foundationOperationsSafe);
        bytes32 expectedDomainSeparator = IGnosisSafe(foundationOperationsSafe).domainSeparator();

        assertEq(IGnosisSafe(foundationOperationsSafe).VERSION(), "1.1.1"); // Asserting that this is an old version.
        assertEq(
            actualDomainSeparator,
            expectedDomainSeparator,
            "Domain separator should match expected value for old Safe version"
        );
        assertTrue(actualDomainSeparator != bytes32(0), "Domain separator should not be zero");
    }

    /// @notice Test calculateDomainSeparator for old Safe version (< 1.3.0) - Our FoundationOperationsSafe is old.
    function testCalculateDomainSeparator_NewVersion() public {
        vm.createSelectFork("mainnet", 23147844);
        address guardianSafe = 0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2;

        // Calculate domain separator using the library
        bytes32 actualDomainSeparator = GnosisSafeHashes.calculateDomainSeparator(1, guardianSafe);
        bytes32 expectedDomainSeparator = IGnosisSafe(guardianSafe).domainSeparator();

        assertEq(IGnosisSafe(guardianSafe).VERSION(), "1.3.0"); // Asserting that this is an new version.
        assertEq(
            actualDomainSeparator,
            expectedDomainSeparator,
            "Domain separator should match expected value for new Safe version"
        );
        assertTrue(actualDomainSeparator != bytes32(0), "Domain separator should not be zero");
    }

    /// @notice Test isOldDomainSeparatorVersion with invalid version formats
    function testIsOldDomainSeparatorVersion_InvalidVersionFormats() public {
        vm.createSelectFork("mainnet", 23147844);
        address foundationOperationsSafe = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;
        GnosisSafeHashes_Harness gnosisSafeHashesHarness = new GnosisSafeHashes_Harness();
        // Test with version missing dots (should revert)
        vm.mockCall(
            foundationOperationsSafe, abi.encodeWithSelector(IGnosisSafe.VERSION.selector), abi.encode("invalidversion")
        );
        vm.expectRevert("GnosisSafeHashes: Invalid version format");
        gnosisSafeHashesHarness.isOldDomainSeparatorVersion(foundationOperationsSafe);

        // Test with version missing second dot (should revert)
        vm.mockCall(foundationOperationsSafe, abi.encodeWithSelector(IGnosisSafe.VERSION.selector), abi.encode("1.2"));

        vm.expectRevert("GnosisSafeHashes: Invalid version format");
        gnosisSafeHashesHarness.isOldDomainSeparatorVersion(foundationOperationsSafe);
    }

    /// @notice Test with valid input. The encoded data is constructed as:
    /// [0x19, 0x01, 32 bytes domain separator (zeros), 32 bytes message hash].
    function testGetMessageHashFromEncodedTransactionData_ValidInput() public pure {
        bytes32 expectedDomainSeparator = bytes32(hex"0000000000000000000000000000000000000000000000000000000000001234");
        bytes32 expectedMessageHash = bytes32(hex"000000000000000000000000000000000000000000000000000000000000abcd");
        bytes memory encodedTxData = abi.encodePacked(bytes2(0x1901), expectedDomainSeparator, expectedMessageHash);

        (bytes32 domainSeparator, bytes32 messageHash) =
            encodedTxData.getDomainAndMessageHashFromEncodedTransactionData();
        assertEq(domainSeparator, expectedDomainSeparator, "Domain separator should be all zeros");
        assertEq(messageHash, expectedMessageHash, "Message hash should match the last 32 bytes");
    }

    /// @notice Test where the message hash is all zeros.
    function testGetMessageHashFromEncodedTransactionData_AllZeros() public pure {
        bytes memory encodedTxData = abi.encodePacked(bytes2(0x1901), bytes32(0), bytes32(0));
        bytes32 expectedHash = bytes32(0);

        (bytes32 domainSeparator, bytes32 messageHash) =
            encodedTxData.getDomainAndMessageHashFromEncodedTransactionData();
        assertEq(domainSeparator, expectedHash, "Domain separator should be all zeros");
        assertEq(messageHash, expectedHash, "Message hash should be all zeros");
    }

    function testGetDomainAndMessageHashFromEncodedTransactionData_MaxUint256() public pure {
        bytes memory encodedTxData =
            abi.encodePacked(bytes2(0x1901), bytes32(type(uint256).max), bytes32(type(uint256).max));
        bytes32 expectedHash = bytes32(type(uint256).max);

        (bytes32 domainSeparator, bytes32 messageHash) =
            encodedTxData.getDomainAndMessageHashFromEncodedTransactionData();
        assertEq(domainSeparator, expectedHash, "Domain separator should be the max uint256");
        assertEq(messageHash, expectedHash, "Message hash should be the max uint256");
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testGetMessageHashFromEncodedTransactionData_TooShort() public {
        // Only 6 bytes (too short)
        bytes memory encodedTxData = hex"1901deadbeef";
        vm.expectRevert("GnosisSafeHashes: Invalid encoded transaction data length.");
        encodedTxData.getDomainAndMessageHashFromEncodedTransactionData();
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testGetMessageHashFromEncodedTransactionData_TooLong() public {
        // 67 bytes (too long)
        bytes memory encodedTxData = new bytes(67);
        vm.expectRevert("GnosisSafeHashes: Invalid encoded transaction data length.");
        encodedTxData.getDomainAndMessageHashFromEncodedTransactionData();
    }

    function testGetMessageHashFromEncodedTransactionData_FuzzTest(bytes32 randomHash) public pure {
        bytes memory encodedTxData = abi.encodePacked(bytes2(0x1901), bytes32(0), randomHash);
        (, bytes32 messageHash) = encodedTxData.getDomainAndMessageHashFromEncodedTransactionData();
        assertEq(messageHash, randomHash, "Message hash should match the input random hash");
    }

    /// @notice Test decodeMulticallApproveHash with valid input.
    function testDecodeMulticallApproveHash_ValidInput() public pure {
        bytes32 testHash = keccak256("test hash");

        // Prepare callData for `approveHash(bytes32)`
        bytes memory approveCalldata = abi.encodeWithSelector(bytes4(keccak256("approveHash(bytes32)")), testHash);

        // Prepare the `Call3Value` struct
        IMulticall3.Call3Value memory call =
            IMulticall3.Call3Value({target: address(0), allowFailure: false, value: 0, callData: approveCalldata});

        // Prepare the multicall array
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);
        calls[0] = call;

        // Prepare the full calldata for multicall
        bytes memory multicallCalldata = abi.encodeWithSelector(bytes4(0xdeadbeef), calls);

        // Decode and assert
        bytes32 decodedHash = GnosisSafeHashes.decodeMulticallApproveHash(multicallCalldata);
        assertEq(decodedHash, testHash, "Decoded hash should match");
    }

    /// @notice Test decodeMulticallApproveHash with calldata that is too short.
    /// forge-config: default.allow_internal_expect_revert = true
    function testDecodeMulticallApproveHash_TooShortCalldata() public {
        bytes memory shortCalldata = hex"1234";
        vm.expectRevert("GnosisSafeHashes: calldata too short");
        GnosisSafeHashes.decodeMulticallApproveHash(shortCalldata);
    }

    /// @notice Test decodeMulticallApproveHash with multiple calls.
    /// forge-config: default.allow_internal_expect_revert = true
    function testDecodeMulticallApproveHash_MultipleCalls() public {
        bytes32 testHash = keccak256("test hash");
        bytes memory approveCalldata = abi.encodeWithSelector(bytes4(keccak256("approveHash(bytes32)")), testHash);

        IMulticall3.Call3Value memory call =
            IMulticall3.Call3Value({target: address(0), allowFailure: false, value: 0, callData: approveCalldata});

        // Two calls instead of one
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](2);
        calls[0] = call;
        calls[1] = call;

        bytes memory multicallCalldata = abi.encodeWithSelector(bytes4(0xdeadbeef), calls);

        vm.expectRevert("GnosisSafeHashes: expected single approval call");
        GnosisSafeHashes.decodeMulticallApproveHash(multicallCalldata);
    }

    /// @notice Test decodeMulticallApproveHash with invalid approveCalldata length.
    /// forge-config: default.allow_internal_expect_revert = true
    function testDecodeMulticallApproveHash_InvalidApproveCalldataLength() public {
        bytes memory invalidApproveCalldata = hex"12345678";

        IMulticall3.Call3Value memory call = IMulticall3.Call3Value({
            target: address(0),
            allowFailure: false,
            value: 0,
            callData: invalidApproveCalldata
        });

        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);
        calls[0] = call;

        bytes memory multicallCalldata = abi.encodeWithSelector(bytes4(0xdeadbeef), calls);

        vm.expectRevert("GnosisSafeHashes: invalid approveHash calldata length");
        GnosisSafeHashes.decodeMulticallApproveHash(multicallCalldata);
    }

    /// @notice Fuzz test for decodeMulticallApproveHash.
    function testDecodeMulticallApproveHash_FuzzTest(bytes32 randomHash) public pure {
        // Prepare callData for `approveHash(bytes32)`
        bytes memory approveCalldata = abi.encodeWithSelector(bytes4(keccak256("approveHash(bytes32)")), randomHash);

        // Prepare the `Call3Value` struct
        IMulticall3.Call3Value memory call =
            IMulticall3.Call3Value({target: address(0), allowFailure: false, value: 0, callData: approveCalldata});

        // Prepare the multicall array
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);
        calls[0] = call;

        // Prepare the full calldata for multicall
        bytes memory multicallCalldata = abi.encodeWithSelector(bytes4(0xdeadbeef), calls);

        // Decode and assert
        bytes32 decodedHash = GnosisSafeHashes.decodeMulticallApproveHash(multicallCalldata);
        assertEq(decodedHash, randomHash, "Decoded hash should match random hash");
    }

    /// Test to make sure the opinionated nature of getEncodedTransactionData remains.
    /// This function is specifically designed to be opinionated and work with MultisigTask.sol.
    function testGetEncodedTransactionDataAndExecCalldata() public {
        vm.createSelectFork("mainnet", 22696253); // Expected encoded data will be reproducible at this block.
        address safe = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A; // Use a real GnosisSafe address.
        bytes32 hash = keccak256("txHash");
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("approveHash(bytes32)")), hash);
        uint256 value = 0;
        uint256 nonce = IGnosisSafe(safe).nonce();
        address multicall = 0xcA11bde05977b3631167028862bE2a173976CA11; // Official Multicall3
        bytes memory encodedData = GnosisSafeHashes.getEncodedTransactionData(safe, data, value, nonce, multicall);
        bytes memory expectedEncodedData =
            hex"1901daf670b31fdf41fdaae2643ed0ebe709283539c0e61540c160b5a6403d79073f425b64ae71da88c9c7a74b94d0b760e4544add8e920a225bc137009e4e1a8594";
        assertEq(encodedData.length, 66);
        assertEq(keccak256(encodedData), keccak256(expectedEncodedData));

        bytes memory signatures = new bytes(0);
        bytes memory execCalldata = GnosisSafeHashes.encodeExecTransactionCalldata(safe, data, signatures, multicall);
        bytes memory expectedExecCalldata =
            hex"6a761202000000000000000000000000ca11bde05977b3631167028862be2a173976ca110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000000000000000000000000000000000024d4d9bdcd7e1975a6bf513022a8cc382a3cdb1e1dbcd58ebb1cb9abf11e64aadb21262516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        assertEq(keccak256(execCalldata), keccak256(expectedExecCalldata));
    }

    /// @notice Test the min helper function
    function testMinFunction() public pure {
        // Test basic functionality
        assertEq(GnosisSafeHashes.min(5, 10), 5, "min(5, 10) should return 5");
        assertEq(GnosisSafeHashes.min(10, 5), 5, "min(10, 5) should return 5");
        assertEq(GnosisSafeHashes.min(7, 7), 7, "min(7, 7) should return 7");

        // Test edge cases
        assertEq(GnosisSafeHashes.min(0, 100), 0, "min(0, 100) should return 0");
        assertEq(GnosisSafeHashes.min(100, 0), 0, "min(100, 0) should return 0");
        assertEq(GnosisSafeHashes.min(0, 0), 0, "min(0, 0) should return 0");

        // Test large numbers
        assertEq(GnosisSafeHashes.min(type(uint256).max, 1000), 1000, "min(max, 1000) should return 1000");
        assertEq(GnosisSafeHashes.min(1000, type(uint256).max), 1000, "min(1000, max) should return 1000");
    }

    /// @notice Test getOperationDetails with all valid operation kinds and invalid ones
    function testGetOperationDetails() public {
        GnosisSafeHashes_Harness gnosisSafeHashesHarness = new GnosisSafeHashes_Harness();

        (string memory opStr1, Enum.Operation op1) = GnosisSafeHashes.getOperationDetails(VmSafe.AccountAccessKind.Call);
        assertEq(opStr1, "Call", "Call operation should return 'Call' string");
        assertTrue(op1 == Enum.Operation.Call, "Call operation should return Call enum");
        (string memory opStr2, Enum.Operation op2) =
            GnosisSafeHashes.getOperationDetails(VmSafe.AccountAccessKind.DelegateCall);
        assertEq(opStr2, "DelegateCall", "DelegateCall operation should return 'DelegateCall' string");
        assertTrue(op2 == Enum.Operation.DelegateCall, "DelegateCall operation should return DelegateCall enum");

        // Test invalid operation kind (should revert)
        // We need to cast an invalid value to trigger the revert
        VmSafe.AccountAccessKind invalidKind = VmSafe.AccountAccessKind(uint8(10)); // Invalid enum value

        vm.expectRevert("Unknown account access kind");
        gnosisSafeHashesHarness.getOperationDetails(invalidKind);
    }

    /// @notice Helper to create valid Safe transaction calldata
    function createSafeTxCalldata(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver
    ) internal pure returns (bytes memory) {
        // Function selector for execTransaction (0x6a761202)
        bytes4 selector = bytes4(0x6a761202);

        // Encode the parameters
        bytes memory encodedParams =
            abi.encode(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver);

        return abi.encodePacked(selector, encodedParams);
    }
}

contract GnosisSafeHashes_Harness is Test {
    using GnosisSafeHashes for address;

    function isOldDomainSeparatorVersion(address _safeAddress) public view returns (bool isOldVersion_) {
        return GnosisSafeHashes.isOldDomainSeparatorVersion(_safeAddress);
    }

    function getOperationDetails(VmSafe.AccountAccessKind _kind) public pure returns (string memory, Enum.Operation) {
        return GnosisSafeHashes.getOperationDetails(_kind);
    }
}
