pragma solidity 0.5.1;

contract MyContract {

    mapping(uint => Person) public people;
    uint public peopleCount = 0;
    address owner;

    struct Person {
        uint _id;
        string _firstName;
        string _lastName;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addPerson(string memory _firstName, string memory _lastName) public onlyOwner {
        incrementCounter();
        people[peopleCount] = Person(peopleCount, _firstName,_lastName);
    }

    function incrementCounter() internal {
        peopleCount += 1;
    }
}