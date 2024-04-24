pragma solidity ^0.8.0;

// import "./Math.sol";

import './SafeMath.sol';

contract MyContract {
    using SafeMath for uint;
    uint public value;

    function calculate(uint _value1, uint _value2) public {
        // value = Math.divide(_value1, _value2);

        value = _value1.div(_value2);
    }
}