// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IVaultController, IVotingVaultController, IOracleMaster} from "./IP.sol";
import {USDI} from "ip-contracts/USDI.sol";

library IPMainnet {
    IVaultController internal constant VAULT_CONTROLLER = IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);
    IVotingVaultController internal constant VOTING_VAULT_CONTROLLER =
        IVotingVaultController(0xaE49ddCA05Fe891c6a5492ED52d739eC1328CBE2);

    IOracleMaster internal constant ORACLE = IOracleMaster(0xf4818813045E954f5Dc55a40c9B60Def0ba3D477);

    address internal constant PROXY_ADMIN = 0x3D9d8c08dC16Aa104b5B24aBDd1aD857e2c0D8C5;

    USDI internal constant USDIToken = USDI(0x2A54bA2964C8Cd459Dc568853F79813a60761B58);

    uint256 internal constant WETH_ID = 1;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address internal constant WETH_ORACLE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 internal constant UNISWAP_ID = 2;

    address internal constant UNISWAP = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    address internal constant UNISWAP_ORACLE = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    uint256 internal constant WBTC_ID = 3;

    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address internal constant WBTC_ORACLE = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    uint256 internal constant STETH_ID = 4;

    address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address internal constant STETH_ORACLE = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    uint256 internal constant CMATIC_ID = 5;

    address internal constant CMATIC = 0x5aC39Ed42e14Cf330A864d7D1B82690B4D1B9E61;

    address internal constant CMATIC_ORACLE = 0x5aC39Ed42e14Cf330A864d7D1B82690B4D1B9E61;

    address internal constant CMATIC_UNDERLYING = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;

    uint256 internal constant CENS_ID = 6;

    address internal constant CENS = 0xfb42f5AFb722d2b01548F77C31AC05bf80e03381;

    address internal constant CENS_ORACLE = 0xfb42f5AFb722d2b01548F77C31AC05bf80e03381;

    address internal constant CENS_UNDERLYING = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;

    uint256 internal constant CBAL_ID = 7;

    address internal constant CBAL = 0x05498574BD0Fa99eeCB01e1241661E7eE58F8a85;

    address internal constant CBAL_ORACLE = 0x05498574BD0Fa99eeCB01e1241661E7eE58F8a85;

    address internal constant CBAL_UNDERLYING = 0xba100000625a3754423978a60c9317c58a424e3D;

    uint256 internal constant CAAVE_ID = 8;

    address internal constant CAAVE = 0xd3bd7a8777c042De830965de1C1BCC9784135DD2;

    address internal constant CAAVE_ORACLE = 0xd3bd7a8777c042De830965de1C1BCC9784135DD2;

    address internal constant CAAVE_UNDERLYING = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    uint256 internal constant CLDO_ID = 9;

    address internal constant CLDO = 0x7C1Caa71943Ef43e9b203B02678000755a4eCdE9;

    address internal constant CLDO_ORACLE = 0x7C1Caa71943Ef43e9b203B02678000755a4eCdE9;

    address internal constant CLDO_UNDERLYING = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    uint256 internal constant CDYDX_ID = 10;

    address internal constant CDYDX = 0xDDB3BCFe0304C970E263bf1366db8ed4DE0e357a;

    address internal constant CDYDX_ORACLE = 0xDDB3BCFe0304C970E263bf1366db8ed4DE0e357a;

    address internal constant CDYDX_UNDERLYING = 0x92D6C1e31e14520e676a687F0a93788B716BEff5;

    uint256 internal constant CCRV_ID = 11;

    address internal constant CCRV = 0x9d878eC06F628e883D2F9F1D793adbcfd52822A8;

    address internal constant CCRV_ORACLE = 0x9d878eC06F628e883D2F9F1D793adbcfd52822A8;

    address internal constant CCRV_UNDERLYING = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    uint256 internal constant CRETH_ID = 12;

    address internal constant CRETH = 0x64eA012919FD9e53bDcCDc0Fc89201F484731f41;

    address internal constant CRETH_ORACLE = 0x64eA012919FD9e53bDcCDc0Fc89201F484731f41;

    address internal constant CRETH_UNDERLYING = 0xae78736Cd615f374D3085123A210448E74Fc6393;

    uint256 internal constant CCBETH_ID = 13;

    address internal constant CCBETH = 0x99bd1f28a5A7feCbE39a53463a916794Be798FC3;

    address internal constant CCBETH_UNDERLYING = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;

    address internal constant CCBETH_ORACLE = 0x64eA012919FD9e53bDcCDc0Fc89201F484731f41;

    uint256 internal constant CZRX_ID = 14;

    address internal constant CZRX = 0xDf623240ec300fD9e2B7780B34dC2F417c0Ab6D2;

    address internal constant CZRX_ORACLE = 0xDf623240ec300fD9e2B7780B34dC2F417c0Ab6D2;

    address internal constant CZRX_UNDERLYING = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;
}
