// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {VaultMKR, VoteDelegate} from "../../upgrades/VaultMKR.sol";
import {IERC20} from "ip-contracts/_external/IERC20.sol";
import {IPMainnet} from "../../address-book/IPAddressBook.sol";

contract VaultMKRTest is Test {
    uint96 internal constant VAULT_ID = 999;
    address internal constant DELEGATEE = 0x4C28d8402ac01E5d623e4A5438535369770Fe407;
    address internal constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16819412);
    }

    function test_delegateTo() public {
        uint256 delegateAmount = 5e18;
        VaultMKR vault = new VaultMKR(VAULT_ID, msg.sender, address(IPMainnet.VAULT_CONTROLLER));
        assertEq(IERC20(MKR).balanceOf(address(vault)), 0);
        deal(MKR, address(vault), 10e18);

        uint256 balanceVaultBefore = IERC20(MKR).balanceOf(address(vault));
        assertEq(IERC20(MKR).balanceOf(address(vault)), 10e18);

        vm.startPrank(msg.sender);
        vault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);
        vm.stopPrank();

        assertEq(IERC20(MKR).balanceOf(address(vault)), balanceVaultBefore - delegateAmount);
        assertEq(VoteDelegate(DELEGATEE).stake(address(vault)), delegateAmount);
    }

    function test_undelegateFrom_revertsInsufficientStake() public {
        uint256 delegateAmount = 5e18;
        VaultMKR vault = new VaultMKR(VAULT_ID, msg.sender, address(IPMainnet.VAULT_CONTROLLER));
        deal(MKR, address(vault), 10e18);

        vm.startPrank(msg.sender);
        vault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);
        vm.stopPrank();

        assertEq(VoteDelegate(DELEGATEE).stake(address(vault)), delegateAmount);

        vm.expectRevert("VoteDelegate/insufficient-stake");
        vm.startPrank(msg.sender);
        vault.undelegateMKRLike(DELEGATEE, delegateAmount + 1);
        vm.stopPrank();
    }

    function test_undelegateFrom_success() public {
        uint256 delegateAmount = 5e18;
        VaultMKR vault = new VaultMKR(VAULT_ID, msg.sender, address(IPMainnet.VAULT_CONTROLLER));
        assertEq(IERC20(MKR).balanceOf(address(vault)), 0);
        deal(MKR, address(vault), 10e18);

        uint256 balanceVaultBefore = IERC20(MKR).balanceOf(address(vault));
        assertEq(IERC20(MKR).balanceOf(address(vault)), 10e18);

        vm.startPrank(msg.sender);
        vault.delegateMKRLikeTo(DELEGATEE, MKR, delegateAmount);
        vm.stopPrank();

        assertEq(IERC20(MKR).balanceOf(address(vault)), balanceVaultBefore - delegateAmount);
        assertEq(VoteDelegate(DELEGATEE).stake(address(vault)), delegateAmount);

        vm.startPrank(msg.sender);
        vault.undelegateMKRLike(DELEGATEE, delegateAmount);
        vm.stopPrank();

        assertEq(IERC20(MKR).balanceOf(address(vault)), balanceVaultBefore);
        assertEq(VoteDelegate(DELEGATEE).stake(address(vault)), 0);
    }
}
