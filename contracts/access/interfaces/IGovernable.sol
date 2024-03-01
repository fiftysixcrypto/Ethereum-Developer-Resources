// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}
