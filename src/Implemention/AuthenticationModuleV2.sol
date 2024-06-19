//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IModule} from "./IModule.sol";

contract AuthModule is IModule {
    //黑名单模式:1.函数黑名单 2.全局黑名单
    struct BlackMode{
        bool isFuctionAccessBlacklist;
        bool isGlobalAccessBlacklist;
    }
    // 黑名单 项目地址 => 函数选择器 => 黑名单地址 => 是否是黑名单 (避免遍历数组)
    mapping(address => mapping(bytes4 => mapping(address => bool))) functionAccessBlacklist;
    // 全局黑名单 项目地址 => 黑名单地址 => 是否是黑名单
    mapping(address => mapping(address => bool)) globalAccessBlacklist;
    // 项目地址 => 启用模式
    mapping(address => BlackMode) blackListMode;

    address manager;
    address router;
    address registry;
    // =============================修饰符=============================

    // 检查权限修饰符
    modifier check() {
        require(
            msg.sender == router || msg.sender == registry || msg.sender == manager, "ParamModule:permission denied"
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
    // =============================选择要启用的黑名单拦截方式=================================

    /**
     * @dev 设置项目启用的黑名单拦截模式
     * @param data  inculdes projectaddress, _isFuctionAccessBlacklist and _isGlobalAccessBlacklist
     */
    function setMode(bytes memory data) external override check{
        (address project, bool _isFuctionAccessBlacklist, bool _isGlobalAccessBlacklist) = abi.decode(data,(address, bool, bool));
        blackListMode[project].isFuctionAccessBlacklist = _isFuctionAccessBlacklist;
        blackListMode[project].isGlobalAccessBlacklist = _isGlobalAccessBlacklist;
    }

    // =============================管理函数=============================

    /**
     * @dev 设置黑名单信息
     * @param data 包含函数选择器、项目地址、黑名单地址的ABI编码数据以及该项目是否是黑名单地址
     * @notice 这个地方感觉可以把address从data分离出来作为一个参数，而不是通过硬编码传递
     */
    function setInfo(bytes memory data) external override check {
        // 添加
        (bytes4 funcSig, address project, address blackAddr, bool isblack) = abi.decode(data, (bytes4, address, address, bool));
        if(blackListMode[project].isFuctionAccessBlacklist == true){
            functionAccessBlacklist[project][funcSig][blackAddr] = isblack;
        }
        if(blackListMode[project].isGlobalAccessBlacklist == true){
            globalAccessBlacklist[project][blackAddr] = isblack;
        }
        emit AddBlackAddr(project, blackAddr);
    }

    /**
     * @dev 移除黑名单信息
     * @param data 包含函数选择器、项目地址、黑名单地址的ABI编码数据以及该项目置为非黑名单
     * @notice 这个地方感觉可以把address从data分离出来作为一个参数，而不是通过硬编码传递
     */
    function removeInfo(bytes memory data) external override check {
        // 移除
        (bytes4 funcSig, address project, address blackAddr) = abi.decode(data, (bytes4, address, address));
        if(blackListMode[project].isFuctionAccessBlacklist == true){
            functionAccessBlacklist[project][funcSig][blackAddr] = false;
        }
        if(blackListMode[project].isGlobalAccessBlacklist == true){
            globalAccessBlacklist[project][blackAddr] = false;
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
    function detect(address project, string[] memory args, bytes memory data) external override returns (bool) {
        if(blackListMode[project].isFuctionAccessBlacklist == true){
            if(functionAccessBlacklist[project][bytes4(data)][tx.origin] == true){ 
                emit BlackAddrAccess(project, tx.origin);
                revert("detect:black address access forbidden");
            }
        }
        if(blackListMode[project].isGlobalAccessBlacklist == true){
            if(globalAccessBlacklist[project][tx.origin] == true){ 
                emit BlackAddrAccess(project, tx.origin);
                revert("detect:black address access forbidden");
            }
        }
        
        return true;
    }
}
