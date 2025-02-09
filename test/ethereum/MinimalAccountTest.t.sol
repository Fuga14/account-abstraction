// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { MinimalAccount } from "src/ethereum/MinimalAccount.sol";
import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";
import { MockERC20 } from "src/mocks/MockERC20.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////
                                ACCOUNTS
    //////////////////////////////////////////////////////////////*/
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal carol = makeAddr("carol");
    address internal chuck = makeAddr("chuck");

    uint256 internal privateKey = 123456789;
    address internal deployer = vm.addr(privateKey);

    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/
    MinimalAccount minimalAccount;
    EntryPoint entryPoint;
    MockERC20 usdc;

    uint256 constant AMOUNT = 1 ether;

    function setUp() public {
        vm.startBroadcast(deployer);

        usdc = new MockERC20(1_000_000 ether, 18);
        entryPoint = new EntryPoint();
        minimalAccount = new MinimalAccount(address(entryPoint));

        vm.stopBroadcast();
    }

    function test_OwnerCanExecuteCommands() public {
        // USDC Mint
        // msg.sender is the owner

        // Assert
        assertEq(usdc.balanceOf(alice), 0, "USDC balance is not zero");
        assertEq(minimalAccount.owner(), deployer, "Account missmatch");

        // Prepare data
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcData = abi.encodeWithSelector(MockERC20.mint.selector, address(alice), AMOUNT);

        // Execute
        vm.prank(deployer);
        minimalAccount.execute(dest, value, funcData);

        // Check that the USDC was minted
        assertEq(usdc.balanceOf(alice), AMOUNT, "USDC balance is not correct");
    }

    function test_NonOwnerOrEntryPointCannotExecute() public {
        // Prepare data
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcData = abi.encodeWithSelector(MockERC20.mint.selector, address(alice), AMOUNT);

        // Execute and expect revert
        vm.prank(bob);
        vm.expectRevert(MinimalAccount.NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(dest, value, funcData);
    }

    function test_ReoverSignedOp() public {
        vm.startBroadcast(deployer);
        // Prepare data
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcData = abi.encodeWithSelector(MockERC20.mint.selector, address(alice), AMOUNT);

        bytes memory callData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, funcData);

        PackedUserOperation memory packedUserOp =
            generateSignedUserOperation(deployer, callData, address(minimalAccount));

        bytes32 userOpHash = entryPoint.getUserOpHash(packedUserOp);
        address singer = ECDSA.recover(userOpHash.toEthSignedMessageHash(), packedUserOp.signature);

        assertEq(singer, deployer);

        vm.stopBroadcast();
    }

    function test_ValidateUserOperation() public {
        vm.startBroadcast(deployer);
        // Prepare data
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcData = abi.encodeWithSelector(MockERC20.mint.selector, address(alice), AMOUNT);

        bytes memory callData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, funcData);

        PackedUserOperation memory packedUserOp =
            generateSignedUserOperation(deployer, callData, address(minimalAccount));

        bytes32 userOpHash = entryPoint.getUserOpHash(packedUserOp);
        address singer = ECDSA.recover(userOpHash.toEthSignedMessageHash(), packedUserOp.signature);

        assertEq(singer, deployer);
        vm.stopBroadcast();

        vm.prank(address(entryPoint));
        uint256 result = minimalAccount.validateUserOp(packedUserOp, userOpHash, 0);
        assertEq(result, 0, "Validation failed");
    }

    function test_EntryPointCanExecuteCommands() public {
        vm.startBroadcast(deployer);
        // Prepare data
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory funcData = abi.encodeWithSelector(MockERC20.mint.selector, address(alice), AMOUNT);

        bytes memory callData = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, funcData);

        PackedUserOperation memory packedUserOp = generateSignedUserOperation(alice, callData, address(minimalAccount));

        // bytes32 userOpHash = entryPoint.getUserOpHash(packedUserOp);
        vm.stopBroadcast();

        vm.deal(address(minimalAccount), 1 ether);

        PackedUserOperation[] memory packedUserOps = new PackedUserOperation[](1);
        packedUserOps[0] = packedUserOp;

        // Act
        vm.prank(alice);
        entryPoint.handleOps(packedUserOps, payable(alice));

        // Check that the USDC was minted
        assertEq(usdc.balanceOf(alice), AMOUNT, "USDC balance is not correct");
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function generateSignedUserOperation(address _sender, bytes memory callData, address _minimalAccount)
        internal
        view
        returns (PackedUserOperation memory)
    {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(_minimalAccount) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(_minimalAccount, nonce, callData);

        // 2. Get the userOp hash
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // 3. Sign the hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        userOp.signature = abi.encodePacked(r, s, v);

        return userOp;
    }

    function _generateUnsignedUserOperation(address sender, uint256 nonce, bytes memory callData)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint256 verificationGasLimit = 16777216;
        uint256 callGasLimit = verificationGasLimit;
        uint256 maxPriorityFeePerGas = 256;
        uint256 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
