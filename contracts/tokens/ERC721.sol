// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FiftysixERC721 is ERC721 {
    constructor() ERC721("Fiftysix NFT", "56") {}

    function mint(address mintTo_, uint256 tokenId_) external {
        _mint(mintTo_, tokenId_);
    }
}
