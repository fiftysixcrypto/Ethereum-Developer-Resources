// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FiftysixERC20 is ERC20 {
    constructor(uint256 totalSupply_) ERC20("Fiftysix", "56") {
        _mint(msg.sender, totalSupply_);
    }
}
