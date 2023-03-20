// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {BaseInterestProtocolTest} from "../BaseInterestProtocolTest.t.sol";
import {CappedGovToken} from "ip-contracts/lending/CappedGovToken.sol";
import {ChainlinkOracleRelay} from "ip-contracts/oracle/External/ChainlinkOracleRelay.sol";
import {ChainlinkTokenOracleRelay} from "ip-contracts/oracle/External/ChainlinkTokenOracleRelay.sol";
import {UniswapV3OracleRelay} from "ip-contracts/oracle/External/UniswapV3OracleRelay.sol";
import {UniswapV3TokenOracleRelay} from "ip-contracts/oracle/External/UniswapV3TokenOracleRelay.sol";
import {AnchoredViewV2} from "ip-contracts/oracle/Logic/AnchoredViewV2.sol";

import {GenericListing} from "../../listings/GenericListing.sol";
import {IPGovernance, IPEthereum} from "../../address-book/IPAddressBook.sol";

contract GenericListingTest is Test {
    address public constant IPT_WHALE = 0x95Bc377F540E504F666671177E5d80bf7c21ab6F;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 16819412);
    }
}

contract DeployCappedtoken is GenericListingTest {
    address public constant ONEINCH = 0x111111111117dC0aa78b770fA6A738034120C302;

    function test_revertsIf_calledWithEmptyName() public {
        vm.expectRevert(GenericListing.NonEmptyName.selector);
        GenericListing.deployCappedToken(GenericListing.ListingData({tokenName: "", underlying: address(0), cap: 0}));
    }

    function test_revertsIf_calledWithAddress0x() public {
        vm.expectRevert(GenericListing.Invalid0xAddress.selector);
        GenericListing.deployCappedToken(
            GenericListing.ListingData({tokenName: "TKN", underlying: address(0), cap: 0})
        );
    }

    function test_revertsIf_calledWithZeroCap() public {
        vm.expectRevert(GenericListing.InvalidCap.selector);
        GenericListing.deployCappedToken(
            GenericListing.ListingData({tokenName: "TKN", underlying: makeAddr("TKN"), cap: 0})
        );
    }

    function test_deploysNewCappedToken() public {
        uint256 proposedCap = 1_000_000;
        address cappedToken = GenericListing.deployCappedToken(
            GenericListing.ListingData({tokenName: "1INCH", underlying: ONEINCH, cap: proposedCap})
        );
        CappedGovToken token = CappedGovToken(cappedToken);
        assertEq(token.getCap(), proposedCap * 1e18);
        assertEq(address(token._underlying()), ONEINCH);
        assertEq(keccak256(abi.encodePacked("Capped 1INCH")), keccak256(abi.encodePacked(token.name())));
        assertEq(keccak256(abi.encodePacked("c1INCH")), keccak256(abi.encodePacked(token.symbol())));
    }
}

contract DeployChainlinkOracle is GenericListingTest {
    function test_revertsIf_calledWithAddress0x() public {
        vm.expectRevert(GenericListing.Invalid0xAddress.selector);
        GenericListing.deployChainlinkOracle(
            GenericListing.ChainlinkOracleData({oracle: address(0), ethOracle: false, mul: 1, div: 1})
        );
    }

    function test_deploysNewChainlinkOracle() public {
        address oracleAddress = GenericListing.deployChainlinkOracle(
            GenericListing.ChainlinkOracleData({
                oracle: 0xec1D1B3b0443256cc3860e24a46F108e699484Aa, // MKR/USD
                ethOracle: false,
                mul: 1,
                div: 1
            })
        );
        ChainlinkOracleRelay oracle = ChainlinkOracleRelay(oracleAddress);
        assertEq(oracle._divide(), 1);
        assertEq(oracle._multiply(), 1);
        assertEq(oracle.currentValue(), 89225360391);
    }

    function test_deploysNewChainlinkTokenOracle() public {
        address oracleAddress = GenericListing.deployChainlinkOracle(
            GenericListing.ChainlinkOracleData({
                oracle: 0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b, // BAL/ETH
                ethOracle: true,
                mul: 1,
                div: 1
            })
        );
        ChainlinkTokenOracleRelay oracle = ChainlinkTokenOracleRelay(oracleAddress);
        assertEq(oracle._divide(), 1);
        assertEq(oracle._multiply(), 1);
        assertEq(oracle.currentValue(), 6331294624430814066);
    }
}

