// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Types} from "@eth-optimism-bedrock/scripts/libraries/Types.sol";
import {CommonBase} from "forge-std/Base.sol";
import {stdToml} from "forge-std/StdToml.sol";

// TODO(#427): Proposing to just merge this contract into JsonTxBuilderBase.
contract VerificationBase {
    address[] public allowedStorageAccess;
    address[] public codeExceptions;

    function addAllowedStorageAccess(address addr) internal {
        allowedStorageAccess.push(addr);
    }

    function addCodeException(address addr) internal {
        codeExceptions.push(addr);
    }

    function addCodeExceptions(address[] memory addrs) internal {
        for (uint256 i = 0; i < addrs.length; i++) {
            addCodeException(addrs[i]);
        }
    }
}

contract SuperchainRegistry is CommonBase {
    using LibString for string;

    struct StandardVersion {
        string version;
    }

    struct StandardVersionImpl {
        string version;
        address implementation;
    }

    struct StandardVersionAddr {
        string version;
        address Address;
    }

    struct StandardVersions {
        StandardVersionImpl SystemConfig;
        StandardVersion FaultDisputeGame;
        StandardVersion PermissionedDisputeGame;
        StandardVersionAddr MIPS;
        StandardVersionImpl OptimismPortal;
        StandardVersion AnchorStateRegistry;
        StandardVersionImpl DelayedWETH;
        StandardVersionImpl DisputeGameFactory;
        StandardVersionAddr PreimageOracle;
        StandardVersionImpl L1CrossDomainMessenger;
        StandardVersionImpl L1ERC721Bridge;
        StandardVersionImpl L1StandardBridge;
        StandardVersionImpl OptimismMintableERC20Factory;
    }

    struct ChainConfig {
        uint256 chainId;
        address systemConfigOwner;
        address unsafeBlockSigner;
        address batchSubmitter;
        address batchInbox;
        address proposer;
        address challenger;
    }

    string l1ChainName; // e.g. "mainnet";
    string l2ChainName; // e.g. "op";
    string opContractsReleaseQ; // prefixed & quoted, e.g. '"op-contracts/v1.8.0"';

    address addressManager;
    Types.ContractSet proxies;
    StandardVersions standardVersions;
    ChainConfig chainConfig;

    constructor(string memory _l1ChainName, string memory _l2ChainName, string memory _opContractsRelease) {
        l1ChainName = _l1ChainName;
        l2ChainName = _l2ChainName;
        opContractsReleaseQ = string.concat("\"op-contracts/", _opContractsRelease, "\"");
        _readSuperchainConfig();
        _readStandardVersions();
        _applyOverrides();
    }

    /// @notice Reads the contract addresses from the superchain registry.
    function _readSuperchainConfig() internal {
        string memory toml;
        string memory path =
            string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            toml = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        proxies.SuperchainConfig = stdToml.readAddress(toml, "$.superchain_config_addr");
        proxies.ProtocolVersions = stdToml.readAddress(toml, "$.protocol_versions_addr");

        path = string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/", l2ChainName, ".toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            toml = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        proxies.OptimismPortal = stdToml.readAddress(toml, "$.addresses.OptimismPortalProxy");
        proxies.L1CrossDomainMessenger = stdToml.readAddress(toml, "$.addresses.L1CrossDomainMessengerProxy");
        proxies.L1StandardBridge = stdToml.readAddress(toml, "$.addresses.L1StandardBridgeProxy");
        proxies.SystemConfig = stdToml.readAddress(toml, "$.addresses.SystemConfigProxy");
        proxies.L1ERC721Bridge = stdToml.readAddress(toml, "$.addresses.L1ERC721BridgeProxy");
        proxies.OptimismMintableERC20Factory =
            stdToml.readAddress(toml, "$.addresses.OptimismMintableERC20FactoryProxy");

        // Not all chains have the following values specified in the registry, so we will
        // set them to the zero address if they are not found.
        proxies.AnchorStateRegistry = stdToml.readAddressOr(toml, "$.addresses.AnchorStateRegistryProxy", address(0));
        proxies.DisputeGameFactory = stdToml.readAddressOr(toml, "$.addresses.DisputeGameFactoryProxy", address(0));

        // Not part of the standard proxy set so we set it as a separate variable.
        addressManager = stdToml.readAddress(toml, "$.addresses.AddressManager");

        chainConfig.chainId = stdToml.readUint(toml, "$.chain_id");
        chainConfig.systemConfigOwner = stdToml.readAddress(toml, "$.roles.SystemConfigOwner");
        chainConfig.unsafeBlockSigner = stdToml.readAddressOr(toml, "$.roles.UnsafeBlockSigner", address(0)); // Not present on all chains, note .readAddressOr
        chainConfig.batchSubmitter = stdToml.readAddress(toml, "$.roles.BatchSubmitter");
        chainConfig.batchInbox = stdToml.readAddress(toml, "$.batch_inbox_addr");
        chainConfig.proposer = stdToml.readAddress(toml, "$.roles.Proposer");
        chainConfig.challenger = stdToml.readAddress(toml, "$.roles.Challenger");
    }

    function _readStandardVersions() internal {
        string memory toml;
        string memory path =
            string.concat("/lib/superchain-registry/validation/standard/standard-versions-", l1ChainName, ".toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            toml = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        toml = toml.replace(opContractsReleaseQ, "RELEASE");

        standardVersions.SystemConfig = _parseStandardVersionImpl(toml, "system_config");
        standardVersions.FaultDisputeGame = _parseStandardVersion(toml, "fault_dispute_game");
        standardVersions.PermissionedDisputeGame = _parseStandardVersion(toml, "permissioned_dispute_game");
        standardVersions.MIPS = _parseStandardVersionAddr(toml, "mips");
        standardVersions.OptimismPortal = _parseStandardVersionImpl(toml, "optimism_portal");
        standardVersions.AnchorStateRegistry = _parseStandardVersion(toml, "anchor_state_registry");
        standardVersions.DelayedWETH = _parseStandardVersionImpl(toml, "delayed_weth");
        standardVersions.DisputeGameFactory = _parseStandardVersionImpl(toml, "dispute_game_factory");
        standardVersions.PreimageOracle = _parseStandardVersionAddr(toml, "preimage_oracle");
        standardVersions.L1CrossDomainMessenger = _parseStandardVersionImpl(toml, "l1_cross_domain_messenger");
        standardVersions.L1ERC721Bridge = _parseStandardVersionImpl(toml, "l1_erc721_bridge");
        standardVersions.L1StandardBridge = _parseStandardVersionImpl(toml, "l1_standard_bridge");
        standardVersions.OptimismMintableERC20Factory =
            _parseStandardVersionImpl(toml, "optimism_mintable_erc20_factory");
    }

    function _parseStandardVersionImpl(string memory data, string memory key)
        internal
        pure
        returns (StandardVersionImpl memory sv_)
    {
        sv_.version = stdToml.readString(data, string.concat("$.RELEASE.", key, ".version"));
        sv_.implementation = stdToml.readAddress(data, string.concat("$.RELEASE.", key, ".implementation_address"));
    }

    function _parseStandardVersionAddr(string memory data, string memory key)
        internal
        pure
        returns (StandardVersionAddr memory sv_)
    {
        sv_.version = stdToml.readString(data, string.concat("$.RELEASE.", key, ".version"));
        sv_.Address = stdToml.readAddress(data, string.concat("$.RELEASE.", key, ".address"));
    }

    function _parseStandardVersion(string memory data, string memory key)
        internal
        pure
        returns (StandardVersion memory sv_)
    {
        sv_.version = stdToml.readString(data, string.concat("$.RELEASE.", key, ".version"));
    }

    function _applyOverrides() internal {
        try vm.envAddress("SCR_OVERRIDE_MIPS_ADDRESS") returns (address mips) {
            console.log("SuperchainRegistry: overriding MIPS address to %s", mips);
            standardVersions.MIPS.Address = mips;
        } catch { /* Ignore, no override */ }
        try vm.envString("SCR_OVERRIDE_MIPS_VERSION") returns (string memory ver) {
            console.log("SuperchainRegistry: overriding MIPS version to %s", ver);
            standardVersions.MIPS.version = ver;
        } catch { /* Ignore, no override */ }
    }
}
