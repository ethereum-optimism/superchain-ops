// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {SetL1SplitterConfig} from "src/template/SetL1SplitterConfig.sol";

/// @notice Runs the L2 pre-flight on a pinned Unichain fork with a successor already nominated
///         (pendingOwner set, not yet accepted) and only a setter configured.
contract SetL1SplitterConfigPendingOwnerHarness is SetL1SplitterConfig {
    uint256 internal constant UNICHAIN_PINNED_BLOCK = 60099000;

    address internal nominee;

    function preflightSetterOnly(address _splitter, address _recipient, address _nominee, address _rootSafe) external {
        chainId = 130;
        l1Splitter = _splitter;
        setL1Recipient = true;
        l1Recipient = _recipient;
        nominee = _nominee;
        _preflightL2("https://mainnet.unichain.org", _rootSafe);
    }

    function _createL2Fork(string memory _l2RpcUrl) internal override {
        vm.createSelectFork(_l2RpcUrl, UNICHAIN_PINNED_BLOCK);
        vm.store(l1Splitter, PENDING_OWNER_SLOT, bytes32(uint256(uint160(nominee))));
    }
}

contract SetL1SplitterConfigPendingOwnerTest is Test {
    address internal constant L1_SPLITTER = 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003;
    /// @dev Current owner is this Safe's L2 alias.
    address internal constant UNICHAIN_SYSTEM_CONFIG_OWNER_SAFE = 0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1;
    /// @dev Alias of the L1PAO, i.e. the leg-A nominee.
    address internal constant NOMINEE = 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b;

    /// @notice A recipient-only update by the current owner leaves the nomination in place; the
    ///         pre-flight's pendingOwner assertion must accept it instead of expecting zero.
    function test_preflight_setterOnlyWithPendingOwner_preservesNomination() public {
        vm.createSelectFork("https://mainnet.unichain.org", 60099000);
        SetL1SplitterConfigPendingOwnerHarness harness = new SetL1SplitterConfigPendingOwnerHarness();
        harness.preflightSetterOnly(L1_SPLITTER, makeAddr("newL1Recipient"), NOMINEE, UNICHAIN_SYSTEM_CONFIG_OWNER_SAFE);
    }
}
