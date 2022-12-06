// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IKlimaCarbonRetirements {
    function getRetirementPoolInfo(address user, address pool)
        external
        view
        returns (uint256);
    function retirements(address user)
        external
        view
        returns (
            uint256 totalRetirements,
            uint256 totalCarbonRetired,
            uint256 totalClaimed
        );
}
