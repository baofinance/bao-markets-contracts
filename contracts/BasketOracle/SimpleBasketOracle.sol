pragma solidity ^0.8.0;

import "../Liquidator/OpenZeppelinInterfaces.sol";
import "./BasketOracleInterfaces.sol";

contract SimpleBasketOracle is Ownable {
    IBasketFacet immutable basket;
    ILendingRegistry immutable lendingRegistry;
    mapping(address => AggregatorInterface) public linkFeeds;

    constructor (address _basket, address _lendingRegistry) {
        basket = IBasketFacet(_basket);
        lendingRegistry = ILendingRegistry(_lendingRegistry);
    }

    /**
     * Function to retrieve the price of 1 basket token in USD, scaled by 1e18
     *
     * @return usdPrice Price of 1 basket token in USD
     */
    function latestAnswer() external view returns (uint256 usdPrice) {
        address[] memory components = basket.getTokens();

        uint256 marketCapUSD = 0;

        // Gather link prices, component balances, and basket market cap
        for (uint8 i = 0; i < components.length; i++) {
            address component = components[i];
            address underlying = lendingRegistry.wrappedToUnderlying(component);
            IERC20 componentToken = IERC20(component);
            AggregatorInterface linkFeed;

            if (underlying != address(0)) { // Wrapped tokens
                ILendingLogic lendingLogic = ILendingLogic(address(uint160(uint256(lendingRegistry.wrappedToProtocol(component)))));
                linkFeed = linkFeeds[underlying];

                marketCapUSD += (
                    componentToken.balanceOf(address(basket)) *
                    lendingLogic.exchangeRateView(component) /
                    1 ether *
                    (10 ** (18 - componentToken.decimals())) * // Scale token balance decimals to always be 1e18
                    uint256(linkFeed.latestAnswer()) /
                    (10 ** (linkFeed.decimals()))
                );
            } else { // Non-wrapped tokens
                linkFeed = linkFeeds[component];

                marketCapUSD += (
                    componentToken.balanceOf(address(basket)) *
                    (10 ** (18 - componentToken.decimals())) * // Scale token balance decimals to always be 1e18
                    uint256(linkFeed.latestAnswer()) /
                    (10 ** linkFeed.decimals())
                );
            }
        }

        usdPrice = marketCapUSD * 1 ether / basket.totalSupply();
        return usdPrice;
    }

    function setTokenFeed(address _token, address _oracle) external onlyOwner {
        linkFeeds[_token] = AggregatorInterface(_oracle);
    }

    function removeTokenFeed(address _token) external onlyOwner {
        delete linkFeeds[_token];
    }
}
