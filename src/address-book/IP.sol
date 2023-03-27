// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVaultController {
    function _enabledTokens(uint256 id) external view returns (address);

    ///@notice amount of USDi needed to reach even solvency
    ///@notice this amount is a moving target and changes with each block as pay_interest is called
    /// @param id id of vault
    function amountToSolvency(uint96 id) external view returns (uint256);

    /// @notice borrow USDi from a vault. only vault minter may borrow from their vault
    /// @param id vault to borrow against
    /// @param amount amount of USDi to borrow
    function borrowUsdi(uint96 id, uint192 amount) external;

    /// @notice calls the pay interest function
    /// @dev implementation in pay_interest
    function calculateInterest() external returns (uint256);

    /// @notice check an vault for over-collateralization. returns false if amount borrowed is greater than borrowing power.
    /// @param id the vault to check
    /// @return true = vault over-collateralized; false = vault under-collaterlized
    function checkVault(uint96 id) external view returns (bool);

    /// @notice liquidate an underwater vault
    /// @notice vaults may be liquidated up to the point where they are exactly solvent
    /// @param id the vault to liquidate
    /// @param assetAddress the token the liquidator wishes to liquidate
    /// @param tokensToLiquidate  number of tokens to liquidate
    /// @dev pays interest before liquidation
    function liquidateVault(
        uint96 id,
        address assetAddress,
        uint256 tokensToLiquidate
    ) external returns (uint256);

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

    /// @notice repay all of a vault's USDi. anyone may repay a vault's liabilities
    /// @param id the vault to repay
    /// @dev pays interest
    function repayAllUSDi(uint96 id) external;

    /// @notice get the amount of tokens regsitered in the system
    /// @return the amount of tokens registered in the system
    function tokensRegistered() external view returns (uint256);

    /// @notice calculate amount of tokens to liquidate for a vault
    /// @param id the vault to get info for
    /// @param asset_address the token to calculate how many tokens to liquidate
    /// @return - amount of tokens liquidatable
    /// @notice the amount of tokens owed is a moving target and changes with each block as pay_interest is called
    /// @notice this function can serve to give an indication of how many tokens can be liquidated
    /// @dev all this function does is call _liquidationMath with 2**256-1 as the amount
    function tokensToLiquidate(uint96 id, address asset_address) external view returns (uint256);

    /// @notice get vault address of id
    /// @return the address of vault
    function vaultAddress(uint96 id) external view returns (address);

    /// @notice get vault borrowing power for vault
    /// @param id id of vault
    /// @return amount of USDi the vault can borrow
    /// @dev implementation in get_vault_borrowing_power
    function vaultBorrowingPower(uint96 id) external view returns (uint192);

    /// @notice get vault liability of vault
    /// @param id id of vault
    /// @return amount of USDi the vault owes
    /// @dev implementation _vaultLiability
    function vaultLiability(uint96 id) external view returns (uint192);

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
