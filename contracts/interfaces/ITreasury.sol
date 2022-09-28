// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITreasury {
    function getTeamReleased() external view returns (uint256);

    function getLiquidityReleased() external view returns (uint256);

    function getFoundationReleased() external view returns (uint256);

    function getMarketingReleased() external view returns (uint256);

    function getTokenSaleReleased() external view returns (uint256);

    function liquidityWithdraw(
        address token,
        address to,
        uint256 amount
    ) external;

    function foundationWithdraw(
        address token,
        address to,
        uint256 amount
    ) external;

    function marketingWithdraw(
        address token,
        address to,
        uint256 amount
    ) external;

    function tokenSaleWithdraw(
        address token,
        address to,
        uint256 amount
    ) external;
}
