// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Demo {
  
    uint public nounce;

    constructor () {}

    function incNounce() public 
    {
        nounce ++;
    }
    
}
