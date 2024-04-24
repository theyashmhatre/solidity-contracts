pragma solidity ^0.5.16;

contract LendingSystem {
    address payable private owner;

    mapping(address => uint) public loans;

    uint256 public totalLent;

    constructor() public {
        owner = msg.sender;
    }

    function loan(address payable borrower, uint256 amount) public payable {
        require(msg.sender == owner && amount > 0, "Invalid operation");

        loans[borrower] += amount;
        totalLent += amount;

        borrower.send(amount);
    }

    function repay(address borrower, uint256 amount) public payable {
        require(loans[borrower] >= amount, "Insufficient loan amount");

        loans[borrower] -= amount;
        totalLent -= amount;

        owner.send(amount);

    }

    function getLoan(address borrower) public view returns (uint256) {
        return loans[borrower];
    }

    function getTotalLent() public view returns (uint256) {
        return totalLent;
    }

    function tranferOwnership(address payable newOwner) public {
        require(msg.sender == owner, "Should be owner!");

        owner = newOwner;
    }

}