// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {LibString} from "solady/utils/LibString.sol";
import {SuperchainRegistry, VerificationBase} from "script/verification/Verification.s.sol";

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
contract HoloceneSystemConfigUpgrade is SuperchainRegistry, VerificationBase {
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

        if (
            sysCfg.version().eq("2.3.0") || sysCfg.version().eq("2.2.0")
                || sysCfg.version().eq("2.2.0+max-gas-limit-400M")
        ) {
            // Supported initial versions with a getter already
            targetDGF = sysCfg.disputeGameFactory();
        } else if (sysCfg.version().eq("1.12.0")) {
            // Supported initial version with no getter, so we set an empty value
            targetDGF = address(0);
        } else {
            revert("unsupported SystemConfig version");
        }

        _addCodeExceptions();
    }

    /// @notice Public function that must be called by the verification script.
    function checkSystemConfigUpgrade() public view {
        checkTargetVersion();
        checkScalar();
        checkDGF();
        checkGasPayingToken();
        checkBaseSysCfgVars();
    }

    function _addCodeExceptions() internal {
        if (previous.owner.code.length == 0) {
            addCodeException(previous.owner);
        }
        addCodeException(address(uint160(uint256(previous.batcherHash))));
        addCodeException(previous.unsafeBlockSigner);
        addCodeException(previous.batchInbox);
    }

    function getCodeExceptions() public view returns (address[] memory exceptions) {
        return codeExceptions;
    }

    // Checks semver of SystemConfig is correct after the upgrade
    function checkTargetVersion() internal view {
        require(getSysCfgVersion().eq(targetVersion), "system-config-050: targetVersion");
        console.log("confirmed SystemConfig upgraded to version", targetVersion);
    }

    // Checks scalar, basefeeScalar, blobbasefeeScalar are set consistently.
    // The upgrade will modify (via the initialize() method) the storage slots for scalar (pre-existing), basefeeScalar (new) and blobbasefeeScalar (new).
    // checkScalar() reads the variables from the new slot and reencodes them into reecondedScalar (which is a packed version).
    // It then checks that this is equal to the scalar value before the upgrade (previousScalar).
    // In this way, we indirectly prove that the new slots were set correctly (in a way consistent with existing data in the SystemConfig contract).
    function checkScalar() internal view {
        // Check that basefeeScalar and blobbasefeeScalar are correct by re-encoding them and comparing to the new scalar value.
        uint256 reencodedScalar =
            (uint256(0x01) << 248) | (uint256(sysCfg.blobbasefeeScalar()) << 32) | sysCfg.basefeeScalar();
        console.log(
            "checking baseFeeScalar and blobbaseFeeScalar reencoded to scalar (respectively):",
            sysCfg.basefeeScalar(),
            sysCfg.blobbasefeeScalar(),
            reencodedScalar
        );
        uint256 newScalar = sysCfg.scalar();
        require(newScalar == reencodedScalar, "scalar-105");

        // Next, we check that the scalar itself was migrated properly
        uint8 previousScalarEncodingVersion = uint8(previousScalar >> 248);
        uint8 newScalarEncodingVersion = uint8(newScalar >> 248);

        if (
            // If the scalar version (i.e. the most significant bit of the scalar)
            // is 1, we expect it to be unchanged during the upgrade.
            previousScalarEncodingVersion == 1
        ) {
            require(reencodedScalar == previousScalar, "scalar-100 scalar mismatch");
        } else {
            // Otherwise, if the scalar version is 0,
            // the blobbasefeeScalar is implicitly 0 and
            // the upgrade will migrate the scalar version to 1 and preserve
            // everything else.
            // See https://specs.optimism.io/protocol/system-config.html?highlight=ecotone%20scalar#ecotone-scalar-overhead-uint256uint256-change
            require(previousScalarEncodingVersion == 0, "scalar-101 previous scalar version != 0 or 1");
            require(newScalarEncodingVersion == 1, "scalar-102 reenconded scalar version != 1");
            require(sysCfg.blobbasefeeScalar() == uint32(0), "scalar-103 blobbasefeeScalar !=0");

            // Sanity check the scalar "padding" is zero for legacy encodings (see spec)
            uint256 mask = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffff00000000;
            require((previousScalar & mask) == uint256(0), "scalar-105 previous scalar padding != 0");

            // The scalars should match if we add the new scalar version byte to the previous scalar.
            require(reencodedScalar == previousScalar + (uint256(0x01) << 248), "scalar-106 scalar mismatch");
        }
    }

    // Checks the disputeGameFactory address is set correctly after the upgrade
    function checkDGF() internal view {
        require(sysCfg.disputeGameFactory() == targetDGF, "scalar-107");
    }

    // Checks gasPayingToken and its decimals are set correctly after the upgrade
    function checkGasPayingToken() internal view {
        (address t, uint8 d) = sysCfg.gasPayingToken();
        require(t == targetGasPayingToken, "scalar-108");
        require(d == targetDecimals, "scalar-109");
    }

    // Checks the remaining storage variables are unchanged after the upgrade
    function checkBaseSysCfgVars() internal view {
        // Check remaining storage variables didn't change
        require(keccak256(abi.encode(getBaseSysCfgVars())) == keccak256(abi.encode(previous)), "system-config-110");
    }

    // Reads the semantic version of the SystemConfig contract
    function getSysCfgVersion() internal view returns (string memory) {
        return sysCfg.version();
    }

    // Reads the base storage variables of the SystemConfig contract
    // (the ones which are common to all versions and should not change during the upgrade)
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

