// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Vault} from "ip-contracts/lending/Vault.sol";
import "ip-contracts/_external/IERC20.sol";
import {MKRLike} from "./MKRLike.sol";

interface TokenLike_1 {
    function approve(address, uint256) external returns (bool);
}

interface VoteDelegate {
    function iou() external view returns (TokenLike_1);

    function stake(address staker) external view returns (uint256);
}

contract VaultMKR is Vault {
    constructor(
        uint96 id_,
        address minter_,
        address controller_address
    ) Vault(id_, minter_, controller_address) {}

    function delegateMKRLikeTo(
        address delegatee,
        address tokenAddress,
        uint256 amount
    ) external onlyMinter {
        IERC20(tokenAddress).approve(delegatee, amount);
        MKRLike(delegatee).lock(amount);
    }

    function undelegateMKRLike(address delegatee, uint256 amount) external onlyMinter {
        TokenLike_1 iou = VoteDelegate(delegatee).iou();
        iou.approve(delegatee, amount);
        MKRLike(delegatee).free(amount);
    }
}
