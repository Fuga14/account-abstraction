// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";

import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OwnerExecution is Script {
    MinimalAccount internal minimalAccount;
    IERC20 internal link = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    error NotFromEntryPointOrOwner();

    function run() public {
        vm.startBroadcast();

        minimalAccount = MinimalAccount(payable(0x8066FE51D2865a2EB6CA6303130E87c8b8937836));
        address spender = 0x3ad7FEA4f215DE8875F45931e2e3880D45e22EBa;
        uint256 amount = 1e18;

        // Check that the caller is the owner
        require(minimalAccount.owner() == msg.sender, NotFromEntryPointOrOwner());

        // Prepare data for LINK approval
        address dest = address(link);
        uint256 value = 0;
        bytes memory funcData = abi.encodeWithSelector(IERC20.approve.selector, spender, amount);

        // Execute
        minimalAccount.execute(dest, value, funcData);

        console.log("LINK approved");

        vm.stopBroadcast();
    }
}
