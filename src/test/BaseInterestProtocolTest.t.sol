// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC20} from "ip-contracts/_external/IERC20.sol";
import {CappedGovToken} from "ip-contracts/lending/CappedGovToken.sol";
import {Vault} from "ip-contracts/lending/Vault.sol";
import {ProposalState} from "ip-contracts/governance/governor/Structs.sol";

import {IPGovernance, IPEthereum} from "../address-book/IPAddressBook.sol";

contract BaseInterestProtocolTest is Test {
    address public constant IPT_WHALE = 0x95Bc377F540E504F666671177E5d80bf7c21ab6F;
    address private constant IPT_VOTING_WHALE_ONE = 0x3Df70ccb5B5AA9c300100D98258fE7F39f5F9908;
    address private constant IPT_VOTING_WHALE_TWO = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address private constant IPT_VOTING_WHALE_THREE = 0x5fee8d7d02B0cfC08f0205ffd6d6B41877c86558;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function _borrow(
        address user,
        uint192 amount,
        uint96 vaultId
    ) internal {
        vm.startPrank(user);
        assertEq(IERC20(address(IPEthereum.USDIToken)).balanceOf(user), 0);
        IPEthereum.VAULT_CONTROLLER.borrowUsdi(vaultId, amount);
        assertEq(IERC20(address(IPEthereum.USDIToken)).balanceOf(user), amount);
        assertApproxEqAbs(IPEthereum.VAULT_CONTROLLER.vaultLiability(vaultId), amount, 1e15); // Within 0.001 (1e15)
        vm.stopPrank();
    }

    function _delegate(
        CappedGovToken token,
        address user,
        uint96 vaultId,
        address to
    ) internal {
        vm.startPrank(user);
        Vault(IPEthereum.VAULT_CONTROLLER.vaultAddress(vaultId)).delegateCompLikeTo(to, address(token._underlying()));
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
        assertEq(token.balanceOf(IPEthereum.VAULT_CONTROLLER.vaultAddress(vaultId)), cappedTokenBefore + amount);
        vm.stopPrank();
    }

    function _repay(address user, uint96 vaultId) internal {
        vm.startPrank(user);
        IERC20(address(IPEthereum.USDIToken)).approve(
            address(IPEthereum.VAULT_CONTROLLER),
            IERC20(address(IPEthereum.USDIToken)).balanceOf(user)
        );
        IPEthereum.VAULT_CONTROLLER.repayAllUSDi(vaultId);
        assertEq(IPEthereum.VAULT_CONTROLLER.vaultLiability(vaultId), 0);
        vm.stopPrank();
    }

    function _withdraw(
        CappedGovToken token,
        address user,
        uint96 vaultId
    ) internal {
        vm.startPrank(user);
        uint256 amountToWithdraw = token.balanceOf(IPEthereum.VAULT_CONTROLLER.vaultAddress(vaultId));
        uint256 underlyingBalanceBefore = IERC20(address(token._underlying())).balanceOf(user);
        Vault(IPEthereum.VAULT_CONTROLLER.vaultAddress(vaultId)).withdrawErc20(address(token), amountToWithdraw);
        assertEq(IERC20(address(token._underlying())).balanceOf(user), underlyingBalanceBefore + amountToWithdraw);
        assertEq(token.balanceOf(IPEthereum.VAULT_CONTROLLER.vaultAddress(vaultId)), 0);
        vm.stopPrank();
    }

    function _passVoteAndExecute(uint256 proposalId) internal {
        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Pending);

        vm.roll(block.number + IPGovernance.GOV.votingDelay() + 1);
        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Active);

        vm.startPrank(0x95Bc377F540E504F666671177E5d80bf7c21ab6F);
        IPGovernance.GOV.castVote(proposalId, 1);
        vm.stopPrank();

        vm.startPrank(IPT_VOTING_WHALE_ONE);
        IPGovernance.GOV.castVote(proposalId, 1);
        vm.stopPrank();

        vm.startPrank(IPT_VOTING_WHALE_TWO);
        IPGovernance.GOV.castVote(proposalId, 1);
        vm.stopPrank();

        vm.startPrank(IPT_VOTING_WHALE_THREE);
        IPGovernance.GOV.castVote(proposalId, 1);
        vm.stopPrank();

        vm.roll(block.number + IPGovernance.GOV.votingPeriod() + 1);
        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Succeeded);

        IPGovernance.GOV.queue(proposalId);
        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Queued);

        vm.warp(block.timestamp + IPGovernance.GOV.proposalTimelockDelay());
        IPGovernance.GOV.execute(proposalId);

        assertTrue(IPGovernance.GOV.state(proposalId) == ProposalState.Executed);
    }
}
