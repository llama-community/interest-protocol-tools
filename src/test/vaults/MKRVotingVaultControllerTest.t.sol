// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "ip-contracts/_external/IERC20.sol";

import {MKRVotingVaultController} from "../../upgrades/MKRVotingVaultController.sol";
import {CappedMkrToken} from "../../upgrades/CappedMkrToken.sol";
import {IPMainnet, IPGovernance} from "../../address-book/IPAddressBook.sol";

contract MKRVotingVaultControllerTest is Test {
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

    function test_registerUnderlying() public {
        votingController.registerUnderlying(underlyingToken, address(token));
    }

    function test_retrieveUnderlying_revertsIfInvalidVotingVault() public {
        vm.expectRevert(MKRVotingVaultController.InvalidMKRVotingVault.selector);
        votingController.retrieveUnderlying(100, address(0), address(token));
    }

    function test_retrieveUnderlying_revertsIfCallerNotCappedToken() public {
        IPMainnet.VAULT_CONTROLLER.mintVault();
        uint96 vaultId = IPMainnet.VAULT_CONTROLLER.vaultsMinted();
        votingController.mintVault(vaultId);

        address votingVault = votingController.votingVaultAddress(vaultId);
        address recipient = makeAddr("recipient");

        vm.expectRevert(MKRVotingVaultController.OnlyCappedToken.selector);
        votingController.retrieveUnderlying(100, votingVault, recipient);
    }

    function test_retrieveUnderlying_SUPERMAN() public {
        votingController.registerUnderlying(underlyingToken, address(token));

        IPMainnet.VAULT_CONTROLLER.mintVault();
        uint96 vaultId = IPMainnet.VAULT_CONTROLLER.vaultsMinted();
        votingController.mintVault(vaultId);

        address votingVault = votingController.votingVaultAddress(vaultId);
        address recipient = makeAddr("recipient");

        deal(underlyingToken, votingVault, 100);

        vm.startPrank(address(token));
        votingController.retrieveUnderlying(100, votingVault, recipient);
        vm.stopPrank();
    }
}
