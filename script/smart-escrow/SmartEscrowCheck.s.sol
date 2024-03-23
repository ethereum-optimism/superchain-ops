// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

interface GnosisSafeL2 {
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
}

interface SmartEscrow {
    function BENEFACTOR_OWNER_ROLE() external view returns (bytes32);
    function BENEFICIARY_OWNER_ROLE() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function OP_TOKEN() external view returns (address);
    function TERMINATOR_ROLE() external view returns (bytes32);
    function benefactor() external view returns (address);
    function beneficiary() external view returns (address);
    function defaultAdmin() external view returns (address);
    function end() external view returns (uint256);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function initialTokens() external view returns (uint256);
    function owner() external view returns (address);
    function start() external view returns (uint256);
    function terminate() external;
    function vestingEventTokens() external view returns (uint256);
    function vestingPeriod() external view returns (uint256);
}

/// @title SmartEscrowCheck
/// @notice https://optimistic.etherscan.io/address/0x143F5773CFE5613ca94196d557c889134F47CB77
///         Ensure SmartEscrow is configured correctly
contract SmartEscrowCheck is Script {
  SmartEscrow constant SMART_ESCROW = SmartEscrow(0x143F5773CFE5613ca94196d557c889134F47CB77);

  function run() public view {
    require(block.chainid == 10, "Only OP Mainnet");

    // OP Token is configured correctly
    require(SMART_ESCROW.OP_TOKEN() == 0x4200000000000000000000000000000000000042);

    // 2 of 2 multisig
    require(SMART_ESCROW.owner() == 0x0a7361e734cf3f0394B0FC4a45C74E7a4Ec70940);
    require(SMART_ESCROW.defaultAdmin() == 0x0a7361e734cf3f0394B0FC4a45C74E7a4Ec70940);
    GnosisSafeL2 owner = GnosisSafeL2(SMART_ESCROW.owner());

    address[] memory owners = owner.getOwners();
    // First owner is optimism multisig
    require(owners[0] == 0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0);
    // Second owner is base multisig
    require(owners[1] == 0x6e1DFd5C1E22A4677663A81D24C6BA03561ef0f6);

    // optimism multisig is benefactor owner
    require(SMART_ESCROW.hasRole(SMART_ESCROW.BENEFACTOR_OWNER_ROLE(), 0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0));

    // base multisig is beneficiary owner
    require(SMART_ESCROW.hasRole(SMART_ESCROW.BENEFICIARY_OWNER_ROLE(), 0x6e1DFd5C1E22A4677663A81D24C6BA03561ef0f6));

    // both optimism and base can terminate
    require(SMART_ESCROW.hasRole(SMART_ESCROW.TERMINATOR_ROLE(), 0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0));
    require(SMART_ESCROW.hasRole(SMART_ESCROW.TERMINATOR_ROLE(), 0x6e1DFd5C1E22A4677663A81D24C6BA03561ef0f6));

    // Benefactor is optimism multisig
    require(SMART_ESCROW.benefactor() == 0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0);

    // Beneficiary is an eoa
    require(SMART_ESCROW.beneficiary() == 0x635Fb974F09B269Bc750bF96338c29cF41430125);

    require(SMART_ESCROW.start() == 1720674000);
    require(SMART_ESCROW.end() == 1878462000);
    require(SMART_ESCROW.vestingPeriod() == 7889400);
    require(SMART_ESCROW.initialTokens() == 17895697000000000000000000);
    require(SMART_ESCROW.vestingEventTokens() == 4473924000000000000000000);
  }
}
