// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IAccount} from "account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SIG_VALIDATION_SUCCESS, SIG_VALIDATION_FAILED} from "account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MinimalAccount is IAccount, Ownable {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev The entry point contract
    IEntryPoint private immutable entryPoint;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Revert if the message sender is not the entry point
    error NotFromEntryPoint();

    /// @dev Revert if the message sender is not the entry point or the owner
    error NotFromEntryPointOrOwner();

    /// @dev Revert if the execution failed
    error ExecutionFailed(bytes result);

    /// @dev Revert if the address is zero
    error ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyEntryPoint() {
        if (msg.sender != address(entryPoint)) revert NotFromEntryPoint();
        _;
    }

    modifier onlyEntryPointOrOwner() {
        if (msg.sender != address(entryPoint) && msg.sender != owner()) revert NotFromEntryPointOrOwner();
        _;
    }

    /**
     * @notice Constructor
     *
     * @param _entryPoint The entry point contract address
     */
    constructor(address _entryPoint) Ownable(msg.sender) {
        require(_entryPoint != address(0), ZeroAddress());

        entryPoint = IEntryPoint(_entryPoint);
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validate the user operation
     * Must validate the caller is a trusted EntryPoint
     *
     * @param userOp The operation struct to be validated
     * @param userOpHash The hash of the operation with signature
     * @param missingAccountFunds The amount of to be paid during tx
     *
     * @return validationData - 0 for valid signature, 1 to mark signature failure
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);

        //TODO: validate nonce
        // _validateNonce();

        _payPrefund(missingAccountFunds);
    }

    /**
     * @notice Execute the user operation
     * Caller must be the entryPoint or owner
     *
     * @param dest Destination address
     * @param value Value to be sent during the call
     * @param funcData The calldata to be sent
     */
    function execute(address dest, uint256 value, bytes calldata funcData) external onlyEntryPointOrOwner {
        // Make a low-level call to dest
        (bool success, bytes memory ret) = dest.call{value: value}(funcData);

        if (!success) revert ExecutionFailed(ret);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    // EIP-191 version of the signed hash
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);

        return signer == owner() ? SIG_VALIDATION_SUCCESS : SIG_VALIDATION_FAILED;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getEntryPoint() external view returns (address) {
        return address(entryPoint);
    }
}
