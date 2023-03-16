// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {GenericListing} from "../src/listings/GenericListing.sol";
import {IPEthereum} from "../src/address-book/IPEthereum.sol";

contract DeployToken is Script {
    address private constant underlyingToken = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address private cappedToken;
    address private oracleOne;
    address private oracleTwo;
    address private anchor;

    function run() external {
        vm.startBroadcast();
        _deployAll();
        vm.stopBroadcast();
    }

    function _deployAll() public {
        _deployCappedToken();
        _deployOracles();
        _deployAnchor();
        _propose();
    }

    function _deployCappedToken() internal {
        GenericListing.ListingData memory data = GenericListing.ListingData({
            tokenName: "MKR",
            underlying: underlyingToken,
            cap: 5_400_000
        });
        cappedToken = GenericListing.deployCappedToken(data);
    }

    function _deployOracles() internal {
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
    }

    function _deployAnchor() internal {
        GenericListing.AnchoredViewRelayData memory data = GenericListing.AnchoredViewRelayData({
            anchor: oracleTwo,
            main: oracleOne,
            numerator: 25,
            denominator: 100
        });
        anchor = GenericListing.deployAnchoredOracle(data);
    }

    function _propose() internal {
        GenericListing.propose(
            GenericListing.ProposalData(
                _getTargets(),
                _getValues(),
                _getSignatures(),
                _getCalldatas(),
                "my description", // TODO: Read file from here
                false
            )
        );
    }

    function _getTargets() internal pure returns (address[] memory) {
        address[] memory targets = new address[](3);
        targets[0] = address(IPEthereum.ORACLE);
        targets[1] = address(IPEthereum.VAULT_CONTROLLER);
        targets[2] = address(IPEthereum.VOTING_VAULT_CONTROLLER);
        return targets;
    }

    function _getValues() internal pure returns (uint256[] memory) {
        uint256[] memory values = new uint256[](3);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        return values;
    }

    function _getSignatures() internal pure returns (string[] memory) {
        string[] memory signatures = new string[](3);
        signatures[0] = "setRelay(address,address)";
        signatures[1] = "registerErc20(address,uint256,address,uint256)";
        signatures[2] = "registerUnderlying(address,address)";
        return signatures;
    }

    function _getCalldatas() internal view returns (bytes[] memory) {
        bytes[] memory calldatas = new bytes[](3);
        calldatas[0] = abi.encode(cappedToken, anchor);
        calldatas[1] = abi.encode(cappedToken, 70e16, cappedToken, 15e16);
        calldatas[2] = abi.encode(underlyingToken, cappedToken);
        return calldatas;
    }
}
