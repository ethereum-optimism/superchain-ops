// SPDX-License-Identifier: MIT
import {SimpleTaskBase} from "src/tasks/types/SimpleTaskBase.sol";

interface ISaferSafes {
    struct ModuleConfig {                                                       
          uint256 livenessResponsePeriod;                                         
          address fallbackOwner;                                                  
      }                                                                           
            

    function enableModule(address _module) external;
    function setGuard(address _guard) external;
    function configureTimelockGuard(uint256 _timelockDelay) external;
    function configureLivenessModule(ModuleConfig memory _moduleConfig) external;
    function version() external view returns (string memory);
}

interface IMultisig {
    function version() external view returns (string memory);
}

contract MigrateToLiveness2 is SimpleTaskBase {

    address public saferSafes;
    address public multisig;

    uint256 public timelockDelay;
    uint256 public livenessResponsePeriod;
    address public fallbackOwner;

    function _taskStorageWrites() internal pure override returns (string[] memory) {
        return ["SaferSafes", "Multisig", "FallbackOwner"];
    }

    function _taskStorageReads() internal pure override returns (string[] memory) {
        return ["SaferSafes"];
    }

    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);
    
        saferSafes = tomlContent.readAddress(".addresses.saferSafes");
        multisig = tomlContent.readAddress(".addresses.safe");

        livenessResponsePeriod = tomlContent.readUint256("livenessModule.livenessResponsePeriod");
        fallbackOwner = tomlContent.readAddress("livenessModule.fallbackOwner");

        /*
            !!!! Add addresses of current guard and module to be removed here !!!!
            ModuleToRemove
            GuardToRemove
        */

        require(address(saferSafes).code.length > 0, "SaferSafes does not have code");
        require(address(multisig).code.length > 0, "Multisig does not have code");
        require(IMultisig(multisig).version() == "1.4.1", "Incorrect Safe version");
        require(fallbackOwner != address(0), "Incorrect fallback owner");
        require(fallbackOwner.code.length > 0, "Fallback owner does not have code");
    }

    function _build(address) internal override {

        /*  
            !!!! Add logic to remove the current guard and modules to be removed here !!!!

            if moduleToRemove != 0:
                look for prev_module and call disableModule

            if gurardToRemove != 0:
                setGuard(address(0))
        */

        ModuleConfig memory moduleConfig = ModuleConfig({
            livenessResponsePeriod: livenessResponsePeriod,
            fallbackOwner: fallbackOwner
        });

        // delegate call enableModule(saferSafes)
        ISaferSafes(saferSafes).configureLivenessModule(moduleConfig);
    }

    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal pure override {
        require(false, "TODO: Implement with the correct validation logic.");
    }
}