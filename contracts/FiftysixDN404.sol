// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./tokens/DN404.sol";
import "./tokens/DN404Mirror.sol";
import {Governable} from "./access/Governable.sol";

/**
 * @title FiftysixDN404
 * @notice Sample DN404 contract that demonstrates the owner selling fungible tokens.
 * When a user has at least one base unit (10^18) amount of tokens, they will automatically receive an NFT.
 * NFTs are minted as an address accumulates each base unit amount of tokens.
 */
contract FiftysixDN404 is DN404, Governable {
    string private _name;
    string private _symbol;
    string private _baseURI;

    // State variables
    uint256 private constant TOKENS_PER_ETH = 1000;
    uint256 public constant MAX_SUPPLY = 1000000 * (10 ** 18);
    uint256 public currentSupply = 0;

    constructor(
        string memory name_,
        string memory symbol_,
        uint96 initialTokenSupply
    ) {
        _name = name_;
        _symbol = symbol_;

        address mirror = address(new DN404Mirror(msg.sender));
        _initializeDN404(initialTokenSupply, msg.sender, mirror);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory result) {
        if (bytes(_baseURI).length != 0) {
            result = string(abi.encodePacked(_baseURI, toString(tokenId)));
        }
    }

    // This allows the owner of the contract to mint more tokens.
    function mint(address to, uint256 amount) public onlyGovernor {
        _mint(to, amount);
    }

    function setBaseURI(string calldata baseURI_) public onlyGovernor {
        _baseURI = baseURI_;
    }

    function withdraw() public onlyGovernor {
        payable(governor).transfer(address(this).balance);
    }

    // The receive function that mints tokens upon receiving ETH
    receive() external payable override {
        require(msg.value > 0, "Must send ETH to mint tokens");

        // Calculate the amount of tokens to mint
        uint256 amountToMint = msg.value * TOKENS_PER_ETH;
        
        // Check if minting this amount exceeds the max supply
        require(currentSupply + amountToMint <= MAX_SUPPLY, "Minting exceeds max supply");

        // Update current supply
        currentSupply += amountToMint;

        // Mint the tokens
        _mint(msg.sender, amountToMint);
    }

    // Pulled from Vectorized's Solady repo
    // https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol
    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, add(str, 0x20))
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            let w := not(0) // Tsk.
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for { let temp := value } 1 {} {
                str := add(str, w) // `sub(str, 1)`.
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}
