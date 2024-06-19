//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IModule} from "./IModule.sol";

contract AuthModule is IModule {
    // 黑名单 项目地址 => 函数选择器 => 黑名单
    mapping(address => mapping(bytes4 => address[])) functionAccessBlacklist;
    // 全局黑名单 -> 项目方设计
    address manager;
    address router;
    address registry;
    // =============================修饰符=============================

    // 检查权限修饰符
    modifier check() {
        require(
            msg.sender == router ||
                msg.sender == registry ||
                msg.sender == manager,
            "ParamModule:permission denied"
        );
        _;
    }
    // =============================事件=============================

    // 黑名单地址访问事件
    event BlackAddrAccess(address project, address blackAddr);
    // 添加黑名单地址事件
    event AddBlackAddr(address project, address blackAddr);
    // 移除黑名单地址事件
    event RemoveBlackAddr(address project, address blackAddr);

    // 与代理直接进行交互
    constructor(address _routerProxy, address _registryProxy) {
        router = _routerProxy;
        registry = _registryProxy;
        manager = msg.sender;
    }

    // =============================管理函数=============================

    /**
     * @dev 设置黑名单信息
     * @param data 包含函数选择器、项目地址和黑名单地址的ABI编码数据
     */
    function setInfo(bytes memory data) external override check {
        // 添加
        (bytes4 funcSig, address project, address blackAddr) = abi.decode(
            data,
            (bytes4, address, address)
        );
        functionAccessBlacklist[project][funcSig].push(blackAddr);
        emit AddBlackAddr(project, blackAddr);
    }

    /**
     * @dev 移除黑名单信息
     * @param data 包含函数选择器、项目地址和黑名单地址的ABI编码数据
     */
    function removeInfo(bytes memory data) external override check {
        // 移除
        (bytes4 funcSig, address project, address blackAddr) = abi.decode(
            data,
            (bytes4, address, address)
        );
        address[] memory blackList = functionAccessBlacklist[project][funcSig];
        for (uint64 i = 0; i < blackList.length; i++) {
            if (blackList[i] == blackAddr) {
                delete functionAccessBlacklist[project][funcSig][i];
                break;
            }
        }
        emit RemoveBlackAddr(project, blackAddr);
    }

    // =============================检测函数=============================

    /**
     * @dev 检测是否允许访问
     * @param project 项目地址
     * @param args 参数列表
     * @param data 函数调用数据
     * @return 是否允许访问
     */
    function detect(
        address project,
        string[] memory args,
        bytes memory data
    ) external override returns (bool) {
        address[] memory blackList = functionAccessBlacklist[project][
            bytes4(data)
        ];
        for (uint256 i = 0; i < blackList.length; i++) {
            if (blackList[i] == tx.origin) {
                emit BlackAddrAccess(project, tx.origin);
                revert("detect:black address access forbidden");
            }
        }
        return true;
    }

    function setMode(bytes memory data) external virtual override {}
}
