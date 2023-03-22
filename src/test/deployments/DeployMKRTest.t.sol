// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {BaseInterestProtocolTest} from "../BaseInterestProtocolTest.t.sol";
import {CappedGovToken} from "ip-contracts/lending/CappedGovToken.sol";
import {GenericListing} from "../../listings/GenericListing.sol";
import {IPMainnet, IPGovernance} from "../../address-book/IPAddressBook.sol";

// import {DeployToken} from "../../../script/DeployMKR.s.sol";

contract MKRProposalTest is BaseInterestProtocolTest {
    address private constant MKR_WHALE = 0xA9DDA2045D140Eb7CCD30c4EF6B9901CCb279793;
    address private constant underlyingToken = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address private cappedToken;
    address private oracleOne;
    address private oracleTwo;
    address private anchor;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16819412);
    }

    function test_e2e_MKRProposal() public {
        assertEq(IPGovernance.GOV.proposalCount(), 19);
        assertEq(IPMainnet.VAULT_CONTROLLER.tokensRegistered(), 14);

        uint256 proposedCap = 5_400_000;
        uint256 proposalId = _createMKRProposal(underlyingToken, proposedCap);

        _passVoteAndExecute(proposalId);

        assertEq(IPGovernance.GOV.proposalCount(), 20);
        assertEq(IPMainnet.VAULT_CONTROLLER.tokensRegistered(), 15);

        address newToken = IPMainnet.VAULT_CONTROLLER._enabledTokens(14);

        CappedGovToken token = CappedGovToken(newToken);
        assertEq(token.getCap(), proposedCap * 1e18);
        assertEq(address(token._underlying()), underlyingToken);
        assertEq(keccak256(abi.encodePacked("Capped MKR")), keccak256(abi.encodePacked(token.name())));
        assertEq(keccak256(abi.encodePacked("cMKR")), keccak256(abi.encodePacked(token.symbol())));

        vm.startPrank(msg.sender);
        IPMainnet.VAULT_CONTROLLER.mintVault();
        uint96 vaultId = IPMainnet.VAULT_CONTROLLER.vaultsMinted();
        IPMainnet.VOTING_VAULT_CONTROLLER.mintVault(vaultId);
        vm.stopPrank();

        _deposit(token, msg.sender, 1e18, vaultId);
        _withdraw(token, msg.sender, vaultId);

        assertEq(IPMainnet.VAULT_CONTROLLER.vaultLiability(vaultId), 0);
        assertEq(IPMainnet.VAULT_CONTROLLER.vaultBorrowingPower(vaultId), 0);

        _deposit(token, msg.sender, 1e18, vaultId);
        _borrow(msg.sender, 5e17, vaultId);
        _repay(msg.sender, vaultId);
    }

    function _createMKRProposal(address underlying, uint256 proposedCap) internal returns (uint256) {
        GenericListing.ListingData memory cappedTokenData = GenericListing.ListingData({
            tokenName: "MKR",
            underlying: underlying,
            cap: proposedCap
        });
        cappedToken = GenericListing.deployCappedToken(cappedTokenData);

        GenericListing.ChainlinkOracleData memory chainlinkData = GenericListing.ChainlinkOracleData({
            oracle: 0xec1D1B3b0443256cc3860e24a46F108e699484Aa,
            ethOracle: false,
            mul: 1e10,
            div: 1
        });
        oracleOne = GenericListing.deployChainlinkOracle(chainlinkData);

        GenericListing.UniswapV3OracleData memory uniswapData = GenericListing.UniswapV3OracleData({
            lookback: 14400,
            pool: 0xe8c6c9227491C0a8156A0106A0204d881BB7E531,
            quoteTokenIsToken0: false,
            ethOracle: true,
            mul: 1,
            div: 1
        });
        oracleTwo = GenericListing.deployUniswapV3Oracle(uniswapData);

        GenericListing.AnchoredViewRelayData memory data = GenericListing.AnchoredViewRelayData({
            anchor: oracleTwo,
            main: oracleOne,
            numerator: 25,
            denominator: 100
        });
        anchor = GenericListing.deployAnchoredOracle(data);

        address[] memory targets = new address[](3);
        targets[0] = address(IPMainnet.ORACLE);
        targets[1] = address(IPMainnet.VAULT_CONTROLLER);
        targets[2] = address(IPMainnet.VOTING_VAULT_CONTROLLER);

        uint256[] memory values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;

        string[] memory signatures = new string[](3);
        signatures[0] = "setRelay(address,address)";
        signatures[1] = "registerErc20(address,uint256,address,uint256)";
        signatures[2] = "registerUnderlying(address,address)";

        bytes[] memory calldatas = new bytes[](3);
        calldatas[0] = abi.encode(cappedToken, anchor);
        calldatas[1] = abi.encode(cappedToken, 70e16, cappedToken, 15e16);
        calldatas[2] = abi.encode(underlyingToken, cappedToken);

        vm.startPrank(IPT_WHALE);
        GenericListing.propose(
            GenericListing.ProposalData({
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                description: "My proposal",
                emergency: false
            })
        );
        vm.stopPrank();

        return IPGovernance.GOV.proposalCount();
    }
}
