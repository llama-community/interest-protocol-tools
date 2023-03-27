// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "ip-contracts/_external/IERC20.sol";
import {CappedGovToken} from "ip-contracts/lending/CappedGovToken.sol";
import {Vault} from "ip-contracts/lending/Vault.sol";
import {ProposalState} from "ip-contracts/governance/governor/Structs.sol";

import {IPGovernance, IPMainnet} from "../address-book/IPAddressBook.sol";

contract BaseInterestProtocolTest is Test {
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant USDI_WHALE = 0x95Bc377F540E504F666671177E5d80bf7c21ab6F;

    function _borrow(
        address user,
        uint192 amount,
        uint96 vaultId
    ) internal {
        vm.startPrank(user);
        assertEq(IERC20(address(IPMainnet.USDIToken)).balanceOf(user), 0);
        IPMainnet.VAULT_CONTROLLER.borrowUsdi(vaultId, amount);
        assertEq(IERC20(address(IPMainnet.USDIToken)).balanceOf(user), amount);
        assertApproxEqAbs(IPMainnet.VAULT_CONTROLLER.vaultLiability(vaultId), amount, 1e15); // Within 0.001 (1e15)
        vm.stopPrank();
    }

    function _delegate(
        CappedGovToken token,
        address user,
        uint96 vaultId,
        address to
    ) internal {
        vm.startPrank(user);
        Vault(IPMainnet.VAULT_CONTROLLER.vaultAddress(vaultId)).delegateCompLikeTo(to, address(token._underlying()));
        vm.stopPrank();
    }

    function _deposit(
        CappedGovToken token,
        address user,
        uint256 amount,
        uint96 vaultId
    ) internal {
        vm.startPrank(user);
        uint256 cappedTokenBefore = IERC20(address(token)).balanceOf(user);
        deal(address(token._underlying()), user, amount);
        IERC20(address(token._underlying())).approve(address(token), amount);
        token.deposit(amount, vaultId);
        assertEq(token.balanceOf(user), 0);
        assertEq(token.balanceOf(IPMainnet.VAULT_CONTROLLER.vaultAddress(vaultId)), cappedTokenBefore + amount);
        vm.stopPrank();
    }

    function _liquidationFlow(
        CappedGovToken token,
        address user,
        uint96 vaultId
    ) public {
        vm.startPrank(user);
        assertEq(IPMainnet.VAULT_CONTROLLER.vaultLiability(vaultId), 0);
        uint192 borrowingPower = IPMainnet.VAULT_CONTROLLER.vaultBorrowingPower(vaultId);
        IPMainnet.VAULT_CONTROLLER.borrowUsdi(vaultId, borrowingPower);
        assertApproxEqAbs(IPMainnet.VAULT_CONTROLLER.vaultLiability(vaultId), borrowingPower, 1e15); // Within 0.001 (1e15)
        vm.stopPrank();

        _increaseInterestRate(token);
        assertTrue(IPMainnet.VAULT_CONTROLLER.checkVault(vaultId));
        vm.warp(block.timestamp + 3600 * 24 * 7 * 10); // Fast-forward 10-weeks

        IPMainnet.VAULT_CONTROLLER.calculateInterest();
        assertFalse(IPMainnet.VAULT_CONTROLLER.checkVault(vaultId));

        address vaultAddress = IPMainnet.VAULT_CONTROLLER.vaultAddress(vaultId);
        vm.expectRevert("over-withdrawal");
        vm.startPrank(user);
        Vault(vaultAddress).withdrawErc20(address(token), 1e18);
        assertGt(IPMainnet.VAULT_CONTROLLER.amountToSolvency(vaultId), 0);
        vm.stopPrank();

        _liquidate(token, vaultAddress, vaultId);
        _repay(user, vaultId);
    }

    function _repay(address user, uint96 vaultId) internal {
        vm.startPrank(user);
        IERC20(address(IPMainnet.USDIToken)).approve(
            address(IPMainnet.VAULT_CONTROLLER),
            IERC20(address(IPMainnet.USDIToken)).balanceOf(user)
        );
        IPMainnet.VAULT_CONTROLLER.repayAllUSDi(vaultId);
        assertEq(IPMainnet.VAULT_CONTROLLER.vaultLiability(vaultId), 0);
        vm.stopPrank();
    }

    function _withdraw(
        CappedGovToken token,
        address user,
        uint96 vaultId
    ) internal {
        vm.startPrank(user);
        uint256 amountToWithdraw = token.balanceOf(IPMainnet.VAULT_CONTROLLER.vaultAddress(vaultId));
        uint256 underlyingBalanceBefore = IERC20(address(token._underlying())).balanceOf(user);
        Vault(IPMainnet.VAULT_CONTROLLER.vaultAddress(vaultId)).withdrawErc20(address(token), amountToWithdraw);
        assertEq(IERC20(address(token._underlying())).balanceOf(user), underlyingBalanceBefore + amountToWithdraw);
        assertEq(token.balanceOf(IPMainnet.VAULT_CONTROLLER.vaultAddress(vaultId)), 0);
        vm.stopPrank();
    }

    /// @dev Check getPriorVotes of address at:
    /// https://etherscan.io/address/0xd909C5862Cdb164aDB949D92622082f0092eFC3d#readProxyContract
    function _passVoteAndExecute(uint256 proposalId, address[] memory voters) internal {
        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Pending);

        vm.roll(block.number + IPGovernance.GOV.votingDelay() + 1);
        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Active);

        for (uint256 i = 0; i < voters.length; ++i) {
            vm.startPrank(voters[i]);
            IPGovernance.GOV.castVote(proposalId, 1);
            vm.stopPrank();
        }

        vm.roll(block.number + IPGovernance.GOV.votingPeriod() + 1);
        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Succeeded);

        IPGovernance.GOV.queue(proposalId);
        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Queued);

        vm.warp(block.timestamp + IPGovernance.GOV.proposalTimelockDelay());
        IPGovernance.GOV.execute(proposalId);

        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Executed);
    }

    function _liquidate(
        CappedGovToken token,
        address user,
        uint96 vaultId
    ) private {
        uint256 tokensToLiquidate = IPMainnet.VAULT_CONTROLLER.tokensToLiquidate(vaultId, address(token));
        assertGt(tokensToLiquidate, 0);
        uint256 price = IPMainnet.ORACLE.getLivePrice(address(token));
        assertGt(price, 0);

        uint256 startBalLiquidator = token.balanceOf(USDI_WHALE);
        uint256 startingSupply = token.totalSupply();
        uint256 cappedTokenBalance = token.balanceOf(user);

        vm.startPrank(USDI_WHALE);
        IPMainnet.VAULT_CONTROLLER.liquidateVault(vaultId, address(token), tokensToLiquidate);
        vm.stopPrank();

        assertApproxEqAbs(startBalLiquidator + tokensToLiquidate, token.balanceOf(USDI_WHALE), 1e18);
        assertApproxEqAbs(startingSupply - tokensToLiquidate, token.totalSupply(), 1e18);
        assertApproxEqAbs(cappedTokenBalance - tokensToLiquidate, token.balanceOf(user), 1e18);
    }

    function _increaseInterestRate(CappedGovToken token) private {
        address newUser = makeAddr("new-borrowing-user");
        vm.startPrank(newUser);
        IPMainnet.VAULT_CONTROLLER.mintVault();
        uint96 vaultId = IPMainnet.VAULT_CONTROLLER.vaultsMinted();
        IPMainnet.VOTING_VAULT_CONTROLLER.mintVault(vaultId);
        vm.stopPrank();

        _deposit(token, newUser, 1e18, vaultId);
        _borrow(newUser, IPMainnet.VAULT_CONTROLLER.vaultBorrowingPower(vaultId), vaultId);
    }
}
