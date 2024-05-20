pragma solidity ^0.8.0;

abstract contract Proxy {
    // KEN：这个合约实现的是无论以哪种形式调用代理合约中的回调函数时，都是去调用对应的逻辑合约中的函数。
    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch result
            case 0 {
                revert(0, size)
            }
            default {
                return(0, size)
            }
        }
    }

    function _implementation() internal virtual returns (address) {}

    function _beforeFallback() internal virtual {}

    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}
