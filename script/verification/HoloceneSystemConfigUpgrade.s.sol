// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {LibString} from "solady/utils/LibString.sol";
import {ISystemConfig} from "./ISystemConfig.sol";
import {IResourceMetering} from "./IResourceMetering.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";

// HoloceneSystemConfigUpgrade is a contract that can be used to verify the Holocene upgrade of the SystemConfig contract.
// The upgrade paths supported are 2.2.0 -> 2.3.0 and 1.12.0 -> 2.3.0.
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

    // Values which should not change during the upgrade
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

    uint256 previousScalar;
    address targetDGF;
    string targetVersion;

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
            // Target Version
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

    function checkTargetVersion() internal view {
        require(
            keccak256(abi.encode(getSysCfgVersion())) == keccak256(abi.encode(targetVersion)),
            "system-config-050: targetVersion"
        );
        console.log("confirmed SystemConfig upgraded to version", targetVersion);
    }

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

    function checkDGF() internal view {
        require(sysCfg.disputeGameFactory() == targetDGF, "scalar-106");
    }

    function checkGasPayingToken() internal view {
        // upgrade does not support CGT chains, so we require the gasPayingToken to be ETH
        (address t, uint8 d) = sysCfg.gasPayingToken();
        require(t == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "scalar-107");
        require(d == 18, "scalar-108");
    }

    function checkBaseSysCfgVars() internal view {
        // Check remaining storage variables didn't change
        require(keccak256(abi.encode(getBaseSysCfgVars())) == keccak256(abi.encode(previous)), "system-config-100");
    }

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
