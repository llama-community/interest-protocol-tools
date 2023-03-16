// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IPEthereum, IPGovernance} from "../../address-book/IPAddressBook.sol";
import {DeployToken} from "../../../script/DeployMKR.s.sol";

contract DeployMKRTest is Test {
    uint256 public initialProposalCount;

    address public constant IPT_WHALE = 0x95Bc377F540E504F666671177E5d80bf7c21ab6F;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16819412);
        initialProposalCount = IPGovernance.GOV.proposalCount();

        DeployToken deploy = new DeployToken();

        vm.startPrank(IPT_WHALE);
        deploy._deployAll();
        vm.stopPrank();
    }

    function test_proposalIsUp() public {
        assertGt(IPGovernance.GOV.proposalCount(), initialProposalCount);
    }
}
