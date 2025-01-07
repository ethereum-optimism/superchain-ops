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
    SysCfgVars previous;

    constructor(string memory _l1ChainName, string memory _l2ChainName, string memory _release)
        SuperchainRegistry(_l1ChainName, _l2ChainName, _release)
    {
        systemConfigAddress = proxies.SystemConfig;
        previous = getSysCfgVars(); // Set this before the tx is executed.
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
    function checkSystemConfigUpgrade() public view virtual {
        SysCfgVars memory got = getSysCfgVars();
        require(keccak256(abi.encode(got)) == keccak256(abi.encode(previous)), "system-config-100");
    }

    function getCodeExceptions() public view returns (address[] memory) {
        address[] memory exceptions = new address[](4);
        exceptions[0] = previous.owner; // NOTE this can be removed for mainnet
        exceptions[1] = address(uint160(uint256((previous.batcherHash))));
        exceptions[2] = previous.unsafeBlockSigner;
        exceptions[3] = previous.batchInbox;
        return exceptions;
    }
}
