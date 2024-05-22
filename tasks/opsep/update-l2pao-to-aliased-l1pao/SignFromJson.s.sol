// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Constants, ResourceMetering} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {L1StandardBridge} from "@eth-optimism-bedrock/src/L1/L1StandardBridge.sol";
import {L2OutputOracle} from "@eth-optimism-bedrock/src/L1/L2OutputOracle.sol";
import {ProtocolVersion, ProtocolVersions} from "@eth-optimism-bedrock/src/L1/ProtocolVersions.sol";
import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
import {OptimismPortal} from "@eth-optimism-bedrock/src/L1/OptimismPortal.sol";
import {L1CrossDomainMessenger} from "@eth-optimism-bedrock/src/L1/L1CrossDomainMessenger.sol";
import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";
import {L1ERC721Bridge} from "@eth-optimism-bedrock/src/L1/L1ERC721Bridge.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

// Interface used to read various data from contracts. This is an aggregation of methods from
// various protocol contracts for simplicity, and does not map to the full ABI of any single contract.
interface IFetcher {
    function overhead() external returns (uint256); // SystemConfig
    function scalar() external returns (uint256); // SystemConfig
    function guardian() external returns (address); // SuperchainConfig
    function L2_BLOCK_TIME() external returns (uint256); // L2OutputOracle
    function SUBMISSION_INTERVAL() external returns (uint256); // L2OutputOracle
    function FINALIZATION_PERIOD_SECONDS() external returns (uint256); // L2OutputOracle
    function startingTimestamp() external returns (uint256); // L2OutputOracle
    function startingBlockNumber() external returns (uint256); // L2OutputOracle
    function owner() external returns (address); // ProtocolVersions
    function required() external returns (uint256); // ProtocolVersions
    function recommended() external returns (uint256); // ProtocolVersions
}

interface IProxyAdmin {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe l2paoSafe = GnosisSafe(payable(0xb41890910b05dCba3d3dEF19B27E886C4Ab406EB));
    address constant l2PaoSafeEOA = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301;

    // Contracts we need to check, which are not in the superchain registry
    IProxyAdmin l2pa = IProxyAdmin(0x4200000000000000000000000000000000000018);
    // Aliased L1PAO
    address constant aliasedL1PAO = 0x2FC3ffc903729a0f03966b917003800B145F67F3;
    address constant unaliasedL1PAO = 0x1Eb2fFc903729a0F03966B917003800b145F56E2;
    uint160 private constant ALIASING_OFFSET = uint160(0x1111000000000000000000000000000000001111);

    // Known EOAs to exclude from safety checks.
    address constant l2OutputOracleProposer = 0x49277EE36A024120Ee218127354c4a3591dc90A9; // cast call $L2OO "PROPOSER()(address)"
    address constant l2OutputOracleChallenger = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant systemConfigOwner = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant batchSenderAddress = 0x8F23BB38F531600e5d8FDDaAEC41F13FaB46E98c; // In registry genesis-system-configs
    address constant p2pSequencerAddress = 0x57CACBB0d30b01eb2462e5dC940c161aff3230D3; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address constant batchInboxAddress = 0xff00000000000000000000000000000011155420; // In registry yaml.
    
    Types.ContractSet proxies;

    // This gives the initial fork, so we can use it to switch back after fetching data.
    uint256 initialFork;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();

        // Fetch variables that are not expected to change from an older block.
        initialFork = vm.activeFork();
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), block.number - 10); // Arbitrary recent block.

        require(unaliasedL1PAO == undoL1ToL2Alias(aliasedL1PAO), "setUp-100");
        require(aliasedL1PAO == applyL1ToL2Alias(unaliasedL1PAO), "setUp-101");

        vm.selectFork(initialFork);
    }

    function checkL2PAOSafe() internal view {
        console.log("Running assertions on the L2PAO Safe");

        address[] memory l2paoSafeOwners = l2paoSafe.getOwners();
        require(l2paoSafeOwners.length == 1, "checkL2PAOSafe-100");
        require(l2paoSafeOwners[0] == l2PaoSafeEOA, "checkL2PAOSafe-101"); // stays the same
        require(l2paoSafe.getThreshold() == 1, "checkL2PAOSafe-102");
    }

    function checkL2PA() internal view {
        console.log("Running assertions on the L2PA");

        address l2paOwner = l2pa.owner();
        require(l2paOwner == aliasedL1PAO, "checkL2PA-200");
        require(unaliasedL1PAO == undoL1ToL2Alias(l2paOwner), "checkL2PA-201");
    }

    function applyL1ToL2Alias(address l1Address) public pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + ALIASING_OFFSET);
        }
    }

    function undoL1ToL2Alias(address l2Address) public pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - ALIASING_OFFSET);
        }
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkL2PAOSafe();
        checkL2PA();

        console.log("All assertions passed!");
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory shouldHaveCodeExceptions = new address[](7);

        shouldHaveCodeExceptions[0] = l2OutputOracleProposer;
        shouldHaveCodeExceptions[1] = l2OutputOracleChallenger;
        shouldHaveCodeExceptions[2] = systemConfigOwner;
        shouldHaveCodeExceptions[3] = batchSenderAddress;
        shouldHaveCodeExceptions[4] = p2pSequencerAddress;
        shouldHaveCodeExceptions[5] = batchInboxAddress;
        shouldHaveCodeExceptions[6] = aliasedL1PAO; // aliased L1PAO on op-sepolia doesn't have any code.

        return shouldHaveCodeExceptions;
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/extra/addresses/sepolia/op.json
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory addressesJson;

        // Read addresses json
        string memory path = string.concat(
            "/lib/superchain-registry/superchain/extra/addresses/", l1ChainName, "/", l2ChainName, ".json"
        );
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        _proxies.L1CrossDomainMessenger = stdJson.readAddress(addressesJson, "$.L1CrossDomainMessengerProxy");
        _proxies.L1StandardBridge = stdJson.readAddress(addressesJson, "$.L1StandardBridgeProxy");
        _proxies.L2OutputOracle = stdJson.readAddress(addressesJson, "$.L2OutputOracleProxy");
        _proxies.OptimismMintableERC20Factory =
            stdJson.readAddress(addressesJson, "$.OptimismMintableERC20FactoryProxy");
        _proxies.OptimismPortal = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
        _proxies.OptimismPortal2 = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
        _proxies.SystemConfig = stdJson.readAddress(addressesJson, "$.SystemConfigProxy");
        _proxies.L1ERC721Bridge = stdJson.readAddress(addressesJson, "$.L1ERC721BridgeProxy");

        // Read superchain.yaml
        string[] memory inputs = new string[](4);
        inputs[0] = "yq";
        inputs[1] = "-o";
        inputs[2] = "json";
        inputs[3] = string.concat("lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.yaml");

        addressesJson = string(vm.ffi(inputs));

        _proxies.ProtocolVersions = stdJson.readAddress(addressesJson, "$.protocol_versions_addr");
        _proxies.SuperchainConfig = stdJson.readAddress(addressesJson, "$.superchain_config_addr");
    }
}
