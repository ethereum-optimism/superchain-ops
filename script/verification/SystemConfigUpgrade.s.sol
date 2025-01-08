// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";
import {ISystemConfig} from "./ISystemConfig.sol";
import {IResourceMetering} from "./IResourceMetering.sol";
import {console2 as console} from "forge-std/console2.sol";

// SystemConfigUpgrade is a contract that can be used to verify that an upgrade of the SystemConfig contract
// has not changed any of the storage variables that are not expected to change.
// It stores the prior storage variables EXCLUDING:
// - scalar
// - basefeeScalar
// - blobbasefeeScalar
// of the SystemConfig contract at constructor time.
// It exposes a method which allows the verification script to check that the storage variables have not changed.
contract SystemConfigUpgrade is SuperchainRegistry {
    using LibString for string;

    struct SysCfgVars {
        address owner;
        bytes32 batcherHash;
        uint256 gasLimit;
        address unsafeBlockSigner;
        IResourceMetering.ResourceConfig resourceConfig;
        address batchInbox;
        address gasPayingToken;
        address l1CrossDomainMessenger;
        address l1StandardBridge;
        address l1ERC721Bridge;
        address disputeGameFactory;
        address optimismPortal;
        address optimismMintableERC20Factory;
    }

    address public systemConfigAddress;
    SysCfgVars previous;
    string targetVersion;

    constructor(string memory _l1ChainName, string memory _l2ChainName, string memory _release)
        SuperchainRegistry(_l1ChainName, _l2ChainName, _release)
    {
        systemConfigAddress = proxies.SystemConfig;
        targetVersion = standardVersions.SystemConfig.version;
        previous = getSysCfgVars(); // Set this before the tx is executed.
    }

    function getSysCfgVersion() internal view returns (string memory) {
        ISystemConfig sysCfg = ISystemConfig(proxies.SystemConfig);
        return sysCfg.version();
    }

    function getSysCfgVars() internal view returns (SysCfgVars memory) {
        ISystemConfig sysCfg = ISystemConfig(proxies.SystemConfig);

        (address gasPayingToken,) = sysCfg.gasPayingToken();

        return SysCfgVars({
            owner: sysCfg.owner(),
            batcherHash: sysCfg.batcherHash(),
            gasLimit: sysCfg.gasLimit(),
            unsafeBlockSigner: sysCfg.unsafeBlockSigner(),
            resourceConfig: sysCfg.resourceConfig(),
            batchInbox: sysCfg.batchInbox(),
            gasPayingToken: gasPayingToken,
            l1CrossDomainMessenger: sysCfg.l1CrossDomainMessenger(),
            l1StandardBridge: sysCfg.l1StandardBridge(),
            l1ERC721Bridge: sysCfg.l1ERC721Bridge(),
            disputeGameFactory: sysCfg.disputeGameFactory(),
            optimismPortal: sysCfg.optimismPortal(),
            optimismMintableERC20Factory: sysCfg.optimismMintableERC20Factory()
        });
    }

    /// @notice Public function that must be called by the verification script.
    function checkSystemConfigUpgrade() public view virtual {
        require(
            keccak256(abi.encode(getSysCfgVersion())) == keccak256(abi.encode(targetVersion)),
            "system-config-050: targetVersion"
        );
        console.log("confirmed SystemConfig upgraded to version", targetVersion);
        SysCfgVars memory got = getSysCfgVars();
        require(keccak256(abi.encode(got)) == keccak256(abi.encode(previous)), "system-config-100");
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
}
