// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITreasuryWithdraw {
    function liquidityWithdraw(address to, uint256 amount) external;

    function foundationWithdraw(address to, uint256 amount) external;

    function marketingWithdraw(address to, uint256 amount) external;

    function tokenSaleWithdraw(address to, uint256 amount) external;
}
