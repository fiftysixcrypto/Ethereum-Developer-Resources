// SPDX-License-Identifier: MIT
// Code Templates pulled from: https://github.com/jtriley-eth/ERC-6909/blob/main/src/ERC6909.sol

pragma solidity ^0.8.24;

import "./interfaces/IERC6909.sol";
import "./interfaces/IERC6909ContentURI.sol";
import "./interfaces/IERC6909Metadata.sol";
import "./interfaces/IERC6909TokenSupply.sol";

contract ERC6909 is IERC6909, IERC6909ContentURI, IERC6909Metadata, IERC6909TokenSupply {
    /// @dev Thrown when owner balance for id is insufficient.
    error InsufficientBalance();

    /// @dev Thrown when spender allowance for id is insufficient.
    error InsufficientPermission();

    /// @notice Owner balance of an id.
    mapping(address owner => mapping(uint256 id => uint256 amount)) public balanceOf;

    /// @notice Spender allowance of an id.
    mapping(address owner => mapping(address spender => mapping(uint256 id => uint256 amount))) public allowance;

    /// @notice Checks if a spender is approved by an owner as an operator.
    mapping(address owner => mapping(address spender => bool)) public isOperator;

    /// @notice The name of the token.
    mapping(uint256 id => string) public name;

    /// @notice The symbol of the token.
    mapping(uint256 id => string) public symbol;

    /// @notice The number of decimals for each id.
    mapping(uint256 id => uint8 amount) public decimals;

    mapping(uint256 id => uint256) public totalSupply;

    /// @notice The contract level URI.
    string public contractURI;

    /// @notice Transfers an amount of an id from the caller to a receiver.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transfer(address receiver, uint256 id, uint256 amount) public returns (bool) {
        if (balanceOf[msg.sender][id] < amount) revert InsufficientBalance();
        balanceOf[msg.sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, msg.sender, receiver, id, amount);
        return true;
    }

    /// @notice Transfers an amount of an id from a sender to a receiver.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) public returns (bool) {
        if (sender != msg.sender && !isOperator[sender][msg.sender]) {
            uint256 senderAllowance = allowance[sender][msg.sender][id];
            if (senderAllowance < amount) revert InsufficientPermission();
            if (senderAllowance != type(uint256).max) {
                allowance[sender][msg.sender][id] = senderAllowance - amount;
            }
        }
        if (balanceOf[sender][id] < amount) revert InsufficientBalance();
        balanceOf[sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, sender, receiver, id, amount);
        return true;
    }

    /// @notice Approves an amount of an id to a spender.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function approve(address spender, uint256 id, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender][id] = amount;
        emit Approval(msg.sender, spender, id, amount);
        return true;
    }

    /// @notice Sets or unsets a spender as an operator for the caller.
    /// @param spender The address of the spender.
    /// @param approved The approval status.
    function setOperator(address spender, bool approved) public returns (bool) {
        isOperator[msg.sender][spender] = approved;
        emit OperatorSet(msg.sender, spender, approved);
        return true;
    }

    /// @notice The URI for each id.
    /// @return The URI of the token.
    function tokenURI(uint256) public pure override returns (string memory) {
        return "<baseuri>/{id}";
    }

    /// @notice Checks if a contract implements an interface.
    /// @param interfaceId The interface identifier, as specified in ERC-165.
    /// @return supported True if the contract implements `interfaceId` and
    function supportsInterface(bytes4 interfaceId) public pure returns (bool supported) {
        return interfaceId == type(IERC6909).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
