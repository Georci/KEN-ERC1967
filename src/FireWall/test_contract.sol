contract Target {
    bool public is_attack = false;

    function protect_func(uint256 a) public {
        is_attack = true;
    }
}
