// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./tokens/ERC6909.sol";

contract ERC6909Mock is ERC6909 {
    constructor() ERC6909() {}

    function mint(address receiver, uint256 id, uint256 amount) public {
        balanceOf[receiver][id] += amount;
        totalSupply[id] += amount;
        emit Transfer(msg.sender, address(0), receiver, id, amount);
    }

    function burn(address receiver, uint256 id, uint256 amount) public {
        balanceOf[receiver][id] -= amount;
        totalSupply[id] -= amount;
        emit Transfer(msg.sender, receiver, address(0), id, amount);
    }

    function setName(uint256 id, string memory _name) public {
        name[id] = _name;
    }

    function setSymbol(uint256 id, string memory _symbol) public {
        symbol[id] = _symbol;
    }

    function setDecimals(uint256 id, uint8 amount) public {
        decimals[id] = amount;
    }

    function setContractURI(string memory uri) public {
        contractURI = uri;
    }
}
