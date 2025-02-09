// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console } from "forge-std/Script.sol";

import { MinimalAccount } from "src/ethereum/MinimalAccount.sol";

contract DeployMinimalAccount is Script {
    function run() public {
        vm.startBroadcast();

        // Address of sepolia ETH EntryPoint contract
        address entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

        MinimalAccount minimalAccount = new MinimalAccount(entryPoint);

        console.log("MinimalAccount deployed at: ", address(minimalAccount));

        vm.stopBroadcast();
    }
}
