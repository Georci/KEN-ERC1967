// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {IModule} from "./IModule.sol";

contract ParamIntercept is IModule {
    // 参数范围
    struct ParamRange {
        uint256 min;
        uint256 max;
    }

    // 函数选择器 -> 函数参数位置 -> 参数范围
    mapping(bytes4 => mapping(uint8 => ParamRange)) paramRanges;
    // 管理员

    function detect(address _tx_sender, address _project, uint8 _key_args, bytes memory _data)
        external
        view
        override
        returns (bool)
    {
        // 至少要存在函数调用
        if (_data.length < 8) {
            revert("call data have no function selector");
        }
        (bytes4 sig, uint256 now_param) = getParam(_data, _key_args);
        // 获取参数范围
        ParamRange memory range = paramRanges[sig][_key_args];
        if (now_param < range.min || now_param > range.max) {
            revert("error param range");
        }
        return true;
    }

    function getParam(bytes memory _data, uint8 _key_args) public pure returns (bytes4, uint256) {
        if (_data.length < 4 + 32 * _key_args) {
            revert("Invalid call data");
        }
        bytes4 sig;
        uint256 param;
        assembly {
            sig := mload(add(_data, 32))
            param := mload(add(_data, add(4, mul(_key_args, 32))))
        }
        return (sig, param);
    }

    function setInfo(address _project, address _black, bytes4 _sig, uint8 _key_args, uint256 _min, uint256 _max)
        external
    {
        paramRanges[_sig][_key_args] = ParamRange(_min, _max);
    }
}
