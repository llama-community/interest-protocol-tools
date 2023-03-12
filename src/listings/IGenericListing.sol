// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenericListing {
    error NonEmptyName();
    error InvalidUnderlying();
    error InvalidCap();

    struct ListingData {
        string tokenName;
        address underlying;
        uint8 cap;
    }

    struct ChainlinkOracleData {
        address oracle;
        bool ethOracle;
        uint256 mul;
        uint256 div;
    }

    struct UniswapV3OracleData {
        uint32 lookback;
        address pool;
        bool quoteTokenIsToken0;
        bool ethOracle;
        uint256 mul;
        uint256 div;
    }

    struct AnchoredViewRelayData {
        address anchor;
        address main;
        uint256 numerator;
        uint256 denominator;
    }

    /// @dev Deploys a new capped token instance and sets the cap
    function deployCappedToken(ListingData calldata data) external returns (address);

    /// @dev Deploys a new anchored view oracle instance
    function deployAnchoredOracle(AnchoredViewRelayData calldata data) external returns (address);

    /// @dev Deploys a new ChainlinkOracleRelay/ChainlinkTokenOracleRelay instance
    function deployChainlinkOracle(ChainlinkOracleData calldata data) external returns (address);

    /// @dev Deploys a new UniswawpV3OracleRelay/UniswawpV3TokenOracleRelay
    function deployUniswapV3Oracle(UniswapV3OracleData calldata data) external returns (address);
}
