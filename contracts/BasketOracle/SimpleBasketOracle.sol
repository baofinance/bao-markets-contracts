pragma solidity ^0.8.0;

import "../Liquidator/OpenZeppelinInterfaces.sol";
import "./BasketOracleInterfaces.sol";

contract SimpleBasketOracle is Ownable {
    IExperiPie immutable basket;
    mapping(address => AggregatorInterface) public linkOracles;

    constructor (address _basket) {
        basket = IExperiPie(_basket);
    }

    /**
     * Function to retrieve the price of 1 basket token in USD, scaled 1e18
     *
     * @return usdPrice Price of 1 basket token in USD
     */
    function latestAnswer() external view returns (uint256 usdPrice) {
        address[] memory components = basket.getTokens();

        uint256 marketCapUSD = 0;

        // Gather link prices, component balances, and basket market cap
        for (uint8 i = 0; i < components.length; i++) {
            address component = components[i];
            IERC20 componentToken = IERC20(component);
            AggregatorInterface linkOracle = linkOracles[component];

            marketCapUSD += (
                componentToken.balanceOf(address(basket)) *
                (10 ** (18 - componentToken.decimals())) * // Scale token balance decimals to always be 1e18
                uint256(linkOracle.latestAnswer()) /
                (10 ** linkOracle.decimals())
            );
        }

        usdPrice = marketCapUSD * 1 ether / basket.totalSupply();
        return usdPrice;
    }

    function setTokenOracle(address _token, address _oracle) external onlyOwner {
        linkOracles[_token] = AggregatorInterface(_oracle);
    }

    function removeTokenOracle(address _token) external onlyOwner {
        delete linkOracles[_token];
    }
}
