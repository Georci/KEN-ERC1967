// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {FireWallRegistry} from "./FireWallRegistry.sol";
import {IModule} from "./IModule.sol";

contract FireWallRouter {
    FireWallRegistry registry;

    constructor(address _registry) {
        registry = FireWallRegistry(_registry);
    }

    function onCall(address _project, bytes memory _data) external returns (bool) {
        require(_project != address(0), "Invalid sender");
        // 转发检测
        bool is_pass = registry.module_detect(msg.sender, _project, _data);
        require(is_pass, "FireWall:module_detect failed");
        // 进行调用转发
        (bool success,) = _project.call(_data);
        require(success, "FireWall:call failed");
        return true;
    }
}
