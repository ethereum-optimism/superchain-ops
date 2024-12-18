// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {ISystemConfig} from "./ISystemConfig.sol";
import {IResourceMetering} from "./IResourceMetering.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {NestedMultisigBuilder} from "@base-contracts/script/universal/NestedMultisigBuilder.sol";

contract SystemConfigUpgrade is SuperchainRegistry {
    using LibString for string;

    struct SysCfgVars {
        address owner;
        uint256 scalar;
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
    SysCfgVars expected;

    constructor(string memory l1ChainName, string memory l2ChainName, string memory release)
        SuperchainRegistry(l1ChainName, l2ChainName, release)
    {
        systemConfigAddress = proxies.SystemConfig;
        expected = getSysCfgVars(); // Set this before the tx is executed.
    }

    function getSysCfgVars() internal view returns (SysCfgVars memory) {
        ISystemConfig sysCfg = ISystemConfig(proxies.SystemConfig);

        (address gasPayingToken,) = sysCfg.gasPayingToken();

        return SysCfgVars({
            owner: sysCfg.owner(),
            scalar: sysCfg.scalar(),
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
    function checkSystemConfigUpgrade() public view {
        SysCfgVars memory got = getSysCfgVars();
        require(keccak256(abi.encode(got)) == keccak256(abi.encode(expected)), "system-config-100");
    }
}
