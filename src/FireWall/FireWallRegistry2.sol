// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IModule} from "./IModule.sol";
import {Test, console} from "forge-std/Test.sol";

contract FireWallRegistry2 {
    mapping(address => ProtectInfo[]) public project_registry;
    mapping(address => address) public managers;
    address[] detect_modules;
    address owner;

    struct ProtectInfo {
        // 函数签名
        bytes4 func_sig;
        // 关键参数位置
        uint8 key_args_index;
        // 启动的模块
        bool[] mod_flag;
    }

    // constructor(address[] memory _detect_modules) {
    //     owner = msg.sender;
    //     detect_modules = _detect_modules;
    // }

    function setManager(address _project, address _manager) external {
        require(msg.sender == owner, "Not the owner");
        managers[_project] = _manager;
    }

    function getManager(address _project) public view returns (address) {
        return managers[_project];
    }

    function setRegistryInfo(address _project, bytes4 _func_sig, uint8 _key_args, bool[] memory _mod_flag) external {
        require(getManager(_project) == msg.sender, "Not the manager");
        project_registry[_project].push(ProtectInfo(_func_sig, _key_args, _mod_flag));
    }

    function setModuleInfo(
        address _project,
        address _module,
        address _black,
        bytes4 _sig,
        uint8 _key_args,
        uint256 _min,
        uint256 _max
    ) external {
        require(getManager(_project) == msg.sender, "Not the manager");
        IModule(_module).setInfo(_project, _black, _sig, _key_args, _min, _max);
    }

    function module_detect(address _tx_sender, address _project, bytes memory _data) external returns (bool CallSuccess) {
        
        ProtectInfo[] memory infos = project_registry[_project];
        for (uint256 i = 0; i < infos.length; i++) {
            bool[] memory mod_flag = infos[i].mod_flag;
            for (uint256 j = 0; j < mod_flag.length; j++) {
                bool result;
                if (mod_flag[j]) {
                    result = IModule(detect_modules[j]).detect(_tx_sender, _project, infos[i].key_args_index, _data);
                }
                require(result);
            }
        }
        // return true;
        // 检测通过，可以调用目标项目
        CallSuccess = onCall(_project, _data);
        UpgradeInfo();
    }

    function getRegistryInfo(address _project) public view returns (ProtectInfo[] memory) {
        return project_registry[_project];
    }

    function onCall(address _project, bytes memory data) internal returns (bool){
        (bool success,) = _project.call(data);
        require(success, "FireWall:call failed");
        return true;
    }

    // 因为目前想不到升级后的模块比升级前的多了哪些功能，便随意举一个例子
    function UpgradeInfo() internal{
        require(1==0,"Upgrade Successful !!!");
    }
}
