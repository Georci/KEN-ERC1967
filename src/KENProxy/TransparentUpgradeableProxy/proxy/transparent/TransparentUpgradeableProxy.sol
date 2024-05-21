// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC-1967/ERC-1967Proxy.sol";
contract TransparentUpgradeableProxy is ERC1967Proxy{
    
    // KEN：初始化升级代理
    // 参数：_logic 逻辑合约地址，_admin 管理员地址，_data 数据
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    // KEN：修饰器限制调用者，如果是Admin则正常调用，否则调用delegatecall逻辑
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    //KEN：仅仅只更改逻辑合约的地址
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    //KEN：在升级之后通过delegatecall调用逻辑合约
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    //KEN：保证调用者不能是Admin
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }

}
