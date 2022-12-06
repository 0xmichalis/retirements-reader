// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {
    IRetirementCertificates,
    RetirementEvent
} from './interfaces/IRetirementCertificates.sol';
import {IToucanCarbonOffsetsFactory} from './interfaces/IToucanCarbonOffsetsFactory.sol';
import {IToucanPool} from './interfaces/IToucanPool.sol';

contract RetirementReader {
    IRetirementCertificates public immutable tcnRetirements;
    IToucanCarbonOffsetsFactory public immutable tco2Factory;

    constructor(address _tcnRetirements, address _tco2Factory) {
        tcnRetirements = IRetirementCertificates(_tcnRetirements);
        tco2Factory = IToucanCarbonOffsetsFactory(_tco2Factory);
    }

    /// @notice Return the amount of all retirements a user has done
    /// related to vintages that are eligible to be deposited in the pool.
    /// @param user The user to calculate the total amount for
    /// @param pool The pool for which to associate vintages with
    /// @return amount The amount of carbon a user has retired, related to
    /// the vintages eligible to be deposited in the pool
    function getRetiredAmount(address user, address pool)
        external
        view
        returns (uint256 amount)
    {
        // Get all retirement events for a user - this still does not
        // capture retirements where the desired user is the beneficiary
        // and not the actual retiring entity
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
    }
}
