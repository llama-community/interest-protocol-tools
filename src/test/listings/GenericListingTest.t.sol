// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {ChainlinkOracleRelay} from "ip-contracts/oracle/External/ChainlinkOracleRelay.sol";
import {ChainlinkTokenOracleRelay} from "ip-contracts/oracle/External/ChainlinkTokenOracleRelay.sol";
import {UniswapV3OracleRelay} from "ip-contracts/oracle/External/UniswapV3OracleRelay.sol";
import {UniswapV3TokenOracleRelay} from "ip-contracts/oracle/External/UniswapV3TokenOracleRelay.sol";
import {AnchoredViewV2} from "ip-contracts/oracle/Logic/AnchoredViewV2.sol";

import {GenericListing} from "../../listings/GenericListing.sol";
import {IPGovernance, IPMainnet} from "../../address-book/IPAddressBook.sol";
import {CappedMkrToken} from "../../upgrades/CappedMkrToken.sol";

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
        CappedMkrToken token = CappedMkrToken(cappedToken);
        assertEq(token.getCap(), proposedCap * 1e18);
        assertEq(address(token._underlying()), ONEINCH);
        assertEq(keccak256(abi.encodePacked("Capped 1INCH")), keccak256(abi.encodePacked(token.name())));
        assertEq(keccak256(abi.encodePacked("c1INCH")), keccak256(abi.encodePacked(token.symbol())));
        assertEq(token.owner(), address(IPGovernance.GOV));
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
        targets[0] = address(IPMainnet.ORACLE);

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
        targets[0] = address(IPMainnet.ORACLE);

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
