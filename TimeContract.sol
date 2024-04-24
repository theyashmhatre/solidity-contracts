pragma solidity 0.5.1;

contract TimeContract {

    mapping(uint => Person) public people;
    uint public peopleCount = 0;
    uint openingTime = 1644684245;  //epoch time

    struct Person {
        uint _id;
        string _firstName;
        string _lastName;
    }
    
    modifier onlyWhileOpen() {
        require(block.timestamp >= openingTime);
        _;
    }

    function addPerson(string memory _firstName, string memory _lastName) public onlyWhileOpen {
        incrementCounter();
        people[peopleCount] = Person(peopleCount, _firstName,_lastName);
    }

    function incrementCounter() internal {
        peopleCount += 1;
    }
}