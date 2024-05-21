pragma solidity ^0.8.3;
import {console} from "forge-std/Test.sol";
import "./ERC-1967Upgrade.sol";

contract ERC1967Proxy is ERC1967Upgrade {
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    function _implementation() internal view virtual returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }

    // KEN：这个合约实现的是无论以哪种形式调用代理合约中的回调函数时，都是去调用对应的逻辑合约中的函数。
    function _delegate(address implementation) internal virtual {
        console.log("Into delegate!");
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

    function _beforeFallback() internal virtual {}

    function _fallback() internal {
        // _beforeFallback();
        _delegate(_implementation());
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}
