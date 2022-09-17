//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract AddressExample {

address public myAddress;


function setAddress(address _myAddress) public {

    myAddress = _myAddress;
}

function getBalance() public view returns(uint256) {
  
    return myAddress.balance;
}

}