// SPDX License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import {Script} from "forge-std/Script.sol";
import {DAO} from "../src/DAO.sol";

contract DeployDAO is Script {
    
    function run() public returns (DAO) {
        vm.startBroadcast();

        DAO dao = new DAO();

        vm.stopBroadcast();
        return dao;
    }
}