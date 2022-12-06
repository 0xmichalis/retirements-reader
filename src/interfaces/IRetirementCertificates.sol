// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

struct RetirementEvent {
    uint256 createdAt;
    address retiringEntity;
    uint256 amount;
    uint256 projectVintageTokenId;
}

interface IRetirementCertificates {
    function getUserEvents(address user) external view returns (uint256[] memory);
    function retirements(uint256 eventId)
        external
        view
        returns (RetirementEvent memory);
}