interface IResourceMetering {
    struct ResourceConfig {
        uint32 maxResourceLimit;
        uint8 elasticityMultiplier;
        uint8 baseFeeMaxChangeDenominator;
        uint32 minimumBaseFee;
        uint32 systemTxMaxGas;
        uint128 maximumBaseFee;
    }
}

interface ISystemConfig {
    struct Addresses {
        address l1CrossDomainMessenger;
        address l1ERC721Bridge;
        address l1StandardBridge;
        address disputeGameFactory;
        address optimismPortal;
        address optimismMintableERC20Factory;
        address gasPayingToken;
    }

    function BATCH_INBOX_SLOT() external view returns (bytes32);
    function DISPUTE_GAME_FACTORY_SLOT() external view returns (bytes32);
    function L1_CROSS_DOMAIN_MESSENGER_SLOT() external view returns (bytes32);
    function L1_ERC_721_BRIDGE_SLOT() external view returns (bytes32);
    function L1_STANDARD_BRIDGE_SLOT() external view returns (bytes32);
    function OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT() external view returns (bytes32);
    function OPTIMISM_PORTAL_SLOT() external view returns (bytes32);
    function START_BLOCK_SLOT() external view returns (bytes32);
    function UNSAFE_BLOCK_SIGNER_SLOT() external view returns (bytes32);
    function VERSION() external view returns (uint256);
    function basefeeScalar() external view returns (uint32);
    function batchInbox() external view returns (address addr_);
    function batcherHash() external view returns (bytes32);
    function blobbasefeeScalar() external view returns (uint32);
    function disputeGameFactory() external view returns (address addr_);
    function gasLimit() external view returns (uint64);
    function eip1559Denominator() external view returns (uint32);
    function eip1559Elasticity() external view returns (uint32);
    function gasPayingToken() external view returns (address addr_, uint8 decimals_);
    function gasPayingTokenName() external view returns (string memory name_);
    function gasPayingTokenSymbol() external view returns (string memory symbol_);
    function initialize(
        address _owner,
        uint32 _basefeeScalar,
        uint32 _blobbasefeeScalar,
        bytes32 _batcherHash,
        uint64 _gasLimit,
        address _unsafeBlockSigner,
        IResourceMetering.ResourceConfig memory _config,
        address _batchInbox,
        Addresses memory _addresses
    ) external;
    function isCustomGasToken() external view returns (bool);
    function l1CrossDomainMessenger() external view returns (address addr_);
    function l1ERC721Bridge() external view returns (address addr_);
    function l1StandardBridge() external view returns (address addr_);
    function maximumGasLimit() external pure returns (uint64);
    function minimumGasLimit() external view returns (uint64);
    function optimismMintableERC20Factory() external view returns (address addr_);
    function optimismPortal() external view returns (address addr_);
    function overhead() external view returns (uint256);
    function owner() external view returns (address);
    function renounceOwnership() external;
    function resourceConfig() external view returns (IResourceMetering.ResourceConfig memory);
    function scalar() external view returns (uint256);
    function setBatcherHash(bytes32 _batcherHash) external;
    function setGasConfig(uint256 _overhead, uint256 _scalar) external;
    function setGasConfigEcotone(uint32 _basefeeScalar, uint32 _blobbasefeeScalar) external;
    function setGasLimit(uint64 _gasLimit) external;
    function setUnsafeBlockSigner(address _unsafeBlockSigner) external;
    function setEIP1559Params(uint32 _denominator, uint32 _elasticity) external;
    function startBlock() external view returns (uint256 startBlock_);
    function transferOwnership(address newOwner) external; // nosemgrep
    function unsafeBlockSigner() external view returns (address addr_);
    function version() external pure returns (string memory);
}
