pragma solidity 0.5.1;

contract NewAuction {

    address public manager;
    address public seller;
    uint public latestBid;
    bool public finished;

    mapping(address => uint) highestBidByUser;



    constructor() public {
        manager = payable(msg.sender);
    }

    function auction () {

    }

    function bid (uint bidAmount) {
        seller = payable(msg.sender);
        latestBid = bidAmount;
    }

    function finishAuction() {
        if (msg.sender != manager) throw;

        finished = true;

        seller.transfer()
    }
}