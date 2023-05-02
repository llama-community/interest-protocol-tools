// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {IERC20} from "ip-contracts/_external/IERC20.sol";
import {Vault} from "ip-contracts/lending/Vault.sol";

import {MKRVotingVault, VoteDelegate} from "../../upgrades/MKRVotingVault.sol";
import {MKRVotingVaultController} from "../../upgrades/MKRVotingVaultController.sol";
import {IPMainnet} from "../../address-book/IPAddressBook.sol";

contract VaultMKRTest is Test {
    uint96 internal constant VAULT_ID = 999;
    address internal constant DELEGATEE = 0x4C28d8402ac01E5d623e4A5438535369770Fe407;
    address internal constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    Vault internal vault;
    MKRVotingVaultController internal votingVaultController;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16819412);
        vault = new Vault(VAULT_ID, address(this), address(IPMainnet.VAULT_CONTROLLER));
        votingVaultController = new MKRVotingVaultController();
        votingVaultController.initialize(address(IPMainnet.VAULT_CONTROLLER));
    }

    function test_delegateTo_revertsOnlyMinter() public {
        uint256 delegateAmount = 5e18;
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        deal(MKR, address(votingVault), 10e18);

        vm.expectRevert(MKRVotingVault.OnlyMinter.selector);
        vm.startPrank(msg.sender);
        votingVault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);
        vm.stopPrank();
    }

    function test_approveBeforeDelegate_noIssuesWithPriorApproval() public {
        uint256 delegateAmount = 5e18;
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        assertEq(IERC20(MKR).balanceOf(address(votingVault)), 0);
        deal(MKR, address(votingVault), 10e18);

        vm.startPrank(address(votingVault));
        IERC20(MKR).approve(DELEGATEE, 3e18);
        vm.stopPrank();

        votingVault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);

        // All allowance has been spent
        assertEq(IERC20(MKR).allowance(msg.sender, DELEGATEE), 0);
    }

    function test_delegateTo() public {
        uint256 delegateAmount = 5e18;
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        assertEq(IERC20(MKR).balanceOf(address(votingVault)), 0);
        deal(MKR, address(votingVault), 10e18);

        uint256 balanceVaultBefore = IERC20(MKR).balanceOf(address(votingVault));
        assertEq(balanceVaultBefore, 10e18);

        votingVault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);

        assertEq(IERC20(MKR).balanceOf(address(votingVault)), balanceVaultBefore - delegateAmount);
        assertEq(VoteDelegate(DELEGATEE).stake(address(votingVault)), delegateAmount);
    }

    function test_delegateTo_multiple() public {
        address DELEGATEE_TWO = 0xB8dF77C3Bd57761bD0C55D2F873d3Aa89b3dA8B7;

        uint256 delegateAmount = 5e18;
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        assertEq(IERC20(MKR).balanceOf(address(votingVault)), 0);
        deal(MKR, address(votingVault), 10e18);

        uint256 balanceVaultBefore = IERC20(MKR).balanceOf(address(votingVault));
        assertEq(balanceVaultBefore, 10e18);

        votingVault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);

        assertEq(IERC20(MKR).balanceOf(address(votingVault)), balanceVaultBefore - delegateAmount);
        assertEq(VoteDelegate(DELEGATEE).stake(address(votingVault)), delegateAmount);

        votingVault.delegateMKRLikeTo(DELEGATEE_TWO, MKR, delegateAmount);

        assertEq(IERC20(MKR).balanceOf(address(votingVault)), 0);
        assertEq(VoteDelegate(DELEGATEE_TWO).stake(address(votingVault)), delegateAmount);
    }

    function test_undelegateFrom_revertsOnlyMinter() public {
        uint256 delegateAmount = 5e18;
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        deal(MKR, address(votingVault), 10e18);

        votingVault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);

        assertEq(VoteDelegate(DELEGATEE).stake(address(votingVault)), delegateAmount);

        vm.expectRevert(MKRVotingVault.OnlyMinter.selector);
        vm.startPrank(msg.sender);
        votingVault.undelegateMKRLike(DELEGATEE, delegateAmount);
        vm.stopPrank();
    }

    function test_undelegateFrom_revertsInsufficientStake() public {
        uint256 delegateAmount = 5e18;
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        deal(MKR, address(votingVault), 10e18);

        votingVault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);

        assertEq(VoteDelegate(DELEGATEE).stake(address(votingVault)), delegateAmount);

        vm.expectRevert("VoteDelegate/insufficient-stake");
        votingVault.undelegateMKRLike(DELEGATEE, delegateAmount + 1);
    }

    function test_undelegateFrom_success() public {
        uint256 delegateAmount = 5e18;
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        assertEq(IERC20(MKR).balanceOf(address(votingVault)), 0);
        deal(MKR, address(votingVault), 10e18);

        uint256 balanceVaultBefore = IERC20(MKR).balanceOf(address(votingVault));
        assertEq(IERC20(MKR).balanceOf(address(votingVault)), 10e18);

        votingVault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);

        assertEq(IERC20(MKR).balanceOf(address(votingVault)), balanceVaultBefore - delegateAmount);
        assertEq(VoteDelegate(DELEGATEE).stake(address(votingVault)), delegateAmount);

        vm.roll(block.number + 1);

        votingVault.undelegateMKRLike(DELEGATEE, delegateAmount);

        assertEq(IERC20(MKR).balanceOf(address(votingVault)), balanceVaultBefore);
        assertEq(VoteDelegate(DELEGATEE).stake(address(votingVault)), 0);
    }

    function test_controllerTransfer_revertsIfNotValidSender() public {
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        vm.expectRevert(MKRVotingVault.OnlyVaultController.selector);
        votingVault.controllerTransfer(MKR, makeAddr("new-address"), 1e18);
    }

    function test_controllerTransfer_success() public {
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        deal(MKR, address(votingVault), 10e18);
        address receiver = makeAddr("new-address");

        assertEq(IERC20(MKR).balanceOf(receiver), 0);

        vm.startPrank(address(IPMainnet.VAULT_CONTROLLER));
        votingVault.controllerTransfer(MKR, receiver, 1e18);
        vm.stopPrank();

        assertEq(IERC20(MKR).balanceOf(receiver), 1e18);
    }

    function test_votingVaultControllerTransfer_revertsIfNotValidSender() public {
        MKRVotingVault votingVault = new MKRVotingVault(
            VAULT_ID,
            address(vault),
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingVaultController)
        );
        deal(MKR, address(votingVault), 10e18);
        address receiver = makeAddr("new-address");
        assertEq(IERC20(MKR).balanceOf(receiver), 0);

        vm.startPrank(address(votingVaultController));
        votingVault.votingVaultControllerTransfer(MKR, receiver, 1e18);
        vm.stopPrank();

        assertEq(IERC20(MKR).balanceOf(receiver), 1e18);
    }
}
