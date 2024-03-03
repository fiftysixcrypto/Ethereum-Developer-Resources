// SPDX-License-Identifier: MIT
// Author: https://github.com/jtriley-eth/ERC-6909/blob/main/src/interfaces/IERC6909TokenSupply.sol

pragma solidity ^0.8.24;

import "./IERC6909.sol";

/// @title ERC6909 Token Supply Extension
/// @author jtriley.eth
/// @notice Extends the IERC6909 interface with a total supply tracker for each token.
interface IERC6909TokenSupply is IERC6909 {
    /// @notice Total supply of a token
    /// @param id The id of the token.
    /// @return supply The total supply of the token.
    function totalSupply(uint256 id) external view returns (uint256 supply);
}
