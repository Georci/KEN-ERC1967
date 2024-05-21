pragma solidity ^0.8.0;

import "../src/KENProxy/First/FireWallRouter.sol";
import "../src/KENProxy/First/transparentUpgradeable.sol";
import {Test, console} from "forge-std/Test.sol";

// Logic
import "../src/FireWall/FireWallRegistry.sol";
import "../src/FireWall/FireWallRegistry2.sol";

import "../src/FireWall/BlackListModule.sol";
import "../src/FireWall/test_contract.sol";
import "../src/FireWall/ParamIntercept.sol";

contract Testfallbackselector is Test {

    address attacker = vm.addr(10);
    address deployer = vm.addr(1);
    address newOwner = vm.addr(3);
    address projectManager = vm.addr(2);
    FireWallRegistry registry;
    FireWallRegistry2 registry2;
    Target target;

    address admin = vm.addr(4);
    TransparentUpgradeableProxy proxy;

    function setUp() public {
        

        vm.startPrank(deployer);
        // 部署防护模块
        BlackListModule module1 = new BlackListModule();
        ParamIntercept module2 = new ParamIntercept();
        address[] memory modules = new address[](2);
        modules[0] = address(module1);
        modules[1] = address(module2);

        // 部署逻辑合约
        registry = new FireWallRegistry();
        registry2 = new FireWallRegistry2(); 

        // 部署代理合约
        proxy = new TransparentUpgradeableProxy(address(registry),admin,"",modules);
        vm.stopPrank();
        
        vm.prank(projectManager);
        target = new Target();

        // 设置保护信息
        vm.prank(deployer);
        proxy.setManager(address(target), projectManager);
        vm.prank(deployer);
        proxy.setManager(address(target), projectManager);
        bool[] memory flag = new bool[](2);
        flag[0] = true;
        flag[1] = true;
        vm.startPrank(projectManager);
        proxy.setRegistryInfo(address(target), target.protect_func.selector, 1, flag);
        proxy.setRegistryInfo(address(target), target.protect_func.selector, 1, flag);

        // 设置模块保护信息
        proxy.setModuleInfo(address(target), address(module1), attacker, 0, 0, 0, 0);
        proxy.setModuleInfo(address(target), address(module2), address(0), target.protect_func.selector, 1, 2, 20);
        // proxy.setModuleInfo(address(target), address(module1), attacker, 0, 0, 0, 0);
        // proxy.setModuleInfo(address(target), address(module2), address(0), target.protect_func.selector, 1, 2, 10);
        vm.stopPrank();

        //============================================ Proxy ===============================================//
        vm.startPrank(admin);
        console.log("The proxy contract's address is :",address(proxy));
        console.log("We want the Logic contract1 address is :",address(registry));
        console.log("We want the Logic contract2 address is :",address(registry2));
        console.log("We want the admin's address is :",admin);
        
        console.log("The Logic contract1' address :",proxy.implementation());
        console.log("The admin's address :",proxy.admin());
        console.log("The project's address :",address(target));
        vm.stopPrank();
    }

    

    function testProxy() public{
        vm.prank(newOwner);
        proxy.admin();

    }

    //================================================== test ===================================================//
    function test_detect_KEN() public {

        bool result1 = target.is_attack();
        console.log("Before call,the is_attack is:",result1);

        vm.prank(newOwner);
        bytes memory data = abi.encodeWithSelector(target.protect_func.selector, 11);
        bool result = proxy.callLogic(address(target), data);

        // require(result == false,"hasn't been attacked!");
        bool result2 = target.is_attack();
        console.log("After call,the is_attack is:",result2);
    }

    function test_Arg2() public {
        //========================== Upgrade ============================//
        vm.startPrank(admin);
        proxy.upgradeTo(address(registry2));
        console.log("The Logic contract2' address :",proxy.implementation());

        bool result1 = target.is_attack();
        console.log("Before call,the is_attack is:",result1);

        // vm.prank(newOwner);
        bytes memory data = abi.encodeWithSelector(target.protect_func.selector, 11);
        bool result = proxy.callLogic(address(target), data);

        // require(result == false,"hasn't been attacked!");
        bool result2 = target.is_attack();
        console.log("After call,the is_attack is:",result2);
        vm.stopPrank();
    }
}

