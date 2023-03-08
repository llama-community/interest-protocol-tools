// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVaultController {
    /// @notice register a new token to be used as collateral
    /// @param tokenAddress token to register
    /// @param ltv LTV of the token, 1e18=100%
    /// @param oracleAddress address of the token which should be used when querying oracles
    /// @param liquidationIncentive liquidation penalty for the token, 1e18=100%
    function registerErc20(
        address tokenAddress,
        uint256 ltv,
        address oracleAddress,
        uint256 liquidationIncentive
    ) external;
}

interface IVotingVaultController {
    /// @notice register an underlying capped token pair
    /// note: registring a token as a capepd token allows it to transfer the balance of the corresponding token at will
    /// @param underlyingAddress address of underlying
    /// @param cappedToken address of capped token
    function registerUnderlying(address underlyingAddress, address cappedToken) external;
}

/// @title OracleMaster Interface
/// @notice Interface for interacting with OracleMaster
interface IOracleMaster {
    // calling function
    function getLivePrice(address tokenAddress) external view returns (uint256);

    // admin functions
    function setRelay(address tokenAddress, address relayAddress) external;
}
