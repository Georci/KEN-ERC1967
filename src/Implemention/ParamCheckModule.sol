//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IModule} from "./IModule.sol";
import {FireWallRegistry} from "./Registry.sol";
import {Test, console} from "forge-std/Test.sol";

contract ParamCheckModule is IModule {
    struct ParamRange {
        uint256 min; // 参数最小值
        uint256 max; // 参数最大值
    }

    // 项目地址 => 函数 => 参数位置 => 参数范围
    mapping(address => mapping(bytes4 => mapping(uint64 => ParamRange))) paramRanges;
    address router;
    address manager;
    address registry;

    // =============================修饰符=============================
    modifier check() {
        console.log("check ", msg.sender);
        require(
            msg.sender == router ||
                msg.sender == registry ||
                msg.sender == manager,
            "ParamModule:permission denied"
        );
        _;
    }

    // =============================事件=============================
    event errorParam(address project, bytes4 sig, uint64 index, uint256 value); // 参数错误事件
    event setParamRange(
        address project,
        bytes4 sig,
        uint64 index,
        uint256 min,
        uint256 max
    ); // 设置参数范围事件
    event removeParamRange(
        address project,
        bytes4 sig,
        uint64 index,
        uint256 min,
        uint256 max
    ); // 移除参数范围事件

    // 与registry、router交互肯定是走proxy
    constructor(address _routerProxy, address _registryProxy) {
        router = _routerProxy;
        registry = _registryProxy;
        manager = msg.sender;
    }

    /**
     * @dev 设置参数范围
     * @param data 参数数据
     */
    function setInfo(bytes memory data) external override check {
        (
            bytes4 sig,
            address project,
            uint64 index,
            uint256 min,
            uint256 max
        ) = abi.decode(data, (bytes4, address, uint64, uint256, uint256));
        paramRanges[project][sig][index] = ParamRange(min, max);
        emit setParamRange(project, sig, index, min, max);
    }

    /**
     * @dev 移除参数范围
     * @param data 参数数据
     */
    function removeInfo(bytes memory data) external override check {
        (bytes4 sig, address project, uint64 index) = abi.decode(
            data,
            (bytes4, address, uint64)
        );
        emit removeParamRange(
            project,
            sig,
            index,
            paramRanges[project][sig][index].min,
            paramRanges[project][sig][index].max
        );
        delete paramRanges[project][sig][index];
    }

    /**
     * @dev 检测参数是否在范围内
     * @param project 项目地址
     * @param args 参数类型数组
     * @param data 参数数据
     * @return 是否在范围内
     */
    function detect(
        address project,
        string[] memory args,
        bytes memory data
    ) external override returns (bool) {
        // 权限控制
        require(
            msg.sender == router,
            "ParamModule:detect only router can call"
        );
        // 参数长度不匹配
        require(data.length == args.length * 32 + 4, "error data length");
        // 遍历
        for (uint64 i = 0; i < args.length; i++) {
            // 获取每个参数的范围
            ParamRange memory range = paramRanges[project][bytes4(data)][i];
            // 未注册的参数
            if (range.max == 0 && range.min == 0) {
                continue;
            }
            // 仅支持uint256
            if (keccak256(bytes(args[i])) == keccak256("uint256")) {
                bytes32 temp;
                // 读取传入的参数值
                assembly {
                    temp := mload(add(data, add(4, mul(add(i, 1), 32))))
                }
                uint256 value = uint256(temp);
                // 超出范围
                // if (value < range.min || value > range.max) {
                //     emit errorParam(project, bytes4(data), i, value);
                //     revert("detect:error param");
                // }
                if (value > range.min && value < range.max) {
                    emit errorParam(project, bytes4(data), i, value);
                    revert("detect:error param");
                }
            }
        }
        return true;
    }
}
