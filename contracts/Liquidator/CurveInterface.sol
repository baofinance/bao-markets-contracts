// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.1;

interface ICurve {
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256);

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint256);
}