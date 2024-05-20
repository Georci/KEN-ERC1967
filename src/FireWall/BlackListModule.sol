import {IModule} from "./FireWallRouter.sol";
// 黑名单模块
// 思路：项目方可以设置黑名单，黑名单中的地址无法调用受保护合约

contract BlackListModule is IModule {
    // 黑名单可能有多个
    mapping(address => address[]) blacklist;

    function detect(address _tx_sender, address _project, uint8 _key_args, bytes memory _data)
        external
        view
        override
        returns (bool)
    {
        address[] memory _blacklist = blacklist[_project];
        for (uint256 i = 0; i < _blacklist.length; i++) {
            if (_tx_sender == _blacklist[i]) {
                revert("BlackListModule: black address");
            }
        }
        return true;
    }

    function setInfo(address _project, address _black, bytes4 _sig, uint8 _key_args, uint256 _min, uint256 _max)
        external
    {
        blacklist[_project].push(_black);
    }
}
