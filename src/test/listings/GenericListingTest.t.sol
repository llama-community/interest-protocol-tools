// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {GenericListing} from "../../listings/GenericListing.sol";

contract GenericListingTest is Test {}

contract DeployCappedtoken is GenericListingTest {
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
}

contract DeployChainlinkOracle is GenericListingTest {
    function test_revertsIf_calledWithAddress0x() public {
        vm.expectRevert(GenericListing.Invalid0xAddress.selector);
        GenericListing.deployChainlinkOracle(
            GenericListing.ChainlinkOracleData({oracle: address(0), ethOracle: false, mul: 1, div: 1})
        );
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
}
