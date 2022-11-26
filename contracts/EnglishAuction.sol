// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";

contract EnglishAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public minimumPriceIncrement;
    mapping(address => uint) internal wagers;
    uint internal last_bid_time;

    // TODO: place your code here

    // constructor
    constructor(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _minimumPriceIncrement)
             Auction (_sellerAddress, _judgeAddress, _timerAddress, address(0), 0) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        minimumPriceIncrement = _minimumPriceIncrement;

        // TODO: place your code here
    }

    function bid() public payable{
        if (time() >= last_bid_time + biddingPeriod || msg.value < initialPrice
         || msg.value < winningPrice + minimumPriceIncrement) {
            revert();
        }
        wagers[msg.sender] += msg.value;
        winningPrice = msg.value;
        winnerAddress = msg.sender;
        last_bid_time = time();
    }

    // Need to override the default implementation
    function getWinner() public override view returns (address){
        if (time() >= last_bid_time + biddingPeriod) {
            return winnerAddress;
        } else return address(0);
    }
    
    function withdraw() public override {
        //TODO: place your code here
        if (winnerAddress == address(0)) {
            revert("No winner yet, cannot withdraw");
        }
        // if (msg.sender != winnerAddress && msg.sender != sellerAddress) {
        //     revert("Unauthorized withdraw");
        // }
        // if (msg.sender == winnerAddress && !canWinnerWithdraw) {
        //     payable(msg.sender).transfer(winnerChange);
        //     winnerChange = 0;
        //     return;
        // }
        // if (msg.sender == sellerAddress && !canSellerWithdraw) {
        //     return;
        // }
        // canSellerWithdraw = false;
        // canWinnerWithdraw = false;
        // uint total_amount = winningPrice;
        // if (msg.sender == winnerAddress) {
        //     total_amount = total_amount + winnerChange;
        // }
        // winningPrice = 0;
        // payable(msg.sender).transfer(total_amount);
        if (msg.sender == winnerAddress) {
            if (canWinnerWithdraw) {
                canWinnerWithdraw = false;
                payable(msg.sender).transfer(winningPrice);
            } else if (wagers[winnerAddress] > winningPrice) {
                // Winner put a wager before its current winning price,
                // and should be provided a refund for that.
                uint to_send = wagers[winnerAddress] - winningPrice;
                wagers[winnerAddress] = winningPrice;
                payable(msg.sender).transfer(to_send);
            }
            return;
        }
        if (msg.sender == sellerAddress) {
            if (canSellerWithdraw) {
                canSellerWithdraw = false;
                payable(msg.sender).transfer(winningPrice);
            }
            return;
        }
        uint val = wagers[msg.sender];
        wagers[msg.sender] = 0;
        payable(msg.sender).transfer(val);
    }
}
