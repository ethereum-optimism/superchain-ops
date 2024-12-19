// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {LibString} from "solady/utils/LibString.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
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
    }

    string l1ChainName; // e.g. "mainnet";
    string l2ChainName; // e.g. "op";
    string opContractsReleaseQ; // prefixed & quoted, e.g. '"op-contracts/v1.8.0"';

    Types.ContractSet proxies;
    StandardVersions standardVersions;
    ChainConfig chainConfig;

    constructor(string memory _l1ChainName, string memory _l2ChainName, string memory _opContractsRelease) {
        l1ChainName = _l1ChainName;
        l2ChainName = _l2ChainName;
        opContractsReleaseQ = string.concat("\"op-contracts/", _opContractsRelease, "\"");
        _readSuperchainConfig();
        _readStandardVersions();
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
        proxies.AnchorStateRegistry = stdToml.readAddress(toml, "$.addresses.AnchorStateRegistryProxy");
        proxies.DisputeGameFactory = stdToml.readAddress(toml, "$.addresses.DisputeGameFactoryProxy");

        chainConfig.chainId = stdToml.readUint(toml, "$.chain_id");
        chainConfig.systemConfigOwner = stdToml.readAddress(toml, "$.addresses.SystemConfigOwner");
        chainConfig.unsafeBlockSigner = stdToml.readAddress(toml, "$.addresses.UnsafeBlockSigner");
        chainConfig.batchSubmitter = stdToml.readAddress(toml, "$.addresses.BatchSubmitter");
        chainConfig.batchInbox = stdToml.readAddress(toml, "$.batch_inbox_addr");
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
}
