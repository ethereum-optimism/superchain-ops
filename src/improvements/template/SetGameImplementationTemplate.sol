// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {DisputeGameFactory} from "lib/optimism/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol";
import {GameTypes} from "lib/optimism/packages/contracts-bedrock/src/dispute/lib/Types.sol";
import {IDisputeGame} from "lib/optimism/packages/contracts-bedrock/interfaces/dispute/IDisputeGame.sol";

contract SetGameImplementations is L2TaskBase {
    using stdToml for string;

    struct GameImplConfig {
        uint256 chainId;
        address fdgImpl;
        address pdgImpl;
    }

    mapping(uint256 => GameImplConfig) public cfg;

    function safeAddressString() public pure override returns (string memory) {
        return "FoundationOperationsSafe";
    }

    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DisputeGameFactoryProxy";
        return storageWrites;
    }

    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory toml = vm.readFile(taskConfigFilePath);
        GameImplConfig[] memory configs = 
            abi.decode(toml.parseRaw(".gameImpls.configs"), (GameImplConfig[]));
        for (uint256 i = 0; i < configs.length; i++) {
            cfg[configs[i].chainId] = configs[i];
        }
    }

    function _build() internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            GameImplConfig memory c = cfg[chainId];

            address dgf = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);

            if (c.fdgImpl != address(0)) {
                DisputeGameFactory(dgf).setImplementation(GameTypes.CANNON, IDisputeGame(c.fdgImpl));
            }
            if (c.pdgImpl != address(0)) {
                DisputeGameFactory(dgf).setImplementation(GameTypes.PERMISSIONED_CANNON, IDisputeGame(c.pdgImpl));
            }
        }
    }

    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            GameImplConfig memory c = cfg[chainId];

            address dgf = superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId);
            DisputeGameFactory factory = DisputeGameFactory(dgf);

            if (c.fdgImpl != address(0)) {
                assertEq(address(factory.gameImpls(GameTypes.CANNON)), c.fdgImpl);
            }
            if (c.pdgImpl != address(0)) {
                assertEq(address(factory.gameImpls(GameTypes.PERMISSIONED_CANNON)), c.pdgImpl);
            }
        }
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory codeExceptions = new address[](0);
        return codeExceptions;
    }
}
