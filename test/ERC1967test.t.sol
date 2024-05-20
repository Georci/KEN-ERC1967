pragma solidity ^0.8.0;

import "eip1820_firewall/src/KENProxy/proxy.sol";
import {Test, console} from "forge-std/Test.sol";

contract Testfallbackselector is Test {
    address deployer = vm.addr(1);
}