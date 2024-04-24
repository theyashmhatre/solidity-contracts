pragma solidity ^0.5.1;

library Math {
    function divide(uint a, uint b) internal pure returns(uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }
}