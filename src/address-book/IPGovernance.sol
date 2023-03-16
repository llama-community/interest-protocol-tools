// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {GovernorCharlieDelegate} from "ip-contracts/governance/governor/GovernorDelegate.sol";

library IPGovernance {
    GovernorCharlieDelegate internal constant GOV = GovernorCharlieDelegate(0x266d1020A84B9E8B0ed320831838152075F8C4cA);
}
