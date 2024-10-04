// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SimpleLendingProtocol} from "../src/SimpleLendingProtocol.sol";

contract SimpleLendingProtocolScript is Script {
    SimpleLendingProtocol public protocol;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        protocol = new SimpleLendingProtocol();

        vm.stopBroadcast();
    }
}
