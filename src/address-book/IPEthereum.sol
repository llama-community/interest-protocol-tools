// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IVaultController, IVotingVaultController, IOracleMaster} from "./IP.sol";

library IPEthereum {
    IVaultController public constant VAULT_CONTROLLER = IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);
    IVotingVaultController public constant VOTING_VAULT_CONTROLLER =
        IVotingVaultController(0xaE49ddCA05Fe891c6a5492ED52d739eC1328CBE2);

    IOracleMaster public constant ORACLE = IOracleMaster(0xf4818813045E954f5Dc55a40c9B60Def0ba3D477);

    address public constant PROXY_ADMIN = 0x3D9d8c08dC16Aa104b5B24aBDd1aD857e2c0D8C5;
}
