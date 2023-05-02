// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";

import {IERC20} from "ip-contracts/_external/IERC20.sol";

import {CappedMkrToken} from "../../upgrades/CappedMkrToken.sol";
import {MKRVotingVaultController} from "../../upgrades/MKRVotingVaultController.sol";
import {IPMainnet, IPGovernance} from "../../address-book/IPAddressBook.sol";

contract CappedMkrTokenTest is Test {
    address private constant underlyingToken = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

    MKRVotingVaultController internal votingController;
    CappedMkrToken internal token;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16819412);
        votingController = new MKRVotingVaultController();
        votingController.initialize(address(IPMainnet.VAULT_CONTROLLER));

        token = new CappedMkrToken();
        token.initialize(
            "Maker",
            "MKR",
            underlyingToken,
            address(IPMainnet.VAULT_CONTROLLER),
            address(votingController)
        );
    }

    function test_transferFrom_returnsFalse() public {
        deal(underlyingToken, msg.sender, 1e18);
        bool result = token.transferFrom(msg.sender, makeAddr("addy"), 1e18);
        assertFalse(result);
    }

    function test_getCap_notSet() public {
        assertEq(token.getCap(), 0);
    }

    function test_setCap_revertsIfNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(msg.sender);
        token.setCap(100e18);
    }

    function test_setCap_successful() public {
        uint256 newCap = 100e18;
        token.setCap(newCap);
        assertEq(token.getCap(), newCap);
    }

    function test_deposit_revertsIfDepositZero() public {
        vm.expectRevert(CappedMkrToken.CannotDepositZero.selector);
        token.deposit(0, 10000);
    }

    function test_deposit_revertsIfNoVaultYet() public {
        vm.expectRevert(CappedMkrToken.InvalidMKRVotingVault.selector);
        token.deposit(100, 10000);
    }

    function test_deposit_revertsIfOverCap() public {
        IPMainnet.VAULT_CONTROLLER.mintVault();
        uint96 vaultId = IPMainnet.VAULT_CONTROLLER.vaultsMinted();
        votingController.mintVault(vaultId);

        vm.expectRevert(CappedMkrToken.CapReached.selector);
        token.deposit(100, vaultId);
    }

    function test_deposit_revertsIfInsufficientAllowance() public {
        uint256 newCap = 100e18;
        token.setCap(newCap);

        IPMainnet.VAULT_CONTROLLER.mintVault();
        uint96 vaultId = IPMainnet.VAULT_CONTROLLER.vaultsMinted();
        votingController.mintVault(vaultId);

        vm.expectRevert(CappedMkrToken.InsufficientAllowance.selector);
        token.deposit(100, vaultId);
    }

    function test_deposit() public {
        uint256 newCap = 100e18;
        token.setCap(newCap);

        IPMainnet.VAULT_CONTROLLER.mintVault();
        uint96 vaultId = IPMainnet.VAULT_CONTROLLER.vaultsMinted();
        votingController.mintVault(vaultId);

        deal(underlyingToken, address(this), 100);

        IERC20(underlyingToken).approve(address(token), 100);
        token.deposit(100, vaultId);
    }

    function test_transfer_revertsIfNotValidVault() public {
        vm.expectRevert(CappedMkrToken.OnlyVaults.selector);
        vm.prank(makeAddr("addy"));
        token.transfer(makeAddr("recipient"), 100);
    }

    function test_transfer_successful() public {
        votingController.registerUnderlying(underlyingToken, address(token));

        uint256 newCap = 100e18;
        token.setCap(newCap);

        IPMainnet.VAULT_CONTROLLER.mintVault();
        uint96 vaultId = IPMainnet.VAULT_CONTROLLER.vaultsMinted();
        votingController.mintVault(vaultId);

        deal(underlyingToken, address(this), 100);

        IERC20(underlyingToken).approve(address(token), 100);
        token.deposit(100, vaultId);

        vm.prank(IPMainnet.VAULT_CONTROLLER.vaultAddress(vaultId));
        token.transfer(makeAddr("recipient"), 100);
    }
}
