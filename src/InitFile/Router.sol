//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IModule} from "./IModule.sol";
import {FireWallRegistry} from "./Registry.sol";

// import {Test, console} from "forge-std/Test.sol";

contract FireWallRouter {
    // 注册表地址
    FireWallRegistry public registry;

    // 管理者
    address public owner;

    constructor() {
        // 创建注册表
        registry = new FireWallRegistry(address(this));
        emit registryAddress(address(registry));
        owner = msg.sender;
    }

    // =============================修饰符=============================
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    // =============================事件==============================
    event AddProject(address project);
    event registryAddress(address registryAddr);
    event pauseProjectInteract(address project);
    event unpauseProjectInteract(address project);
    event pauseModuleForProject(address project, uint64 module_index);

    // =============================检测函数=============================
    function executeWithDetect(bytes memory data) external returns (bool) {
        // 查询信息
        FireWallRegistry.ProtectInfo memory info = registry.getProtectInfo(
            msg.sender,
            bytes4(data)
        );
        // 判断是否暂停
        require(!registry.pauseMap(msg.sender), "project is pause interaction");
        require(!info.is_pause, "project function is pause interaction");
        // 遍历
        for (uint256 index = 0; index < info.enableModules.length; index++) {
            address detectMod = info.enableModules[index];
            // 拆开参数
            string[] memory args = info.params;
            IModule(detectMod).detect(msg.sender, args, data);
        }
        return true;
    }

    ///@notice Initialize router's data.
    ///@param routerProxy The address of router's proxy.
    ///@param _owner The address of owner.
    function initialize(address routerProxy, address _owner) external {
        registry = new FireWallRegistry(routerProxy);
        emit registryAddress(address(registry));
        owner = _owner;
    }
}