contract DeployUniswapV3Oracle is GenericListingTest {
    function test_revertsIf_calledWithAddress0x() public {
        vm.expectRevert(GenericListing.Invalid0xAddress.selector);
        GenericListing.deployUniswapV3Oracle(
            GenericListing.UniswapV3OracleData({
                lookback: 14400,
                pool: address(0),
                ethOracle: false,
                quoteTokenIsToken0: false,
                mul: 1,
                div: 1
            })
        );
    }

    function test_deploysNewUniswapV3TokenOracle() public {
        address oracleAddress = GenericListing.deployUniswapV3Oracle(
            GenericListing.UniswapV3OracleData({
                lookback: 14400,
                pool: 0xe8c6c9227491C0a8156A0106A0204d881BB7E531,
                ethOracle: true,
                quoteTokenIsToken0: false,
                mul: 1,
                div: 1
            })
        );
        UniswapV3TokenOracleRelay oracle = UniswapV3TokenOracleRelay(oracleAddress);
        assertEq(oracle._div(), 1);
        assertEq(oracle._mul(), 1);
        assertEq(oracle._lookback(), 14400);
        assertEq(address(oracle._pool()), 0xe8c6c9227491C0a8156A0106A0204d881BB7E531);
        assertEq(oracle.currentValue(), 886284359793196292112);
    }
}

contract DeployAnchoredOracle is GenericListingTest {
    function test_revertsIf_calledWithAddress0xMainOracle() public {
        vm.expectRevert(GenericListing.Invalid0xAddress.selector);
        GenericListing.deployAnchoredOracle(
            GenericListing.AnchoredViewRelayData({anchor: address(0), main: address(0), numerator: 1, denominator: 1})
        );
    }

    function test_revertsIf_calledWithAddress0xAnchorOracle() public {
        vm.expectRevert(GenericListing.Invalid0xAddress.selector);
        GenericListing.deployAnchoredOracle(
            GenericListing.AnchoredViewRelayData({
                anchor: address(0),
                main: makeAddr("main"),
                numerator: 1,
                denominator: 1
            })
        );
    }

    function test_deployedAnchoredRelay() public {
        address oracleAddress = GenericListing.deployAnchoredOracle(
            GenericListing.AnchoredViewRelayData({
                anchor: 0xcA9e15Eb362388FFC537280fAe93f35b4A3f230c,
                main: 0x706d1bb99d8ed5B0c02c5e235D8E3f2a406Ad429,
                numerator: 25,
                denominator: 100
            })
        );
        AnchoredViewV2 oracle = AnchoredViewV2(oracleAddress);
        assertEq(oracle._mainAddress(), 0x706d1bb99d8ed5B0c02c5e235D8E3f2a406Ad429);
        assertEq(oracle._anchorAddress(), 0xcA9e15Eb362388FFC537280fAe93f35b4A3f230c);
        assertEq(oracle._widthDenominator(), 100);
        assertEq(oracle._widthNumerator(), 25);
        assertEq(oracle.currentValue(), 115261552567500000000000);
    }
}

