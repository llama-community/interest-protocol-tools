// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IVaultController, IVotingVaultController, IOracleMaster} from "./IP.sol";
import {USDI} from "ip-contracts/USDI.sol";

library IPEthereum {
    IVaultController internal constant VAULT_CONTROLLER = IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);
    IVotingVaultController internal constant VOTING_VAULT_CONTROLLER =
        IVotingVaultController(0xaE49ddCA05Fe891c6a5492ED52d739eC1328CBE2);

    IOracleMaster internal constant ORACLE = IOracleMaster(0xf4818813045E954f5Dc55a40c9B60Def0ba3D477);

    address internal constant PROXY_ADMIN = 0x3D9d8c08dC16Aa104b5B24aBDd1aD857e2c0D8C5;

    USDI internal constant USDIToken = USDI(0x2A54bA2964C8Cd459Dc568853F79813a60761B58);
}
