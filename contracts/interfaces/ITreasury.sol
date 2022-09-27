// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITreasury {
    function getLiquidityTotalAmount() external view returns (uint256);

    function getFoundationTotalAmount() external view returns (uint256);

    function getMarketingTotalAmount() external view returns (uint256);

    function getTokenSaleTotalAmount() external view returns (uint256);
}
