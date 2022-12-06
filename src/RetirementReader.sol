// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IKlimaCarbonRetirements} from './interfaces/IKlimaCarbonRetirements.sol';
import {
    IRetirementCertificates,
    RetirementEvent
} from './interfaces/IRetirementCertificates.sol';
import {IToucanCarbonOffsetsFactory} from './interfaces/IToucanCarbonOffsetsFactory.sol';
import {IToucanPool} from './interfaces/IToucanPool.sol';

contract RetirementReader {
    IRetirementCertificates public immutable tcnRetirements;
    IToucanCarbonOffsetsFactory public immutable tco2Factory;
    // Tracked as the retiring entitty in the Toucan contracts
    // and the end user is tracked as the beneficiary
    IKlimaCarbonRetirements public immutable klimaRetirements;

    constructor(
        address _tcnRetirements,
        address _tco2Factory,
        address _klimaRetirements
    ) {
        tcnRetirements = IRetirementCertificates(_tcnRetirements);
        tco2Factory = IToucanCarbonOffsetsFactory(_tco2Factory);
        klimaRetirements = IKlimaCarbonRetirements(_klimaRetirements);
    }

    /// @notice Return the amount of all retirements a user has done
    /// related to vintages that are eligible to be deposited in the pool.
    /// Returns all retirements made directly via the Toucan contracts or
    /// as a beneficiary via the Klima contracts.
    /// @param user The user to calculate the total amount for
    /// @param pool The pool for which to associate vintages with
    /// @return amount The amount of carbon a user has retired, related to
    /// the vintages eligible to be deposited in the pool
    function getRetiredAmount(address user, address pool)
        external
        view
        returns (uint256 amount)
    {
        // Get all retirements a user has executed directly in the
        // Toucan contracts. This may still miss retirements where the
        // user has been the beneficiary of the retirement instead of
        // the retiring entity.
        uint256[] memory userIds = tcnRetirements.getUserEvents(user);
        for (uint256 i; i < userIds.length; i++) {
            RetirementEvent memory r = tcnRetirements.retirements(userIds[i]);
            // Figure out the TCO2 for the retirement
            address tco2 = tco2Factory.pvIdToERC20(r.projectVintageTokenId);
            // If no pool is provided, then add up all retirements together
            // and pray not to end up in hell
            if (pool == address(0)) {
                amount += r.amount;
            } else {
                // Derive whether this TCO2 is eligible for the pool. Note that
                // pool criteria changes over time but that works in favor of
                // using the pool as a proxy for how many tokens has a user
                // retired with quality close to the pool over time.
                try IToucanPool(pool).checkEligible(tco2) returns (bool isEligible) {
                    if (isEligible) {
                        amount += r.amount;
                    }
                } catch {}
            }
        }

        // Include any retirements executed via Klima
        if (pool == address(0)) {
            (, uint256 total,) = klimaRetirements.retirements(user);
            amount += total;
        } else {
            amount += klimaRetirements.getRetirementPoolInfo(user, pool);
        }
    }
}
