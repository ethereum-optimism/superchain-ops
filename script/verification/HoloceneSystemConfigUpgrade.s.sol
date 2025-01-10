// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ISystemConfig} from "./ISystemConfig.sol";
import {IResourceMetering} from "./IResourceMetering.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";

// HoloceneSystemConfigUpgrade is a contract that can be used to verify the Holocene upgrade of the SystemConfig contract.
// The upgrade paths supported are:
// 1.12.0 -> 2.3.0
//  2.2.0 -> 2.3.0
//  2.3.0 -> 2.3.0 (this case covers where the SystemConfig contract is already at the target version but was upgraded incorrectly)
// The verification checks that the following storage values are properly modified if appropriate:
// - scalar (may be migrated to a different encoding version)
// - basefeeScalar (new storage variable, needs to be set in a way which is consistent with the previous scalar)
// - blobbasefeeScalar (new storage variable, needs to be set in a way which is consistent with the previous scalar)
// - gasPayingToken (new storage variable, needs to be set to a magic value representing ETH)
// - disputeGameFactory (does not exist @ 1.12.0, needs to be set to zero address for changes on this upgrade path)
// It also verified that remaining storage variables are unchanged.
contract HoloceneSystemConfigUpgrade is SuperchainRegistry {
    using LibString for string;

    address public systemConfigAddress;
    ISystemConfig sysCfg;

    // Storage variables which exist in the existing and target
    // SystemConfig contract versions irrespective of upgrade path,
    // and which should be preserved:
    struct BaseSysCfgVars {
        address owner;
        bytes32 batcherHash;
        uint256 gasLimit;
        address unsafeBlockSigner;
        IResourceMetering.ResourceConfig resourceConfig;
        address batchInbox;
        address l1CrossDomainMessenger;
        address l1StandardBridge;
        address l1ERC721Bridge;
        address optimismPortal;
        address optimismMintableERC20Factory;
    }

    BaseSysCfgVars previous;

    // Values which may change during the upgrade, depending on the chain::
    uint256 previousScalar;

    // The target value for the DisputeGameFactory address,
    // this getter does not exist in the SystemConfig contract @ 1.12.0:
    address targetDGF;

    // Target values for gasPayingToken and its decimals. This should represent ETH
    // on all upgrade paths:
    address constant targetGasPayingToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint8 constant targetDecimals = 18;

    // The target version of the SystemConfig contract, read from the SCR @ specified release:
    string targetVersion;

    // The constructor caches some information from the Superchain Registry and from the existing SystemConfig contract
    // before the upgrade is executed.
    constructor(string memory _l1ChainName, string memory _l2ChainName, string memory _release)
        SuperchainRegistry(_l1ChainName, _l2ChainName, _release)
    {
        systemConfigAddress = proxies.SystemConfig;
        sysCfg = ISystemConfig(proxies.SystemConfig);

        // cache the values of the SystemConfig contract before the upgrade
        previous = getBaseSysCfgVars();
        previousScalar = sysCfg.scalar();

        // Read target version from SCR @ specified release
        targetVersion = standardVersions.SystemConfig.version;

        if (sysCfg.version().eq("2.3.0")) {
            // Supported initial version
            targetDGF = sysCfg.disputeGameFactory();
        } else if (sysCfg.version().eq("2.2.0")) {
            // Supported initial version
            targetDGF = sysCfg.disputeGameFactory();
        } else if (sysCfg.version().eq("1.12.0")) {
            // Supported initial version
            targetDGF = address(0);
        } else {
            revert("unsupported SystemConfig version");
        }
    }

    /// @notice Public function that must be called by the verification script.
    function checkSystemConfigUpgrade() public view {
        checkTargetVersion();
        checkScalar();
        checkDGF();
        checkGasPayingToken();
        checkBaseSysCfgVars();
    }

    function getCodeExceptions() public view returns (address[] memory exceptions) {
        uint256 len = block.chainid == 1 ? 3 : 4; // Mainnet doesn't need owner exception.
        exceptions = new address[](len);
        uint256 i = 0;
        if (block.chainid != 1) exceptions[i++] = previous.owner;
        exceptions[i++] = address(uint160(uint256((previous.batcherHash))));
        exceptions[i++] = previous.unsafeBlockSigner;
        exceptions[i++] = previous.batchInbox;
    }

    // Checks semver of SystemConfig is correct after the upgrade
    function checkTargetVersion() internal view {
        require(
            keccak256(abi.encode(getSysCfgVersion())) == keccak256(abi.encode(targetVersion)),
            "system-config-050: targetVersion"
        );
        console.log("confirmed SystemConfig upgraded to version", targetVersion);
    }

    // Checks scalar, basefeeScalar, blobbasefeeScalar are set consistently:
    function checkScalar() internal view {
        uint256 reencodedScalar =
            (uint256(0x01) << 248) | (uint256(sysCfg.blobbasefeeScalar()) << 32) | sysCfg.basefeeScalar();
        console.log(
            "checking baseFeeScalar and blobbaseFeeScalar ",
            LibString.toString(sysCfg.basefeeScalar()),
            LibString.toString(sysCfg.blobbasefeeScalar())
        );
        if (
            // If the scalar version (i.e. the most significant bit of the scalar)
            // is 1, we expect it to be unchanged during the upgrade.
            uint8(previousScalar >> 248) == 1
        ) {
            require(reencodedScalar == previousScalar, "scalar-100 scalar mismatch");
        } else {
            // Otherwise, if the scalar version is 0,
            // and the blobbasefeeScalar is 0,
            // the upgrade will migrate the scalar version to 1 and preserve
            // everything else.
            // See https://specs.optimism.io/protocol/system-config.html?highlight=ecotone%20scalar#ecotone-scalar-overhead-uint256uint256-change
            require(previousScalar >> 248 == 0, "scalar-101 previous scalar version != 0 or 1");
            require(reencodedScalar >> 248 == 1, "scalar-102 reenconded scalar version != 1");
            require(sysCfg.blobbasefeeScalar() == uint32(0), "scalar-103 blobbasefeeScalar !=0");
            require(reencodedScalar << 8 == previousScalar << 8, "scalar-104 scalar mismatch");
        }
        // Check that basefeeScalar and blobbasefeeScalar are correct by re-encoding them and comparing to the new scalar value.
        require(sysCfg.scalar() == reencodedScalar, "scalar-105");
    }

    // Checks the disputeGameFactory address is set correctly after the upgrade
    function checkDGF() internal view {
        require(sysCfg.disputeGameFactory() == targetDGF, "scalar-106");
    }

    // Checks gasPayingToken and its decimals are set correctly after the upgrade
    function checkGasPayingToken() internal view {
        (address t, uint8 d) = sysCfg.gasPayingToken();
        require(t == targetGasPayingToken, "scalar-107");
        require(d == targetDecimals, "scalar-108");
    }

    // CHecsk the remaining storage variables are unchanged after the upgrade
    function checkBaseSysCfgVars() internal view {
        // Check remaining storage variables didn't change
        require(keccak256(abi.encode(getBaseSysCfgVars())) == keccak256(abi.encode(previous)), "system-config-100");
    }

    // Reads
    function getSysCfgVersion() internal view returns (string memory) {
        return sysCfg.version();
    }

    function getBaseSysCfgVars() internal view returns (BaseSysCfgVars memory) {
        return BaseSysCfgVars({
            owner: sysCfg.owner(),
            batcherHash: sysCfg.batcherHash(),
            gasLimit: sysCfg.gasLimit(),
            unsafeBlockSigner: sysCfg.unsafeBlockSigner(),
            resourceConfig: sysCfg.resourceConfig(),
            batchInbox: sysCfg.batchInbox(),
            l1CrossDomainMessenger: sysCfg.l1CrossDomainMessenger(),
            l1StandardBridge: sysCfg.l1StandardBridge(),
            l1ERC721Bridge: sysCfg.l1ERC721Bridge(),
            optimismPortal: sysCfg.optimismPortal(),
            optimismMintableERC20Factory: sysCfg.optimismMintableERC20Factory()
        });
    }
}
