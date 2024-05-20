interface IModule {
    function detect(address _tx_sender, address _project, uint8 _key_args, bytes memory _data)
        external
        returns (bool);

    function setInfo(address _project, address _black, bytes4 _sig, uint8 _key_args, uint256 _min, uint256 _max)
        external;
}
