import {Test, console} from "forge-std/Test.sol";
import "../src/FireWall/FireWallRouter.sol";
import "../src/FireWall/FireWallRegistry.sol";
import "../src/FireWall/BlackListModule.sol";
import "../src/FireWall/test_contract.sol";
import "../src/FireWall/ParamIntercept.sol";

contract FireWallRouterTest is Test {
    address attacker = vm.addr(10);
    address deployer = vm.addr(1);
    address projectManager = vm.addr(2);
    FireWallRouter router;
    FireWallRegistry registry;
    Target target;

    function setUp() public {
        vm.startPrank(deployer);
        // 部署模块
        BlackListModule module1 = new BlackListModule();
        ParamIntercept module2 = new ParamIntercept();
        address[] memory modules = new address[](2);
        modules[0] = address(module1);
        modules[1] = address(module2);
        // 部署合约
        registry = new FireWallRegistry(modules);
        router = new FireWallRouter(address(registry));
        vm.stopPrank();
        vm.prank(projectManager);
        target = new Target();
        // 设置保护信息
        vm.prank(deployer);
        registry.setManager(address(target), projectManager);
        bool[] memory flag = new bool[](2);
        flag[0] = true;
        flag[1] = true;
        vm.startPrank(projectManager);
        registry.setRegistryInfo(address(target), target.protect_func.selector, 1, flag);

        // 设置模块保护信息
        registry.setModuleInfo(address(target), address(module1), attacker, 0, 0, 0, 0);
        registry.setModuleInfo(address(target), address(module2), address(0), target.protect_func.selector, 1, 2, 10);
        vm.stopPrank();
    }

    function test_detect() public {
        vm.prank(attacker);
        bytes memory data = abi.encodeWithSelector(target.protect_func.selector, 7);
        bool result = router.onCall(address(target), data);
        require(result);
    }
}
