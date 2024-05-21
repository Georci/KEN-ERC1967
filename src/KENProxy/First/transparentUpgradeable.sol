// SPDX-License-Indentifier:MIT
pragma solidity ^0.8.0;

import "./ERC-1967Proxy.sol";
import {FireWallRegistry} from "../../FireWall/FireWallRegistry.sol";
import {FireWallRegistry2} from "../../FireWall/FireWallRegistry2.sol";
import {IModule} from "../../FireWall/IModule.sol";

contract TransparentUpgradeableProxy is ERC1967Proxy {
    // 持久化存储的状态
    mapping(address => ProtectInfo[]) public project_registry;
    mapping(address => address) public managers;
    address[] detect_modules;
    address owner;

    struct ProtectInfo {
        // 函数签名
        bytes4 func_sig;
        // 关键参数位置
        uint8 key_args_index;
        // 启动的模块
        bool[] mod_flag;
    }

    // 创建一个新的TransparentUpgradeableProxy实例
    constructor(
        address logic,
        address _admin,
        bytes memory data,
        address[] memory _detect_modules
    ) ERC1967Proxy(logic, data) {
        _changeAdmin(_admin);
        owner = msg.sender;
        detect_modules = _detect_modules;
    }

    //=========================================== Proxy ==============================================//
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

    function implementation()
        external
        ifAdmin
        returns (address implementation_)
    {
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
    function upgradeToAndCall(
        address newImplementation,
        bytes calldata data
    ) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    
    function _beforeFallback() internal override {
        require(1 == 0, "Never commit");
    }

    // 路由调用
    function callLogic(
        address _project,
        bytes memory _data
    ) external returns (bool) {
        address registry = _implementation();
        require(_project != address(0), "Invalid sender");

        // 防火墙检测
        bytes memory checkdata = abi.encodeWithSignature(
            "module_detect(address,address,bytes)",
            msg.sender,
            _project,
            _data
        );
        (bool success, bytes memory data) = registry.delegatecall(checkdata);
        require(success, "delegatcall failed!");
        uint256 returnValue = abi.decode(data, (uint256));
        require(returnValue == 1, "FireWall:module_detect failed");

        return true;
        // (bool success, ) = _implementation().delegatecall(inputdata);
    }

    //======================================= Manage projects =======================================//
    /**
     * 目前想法：1.在代理合约中完成项目及其owner的增删改查 2.在代理合约中完成防护模块detect_modules及其manager的增删改查
     * 
     */
    function setManager(address _project, address _manager) external {
        require(msg.sender == owner, "Not the owner");
        managers[_project] = _manager;
    }

    function getManager(address _project) public view returns (address) {
        return managers[_project];
    }

    function setRegistryInfo(address _project, bytes4 _func_sig, uint8 _key_args, bool[] memory _mod_flag) external {
        require(getManager(_project) == msg.sender, "Not the manager");
        project_registry[_project].push(ProtectInfo(_func_sig, _key_args, _mod_flag));
    }

    function setModuleInfo(
        address _project,
        address _module,
        address _black,
        bytes4 _sig,
        uint8 _key_args,
        uint256 _min,
        uint256 _max
    ) external {
        require(getManager(_project) == msg.sender, "Not the manager");
        IModule(_module).setInfo(_project, _black, _sig, _key_args, _min, _max);
    }

    
    function getRegistryInfo(address _project) public view returns (ProtectInfo[] memory) {
        return project_registry[_project];
    }
}
