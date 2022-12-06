// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IToucanPool {
    function checkEligible(address erc20) external view returns (bool);
}
