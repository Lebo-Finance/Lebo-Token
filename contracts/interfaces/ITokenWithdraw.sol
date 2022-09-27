// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITokenWithdraw {
    function liquidityWithdraw(address to, uint256 amount)
        external
        returns (bool);

    function foundationWithdraw(address to, uint256 amount)
        external
        returns (bool);

    function marketingWithdraw(address to, uint256 amount)
        external
        returns (bool);

    function tokenSaleWithdraw(address to, uint256 amount)
        external
        returns (bool);
}
