// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract FiftysixERC1155 is ERC1155 {
    constructor() ERC1155("https://fiftysix.xyz/metadata") {}

    function mint(address mintTo_, uint256 tokenId_, uint256 amount_) external {
        _mint(mintTo_, tokenId_, amount_, "");
    }
}
