pragma solidity ^0.8.0;

contract Target {
    bool public is_attack = true;

    function protect_func(uint256 a) public {
        is_attack = false;
    }
}
