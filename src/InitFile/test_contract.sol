//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FireWallRouter} from "./Router.sol";

contract TestContract {
    bool is_attack;
    FireWallRouter router;

    constructor(address _router) {
        router = FireWallRouter(_router);
    }

    function test_attack(uint256 a) public {
        router.executeWithDetect(msg.data);
        if (a > 100) {
            is_attack = true;
        }
    }
}