contract Propose is GenericListingTest {
    function test_revertsIf_noTargetsProvided() public {
        vm.expectRevert(GenericListing.InvalidInput.selector);
        GenericListing.propose(
            GenericListing.ProposalData({
                targets: new address[](0),
                values: new uint256[](0),
                signatures: new string[](0),
                calldatas: new bytes[](0),
                description: "My proposal",
                emergency: false
            })
        );
    }

    function test_revertsIf_noDescriptionProvided() public {
        vm.expectRevert(GenericListing.NoDescriptionProvided.selector);
        GenericListing.propose(
            GenericListing.ProposalData({
                targets: new address[](0),
                values: new uint256[](0),
                signatures: new string[](0),
                calldatas: new bytes[](0),
                description: "",
                emergency: false
            })
        );
    }

    function test_revertsIf_differentArraySizesProvided() public {
        vm.expectRevert(GenericListing.InvalidInput.selector);
        address[] memory targetsArray = new address[](1);
        targetsArray[0] = makeAddr("targets");
        GenericListing.propose(
            GenericListing.ProposalData({
                targets: targetsArray,
                values: new uint256[](0),
                signatures: new string[](0),
                calldatas: new bytes[](0),
                description: "My proposal",
                emergency: false
            })
        );
    }

    function test_revertsIf_msgSenderDoesNotHaveVotes() public {
        address[] memory targets = new address[](1);
        targets[0] = address(IPEthereum.ORACLE);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        string[] memory signatures = new string[](1);
        signatures[0] = "setRelay(address,address)";

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encode(makeAddr("CappedToken"), makeAddr("Anchor"));

        vm.expectRevert("votes below proposal threshold");
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
    }

    function test_createsProposal() public {
        // Pre-proposal assertions
        assertEq(IPGovernance.GOV.proposalCount(), 19);

        address[] memory targets = new address[](1);
        targets[0] = address(IPEthereum.ORACLE);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        string[] memory signatures = new string[](1);
        signatures[0] = "setRelay(address,address)";

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encode(makeAddr("CappedToken"), makeAddr("Anchor"));

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

        assertEq(IPGovernance.GOV.proposalCount(), 20);
    }
}

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
        assertEq(IPEthereum.VAULT_CONTROLLER.tokensRegistered(), 14);

        uint256 proposedCap = 5_400_000;
        uint256 proposalId = _createMKRProposal(underlyingToken, proposedCap);

        _passVoteAndExecute(proposalId);

        assertEq(IPGovernance.GOV.proposalCount(), 20);
        assertEq(IPEthereum.VAULT_CONTROLLER.tokensRegistered(), 15);

        address newToken = IPEthereum.VAULT_CONTROLLER._enabledTokens(14);

        CappedGovToken token = CappedGovToken(newToken);
        assertEq(token.getCap(), proposedCap * 1e18);
        assertEq(address(token._underlying()), underlyingToken);
        assertEq(keccak256(abi.encodePacked("Capped MKR")), keccak256(abi.encodePacked(token.name())));
        assertEq(keccak256(abi.encodePacked("cMKR")), keccak256(abi.encodePacked(token.symbol())));

        vm.startPrank(msg.sender);
        IPEthereum.VAULT_CONTROLLER.mintVault();
        uint96 vaultId = IPEthereum.VAULT_CONTROLLER.vaultsMinted();
        IPEthereum.VOTING_VAULT_CONTROLLER.mintVault(vaultId);
        vm.stopPrank();

        _deposit(token, msg.sender, 1e18, vaultId);
        _withdraw(token, msg.sender, vaultId);

        assertEq(IPEthereum.VAULT_CONTROLLER.vaultLiability(vaultId), 0);
        assertEq(IPEthereum.VAULT_CONTROLLER.vaultBorrowingPower(vaultId), 0);

        _deposit(token, msg.sender, 1e18, vaultId);
        _borrow(msg.sender, 5e17, vaultId);
        _repay(msg.sender, vaultId);

        _delegate(token, msg.sender, vaultId, MKR_WHALE);
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
        targets[0] = address(IPEthereum.ORACLE);
        targets[1] = address(IPEthereum.VAULT_CONTROLLER);
        targets[2] = address(IPEthereum.VOTING_VAULT_CONTROLLER);

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
