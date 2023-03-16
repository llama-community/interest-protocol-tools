// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVaultController {
    function _enabledTokens(uint256 id) external view returns (address);

    /// @notice create a new vault
    /// @return address of the new vault
    function mintVault() external returns (address);

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

    /// @notice get the amount of tokens regsitered in the system
    /// @return the amount of tokens registered in the system
    function tokensRegistered() external view returns (uint256);

    /// @notice get vault address of id
    /// @return the address of vault
    function vaultAddress(uint96 id) external view returns (address);

    /// @notice get the amount of vaults in the system
    /// @return the amount of vaults in the system
    function vaultsMinted() external view returns (uint96);
}

interface IVotingVaultController {
    /// @notice create a new vault
    /// @param id of an existing vault
    /// @return address of the new vault
    function mintVault(uint96 id) external returns (address);

    /// @notice register an underlying capped token pair
    /// note: registring a token as a capepd token allows it to transfer the balance of the corresponding token at will
    /// @param underlyingAddress address of underlying
    /// @param cappedToken address of capped token
    function registerUnderlying(address underlyingAddress, address cappedToken) external;

    function votingVaultAddress(uint96 vaultId) external view returns (address);
}

/// @title OracleMaster Interface
/// @notice Interface for interacting with OracleMaster
interface IOracleMaster {
    // calling function
    function getLivePrice(address tokenAddress) external view returns (uint256);

    // admin functions
    function setRelay(address tokenAddress, address relayAddress) external;
}
