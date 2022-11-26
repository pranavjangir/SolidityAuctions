// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";

contract DutchAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public offerPriceDecrement;

    // TODO: place your code here

    // constructor
    constructor(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _offerPriceDecrement)
             Auction (_sellerAddress, _judgeAddress, _timerAddress, address(0), 0) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        offerPriceDecrement = _offerPriceDecrement;

        // TODO: place your code here
    }


    function bid() public payable{
        // TODO: place your code here
        if (winnerAddress != address(0)) {
            revert(); // We already found a winner.
        }
        uint currentPrice = initialPrice;
        uint curTime = time();
        if (curTime >= biddingPeriod) {
            revert();
        }
        currentPrice = currentPrice - curTime*offerPriceDecrement;
        if (msg.value < currentPrice) {
            revert("Low bid value");
        } else if (msg.value > currentPrice) {
            winnerChange = msg.value - currentPrice;
        }
        winnerAddress = msg.sender;
    }

}
