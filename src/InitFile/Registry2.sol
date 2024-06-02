contract test {
    // 注册表的管理者
    address owner;
    // 项目地址 => 项目管理者
    mapping(address => address) projectManagers;

    struct ProtectInfo {
        string[] params;
        address[] enableModules;
        bool is_pause;
    }

    struct ModuleInfo {
        address modAddress;
        address modAdmin;
        string description;
        bool enable;
    }

    // 项目地址 => 函数选择器 => ProtectInfo
    // *存在问题，当需要返回project保护的所有函数的列表时，无法直接返回，因此增加了一个映射
    mapping(address => mapping(bytes4 => ProtectInfo)) protectFuncRegistry;
    mapping(address => bytes4[]) protectFuncSet; // 项目地址 => 保护函数的数组

    // 模块数组
    // *存在查询不便的问题，因此需要增加一个地址到模块名称的映射以及一个模块地址到模块索引的映射
    ModuleInfo[] moduleInfos;
    mapping(address => string) moduleName; // 模块地址 => 模块名称
    mapping(address => uint64) moduleIndex; // 模块地址 => 模块索引

    // 暂停交互的项目列表
    mapping(address => bool) pauseMap;

    /**
     * @dev 本函数用于注册函数信息，包括参数、启用的模块等
     * @param project 项目地址
     * @param funcSig 函数选择器
     * @param project_manager 项目管理者
     * @param params 参数列表
     * @param enableModules 启用的模块列表
     */
    function register(
        address project,
        bytes4 funcSig,
        address project_manager,
        string[] memory params,
        address[] memory enableModules
    ) external {
        // 基本信息注册
        protectFuncRegistry[project][funcSig] = ProtectInfo(params, enableModules, false);
        // 保护函数列表添加
        protectFuncSet[project].push(funcSig);
        // 项目管理者注册
        projectManagers[project] = project_manager;
    }
}
