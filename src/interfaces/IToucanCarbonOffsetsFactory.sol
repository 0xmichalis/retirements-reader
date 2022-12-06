// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IToucanCarbonOffsetsFactory {
    function pvIdToERC20(uint256 id) external view returns (address);
}
