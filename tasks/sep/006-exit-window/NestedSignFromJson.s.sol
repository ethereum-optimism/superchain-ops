// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {SuperchainConfig} from "@eth-optimism-bedrock/src/L1/SuperchainConfig.sol";
import {IGnosisSafe, Enum} from "@eth-optimism-bedrock/scripts/interfaces/IGnosisSafe.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson {
    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#system-config-owner
    address constant finalSystemOwner = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#guardian
    address constant superchainConfigGuardian = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L12
    address constant p2pSequencerAddress = 0xAAAA45d9549EDA09E70937013520214382Ffc4A2;

    /// @notice Verify against https://github.com/ethereum-optimism/optimism/blob/e2307008d8bc3f125f97814243cc72e8b47c117e/packages/contracts-bedrock/deploy-config/mainnet.json#L13
    address constant batchInboxAddress = 0xFF00000000000000000000000000000000000010;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#batcher
    address constant batchSenderAddress = 0x6887246668a3b87F54DeB3b94Ba47a6f63F32985;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#proposer
    address constant l2OutputOracleProposer = 0x473300df21D047806A082244b417f96b32f13A33;

    /// @notice Verify against https://docs.optimism.io/chain/security/privileged-roles#challenger
    address constant l2OutputOracleChallenger = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function _getCodeExceptions() internal view returns (address[] memory) {
        address[] memory shouldHaveCodeExceptions = new address[](4);

        shouldHaveCodeExceptions[0] = l2OutputOracleProposer;
        shouldHaveCodeExceptions[1] = batchSenderAddress;
        shouldHaveCodeExceptions[2] = p2pSequencerAddress;
        shouldHaveCodeExceptions[3] = batchInboxAddress;

        return shouldHaveCodeExceptions;
    }

    /// @notice Asserts that the SuperchainConfig is setup correctly
    function checkSuperchainConfig() internal view {
        console.log("Running chain assertions on the SuperchainConfig");

        require(proxies.SuperchainConfig.code.length != 0, "7100");
        require(EIP1967Helper.getImplementation(proxies.SuperchainConfig).code.length != 0, "7101");

        SuperchainConfig superchainConfigToCheck = SuperchainConfig(proxies.SuperchainConfig);

        require(superchainConfigToCheck.guardian() == superchainConfigGuardian, "7200");
        require(superchainConfigToCheck.guardian().code.length != 0, "7250");
        require(superchainConfigToCheck.paused() == false, "7300");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheckWithSim() internal override {
        console.log("Running the simulation locally");
        vm.startStateDiffRecording();
        runSim();
        Vm.AccountAccess[] memory accountAccesses = vm.stopAndReturnStateDiff();

        console.log("Running post-deploy assertions");
        checkStateDiff(accountAccesses, _getCodeExceptions());

        checkSuperchainConfig();
        console.log("All assertions passed!");
    }

    function _postCheckExecute(Vm.AccountAccess[] memory accountAccesses) internal view override {
        // Same assertions as _postCheckWithSim, and just does not simulate anything since
        // the transactions were broadcasted.
        console.log("Running post-deploy assertions");
        checkStateDiff(accountAccesses, _getCodeExceptions());

        checkSuperchainConfig();
        console.log("All assertions passed!");
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/extra/addresses/sepolia/op.json
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory addressesJson;

        // Read addresses json
        try vm.readFile(
            string.concat(vm.projectRoot(), "/lib/superchain-registry/superchain/extra/addresses/sepolia/op.json")
        ) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert("Failed to read lib/superchain-registry/superchain/extra/addresses/sepolia/op.json");
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
        inputs[3] = "lib/superchain-registry/superchain/configs/mainnet/superchain.yaml";

        addressesJson = string(vm.ffi(inputs));

        _proxies.ProtocolVersions = stdJson.readAddress(addressesJson, "$.protocol_versions_addr");
        _proxies.SuperchainConfig = stdJson.readAddress(addressesJson, "$.superchain_config_addr");
    }

    function runSim() internal {
        // The logic for computing state overrides and calldata was copied from

        // `NestedMultisigBuilder._simulateForSigner`. Then we add the nested `for` loop to
        // `vm.store` the state overrides and the `vm.prank` section to simulate the execution.
        require(globalSignerSafe != address(0), "Signer safe not set");
        address _safe = _ownerSafe();
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        IGnosisSafe signerSafe_ = IGnosisSafe(payable(globalSignerSafe));

        // Apply state overrides.
        SimulationStateOverride[] memory stateOverrides = new SimulationStateOverride[](2);
        stateOverrides[0] = overrideSafeThreshold(_safe);
        stateOverrides[1] = overrideSafeThresholdAndOwner(globalSignerSafe, address(multicall));

        for (uint256 i; i < stateOverrides.length; i++) {
            SimulationStateOverride memory stateOverride = stateOverrides[i];
            SimulationStorageOverride[] memory storageOverrides = stateOverride.overrides;
            for (uint256 j; j < storageOverrides.length; j++) {
                SimulationStorageOverride memory storageOverride = storageOverrides[j];
                vm.store(stateOverride.contractAddress, storageOverride.key, storageOverride.value);
            }
        }

        // Build the call.
        IMulticall3.Call3[] memory nestedCalls = _buildCalls();
        bytes memory data = abi.encodeCall(IMulticall3.aggregate3, (nestedCalls));
        bytes32 hash = _getTransactionHash(_safe, data);

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](2);
        bytes memory approveHashData = abi.encodeCall(
            IMulticall3.aggregate3,
            (
                toArray(
                    IMulticall3.Call3({
                        target: _safe,
                        allowFailure: false,
                        callData: abi.encodeCall(safe.approveHash, (hash))
                    })
                )
            )
        );
        bytes memory approveHashExec = abi.encodeCall(
            signerSafe_.execTransaction,
            (
                address(multicall),
                0,
                approveHashData,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                prevalidatedSignature(address(multicall))
            )
        );
        calls[0] = IMulticall3.Call3({target: globalSignerSafe, allowFailure: false, callData: approveHashExec});

        // simulate the final state changes tx, so that signer can verify the final results
        bytes memory finalExec = abi.encodeCall(
            safe.execTransaction,
            (
                address(multicall),
                0,
                data,
                Enum.Operation.DelegateCall,
                0,
                0,
                0,
                address(0),
                payable(address(0)),
                prevalidatedSignature(globalSignerSafe)
            )
        );
        calls[1] = IMulticall3.Call3({target: _safe, allowFailure: false, callData: finalExec});

        bytes memory finalData = abi.encodeCall(IMulticall3.aggregate3, (calls));
        vm.prank(msg.sender);
        (bool ok, bytes memory returnData) = address(multicall).call(finalData);
        require(ok, string.concat("Foundry simulation failed: ", vm.toString(returnData)));
    }
}
