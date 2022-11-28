// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Auction.sol";

contract VickreyAuction is Auction {

    uint public minimumPrice;
    uint public biddingDeadline;
    uint public revealDeadline;
    uint public bidDepositAmount;
    uint internal maxBid;
    uint internal secondMaxBid;
    mapping(address => bytes32) internal commitments;
    mapping(address => uint) internal withdraw_amt;

    // TODO: place your code here

    // constructor
    constructor(address _sellerAddress,
                            address _judgeAddress,
                            address _timerAddress,
                            uint _minimumPrice,
                            uint _biddingPeriod,
                            uint _revealPeriod,
                            uint _bidDepositAmount)
             Auction (_sellerAddress, _judgeAddress, _timerAddress, address(0), 0) {

        minimumPrice = _minimumPrice;
        bidDepositAmount = _bidDepositAmount;
        biddingDeadline = time() + _biddingPeriod;
        revealDeadline = time() + _biddingPeriod + _revealPeriod;
        maxBid = minimumPrice;
        secondMaxBid = minimumPrice;
        // TODO: place your code here
    }

    // Record the player's bid commitment
    // Make sure exactly bidDepositAmount is provided (for new bids)
    // Bidders can update their previous bid for free if desired.
    // Only allow commitments before biddingDeadline
    function commitBid(bytes32 bidCommitment) public payable {
        require(time() < biddingDeadline);
        if (commitments[msg.sender] == 0) {
            // First time commiter.
            require(msg.value == bidDepositAmount);
            commitments[msg.sender] = bidCommitment;
        } else {
            // The person is updating their commitment.
            require(msg.value == 0);
            commitments[msg.sender] = bidCommitment;
        }
    }

    // Check that the bid (msg.value) matches the commitment.
    // If the bid is correctly opened, the bidder can withdraw their deposit.
    function revealBid(uint nonce) public payable{
        require(time() >= biddingDeadline && time() < revealDeadline);
        bytes32 commitment = keccak256(abi.encodePacked(msg.value, nonce));
        require(commitment == commitments[msg.sender]);
        if (msg.value < secondMaxBid) {
            // Do nothing?
        } else if (msg.value >= secondMaxBid && msg.value < maxBid) {
            secondMaxBid = msg.value;
        } else if (msg.value >= maxBid) {
            secondMaxBid = maxBid;
            maxBid = msg.value;
            winnerAddress = msg.sender;
        }
        // Make sure that the winner address cannot withdraw.
        withdraw_amt[msg.sender] = bidDepositAmount + msg.value;
    }

    // Need to override the default implementation
    function getWinner() public override view returns (address){
        // TODO: place your code here
        if (time() >= revealDeadline) {
            return winnerAddress;
        } else return address(0);
    }

    // finalize() must be extended here to provide a refund to the winner
    // based on the final sale price (the second highest bid, or reserve price).
    function finalize() public override {
        // TODO: place your code here

        if ((winnerAddress == address(0) && judgeAddress != address(0)
         && msg.sender == judgeAddress)) {
            // judge cannot call before there is a winner.
            revert();
        }
        if (judgeAddress != address(0) && winnerAddress != address(0) && 
        !(msg.sender == judgeAddress || msg.sender == winnerAddress)) {
            // only judge and winner can call if there is a winner.
            revert();
        }
        if (winnerAddress == address(0)) {
            winnerAddress = msg.sender;
        }
        if (canSellerWithdraw == false) {
            canSellerWithdraw = true;
        }
        winningPrice = secondMaxBid;
    }

    function withdraw() public override {
        //TODO: place your code here
        require(time() >= revealDeadline);
        if (winnerAddress == address(0)) {
            revert("No winner yet, cannot withdraw");
        }
        if (msg.sender == winnerAddress) {
            if (canWinnerWithdraw) {
                canWinnerWithdraw = false;
                payable(msg.sender).transfer(withdraw_amt[msg.sender]);
            } else if (withdraw_amt[winnerAddress] > winningPrice) {
                // Winner put a wager before its current winning price,
                // and should be provided a refund for that.
                uint to_send = withdraw_amt[winnerAddress] - winningPrice;
                withdraw_amt[winnerAddress] = 0;
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
        uint val = withdraw_amt[msg.sender];
        withdraw_amt[msg.sender] = 0;
        payable(msg.sender).transfer(val);
    }
}
