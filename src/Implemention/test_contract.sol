//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FireWallRouter} from "./Router.sol";
import {ProxyForRouter} from "../proxy/proxyForRouter.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";

contract TestContract {
    bool is_attack;
    // FireWallRouter router;
    ProxyForRouter router;

    constructor(address _routerProxy) {
        router = ProxyForRouter(payable(_routerProxy));
    }

    ///@notice data1是调用executeWithDetect()函数中使用的bytes参数
    ///@notice data是调用executeWithDetect()函数中使用的bytes硬编码数据
    function test_attack(uint256 a) public {
        //这个地方还是有问题，应该将test_attack的function_selector也传入
        bytes memory data = abi.encodeWithSignature(
            "executeWithDetect(bytes)",
            msg.data
        );
        router.CallOn(data);

        if (a <= 100) {
            is_attack = true;
            console.log("Attack successful");
        }
    }
}
