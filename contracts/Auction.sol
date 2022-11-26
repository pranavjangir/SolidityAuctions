// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Timer.sol";

contract Auction {

    address internal judgeAddress;
    address internal timerAddress;
    address internal sellerAddress;
    address internal winnerAddress;
    uint winningPrice;
    uint winnerChange;
    bool canSellerWithdraw;
    bool canWinnerWithdraw;

    // TODO: place your code here

    // constructor
    constructor(address _sellerAddress,
                     address _judgeAddress,
                     address _timerAddress,
                     address _winnerAddress,
                     uint _winningPrice) payable {

        judgeAddress = _judgeAddress;
        timerAddress = _timerAddress;
        sellerAddress = _sellerAddress;
        if (sellerAddress == address(0))
          sellerAddress = msg.sender;
        winnerAddress = _winnerAddress;
        winningPrice = _winningPrice;
        canSellerWithdraw = false;
        canWinnerWithdraw = false;
    }

    // This is provided for testing
    // You should use this instead of block.number directly
    // You should not modify this function.
    function time() public view returns (uint) {
        if (timerAddress != address(0))
          return Timer(timerAddress).getTime();

        return block.number;
    }

    function getWinner() public view virtual returns (address) {
        return winnerAddress;
    }

    function getWinningPrice() public view returns (uint price) {
        return winningPrice;
    }

    // If no judge is specified, anybody can call this.
    // If a judge is specified, then only the judge or winning bidder may call.
    function finalize() public virtual {
        // TODO: place your code here
        if (msg.sender == sellerAddress || 
        (winnerAddress == address(0) && judgeAddress != address(0)
         && msg.sender == judgeAddress)) {
            revert();
        }
        if (judgeAddress != address(0) && winnerAddress != address(0) && 
        !(msg.sender == judgeAddress || msg.sender == winnerAddress)) {
            revert();
        }
        if (winnerAddress == address(0)) {
            winnerAddress = msg.sender;
        }
        if (canSellerWithdraw == false) {
            canSellerWithdraw = true;
        }
    }

    // This can ONLY be called by seller or the judge (if a judge exists).
    // Money should only be refunded to the winner.
    function refund() public {
        if (msg.sender != sellerAddress && msg.sender != judgeAddress) {
            revert();
        }
        if (winnerAddress == address(0)) {
            // No winner yet, so not even judge should be able to call this.
            revert();
        }
        canWinnerWithdraw = true;
    }

    // Withdraw funds from the contract.
    // If called, all funds available to the caller should be refunded.
    // This should be the *only* place the contract ever transfers funds out.
    // Ensure that your withdrawal functionality is not vulnerable to
    // re-entrancy or unchecked-spend vulnerabilities.
    function withdraw() public {
        //TODO: place your code here
        if (winnerAddress == address(0)) {
            revert("No winner yet, cannot withdraw");
        }
        if (msg.sender != winnerAddress && msg.sender != sellerAddress) {
            revert("Unauthorized withdraw");
        }
        if (msg.sender == winnerAddress && !canWinnerWithdraw) {
            payable(msg.sender).transfer(winnerChange);
            winnerChange = 0;
            return;
        }
        if (msg.sender == sellerAddress && !canSellerWithdraw) {
            return;
        }
        canSellerWithdraw = false;
        canWinnerWithdraw = false;
        uint total_amount = winningPrice;
        if (msg.sender == winnerAddress) {
            total_amount = total_amount + winnerChange;
        }
        winningPrice = 0;
        payable(msg.sender).transfer(total_amount);
    }

}
