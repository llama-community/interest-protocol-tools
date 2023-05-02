// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CappedMkrToken} from "../upgrades/CappedMkrToken.sol";
import {IPMainnet, IPGovernance} from "../address-book/IPAddressBook.sol";
import {TransparentUpgradeableProxy} from "ip-contracts/_external/ozproxy/transparent/TransparentUpgradeableProxy.sol";
import {ChainlinkOracleRelay} from "ip-contracts/oracle/External/ChainlinkOracleRelay.sol";
import {ChainlinkTokenOracleRelay} from "ip-contracts/oracle/External/ChainlinkTokenOracleRelay.sol";
import {UniswapV3OracleRelay} from "ip-contracts/oracle/External/UniswapV3OracleRelay.sol";
import {UniswapV3TokenOracleRelay} from "ip-contracts/oracle/External/UniswapV3TokenOracleRelay.sol";
import {AnchoredViewV2} from "ip-contracts/oracle/Logic/AnchoredViewV2.sol";

library GenericListing {
    error Invalid0xAddress();
    error InvalidCap();
    error InvalidInput();
    error NoDescriptionProvided();
    error NonEmptyName();

    struct ListingData {
        string tokenName;
        address underlying;
        uint256 cap;
    }

    struct ChainlinkOracleData {
        address oracle;
        bool ethOracle;
        uint256 mul;
        uint256 div;
    }

    struct UniswapV3OracleData {
        uint32 lookback;
        address pool;
        bool quoteTokenIsToken0;
        bool ethOracle;
        uint256 mul;
        uint256 div;
    }

    struct AnchoredViewRelayData {
        address anchor;
        address main;
        uint256 numerator;
        uint256 denominator;
    }

    struct ProposalData {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        string description;
        bool emergency;
    }

    function propose(ProposalData memory data) internal {
        if (bytes(data.description).length < 1) {
            revert NoDescriptionProvided();
        }

        uint256 targetsLength = data.targets.length;
        if (targetsLength == 0) {
            revert InvalidInput();
        }

        if (
            targetsLength != data.values.length ||
            targetsLength != data.signatures.length ||
            targetsLength != data.calldatas.length
        ) {
            revert InvalidInput();
        }

        IPGovernance.GOV.propose(
            data.targets,
            data.values,
            data.signatures,
            data.calldatas,
            data.description,
            data.emergency
        );
    }

    function deployCappedToken(ListingData memory data) internal returns (address) {
        if (bytes(data.tokenName).length < 1) {
            revert NonEmptyName();
        }
        if (data.underlying == address(0)) {
            revert Invalid0xAddress();
        }
        if (data.cap == 0) {
            revert InvalidCap();
        }
        CappedMkrToken token = new CappedMkrToken();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(token), IPMainnet.PROXY_ADMIN, "");
        CappedMkrToken cappedToken = CappedMkrToken(address(proxy));
        string memory name = string(string.concat("Capped ", bytes(data.tokenName)));
        string memory symbol = string(string.concat("c", bytes(data.tokenName)));

        cappedToken.initialize(
            name,
            symbol,
            data.underlying,
            address(IPMainnet.VAULT_CONTROLLER),
            address(IPMainnet.VOTING_VAULT_CONTROLLER)
        );
        cappedToken.setCap(data.cap * 1e18);
        cappedToken.transferOwnership(address(IPGovernance.GOV));

        return address(cappedToken);
    }

    function deployChainlinkOracle(ChainlinkOracleData memory data) internal returns (address) {
        if (data.oracle == address(0)) {
            revert Invalid0xAddress();
        }
        if (data.ethOracle) {
            ChainlinkTokenOracleRelay oracle = new ChainlinkTokenOracleRelay(data.oracle, data.mul, data.div);
            return address(oracle);
        } else {
            ChainlinkOracleRelay oracle = new ChainlinkOracleRelay(data.oracle, data.mul, data.div);
            return address(oracle);
        }
    }

    function deployUniswapV3Oracle(UniswapV3OracleData memory data) internal returns (address) {
        if (data.pool == address(0)) {
            revert Invalid0xAddress();
        }
        if (data.ethOracle) {
            UniswapV3TokenOracleRelay oracle = new UniswapV3TokenOracleRelay(
                data.lookback,
                data.pool,
                data.quoteTokenIsToken0,
                data.mul,
                data.div
            );
            return address(oracle);
        } else {
            UniswapV3OracleRelay oracle = new UniswapV3OracleRelay(
                data.lookback,
                data.pool,
                data.quoteTokenIsToken0,
                data.mul,
                data.div
            );
            return address(oracle);
        }
    }

    function deployAnchoredOracle(AnchoredViewRelayData memory data) internal returns (address) {
        if (data.anchor == address(0) || data.main == address(0)) {
            revert Invalid0xAddress();
        }
        AnchoredViewV2 anchor = new AnchoredViewV2(data.anchor, data.main, data.numerator, data.denominator);
        return address(anchor);
    }
}
