// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/utils/math/Math.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract AirDrop is  Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event MemberClaim(address indexed user, uint256 amount);


    address public paymentToken=0x8d1D935B1798ABd9f00d6ED117Ec842afa57C4B7;  

    mapping(address => uint256) public balances;

     function setToken(address _token) external onlyOwner{
        require(_token != address(0),"Zero Address");
        paymentToken = _token;
    }


    function addBalances(address _address, uint _amount ) external onlyOwner {
        balances[_address] += _amount;
    }



    function addBalancesBatch(address[] calldata _addresses, uint[] calldata _amounts )  external onlyOwner  {
        require(_addresses.length == _amounts.length, "_addresses and _amounts should have the same length");
        for (uint i = 0; i < _addresses.length; i++) {
            balances[_addresses[i]] += _amounts[i];
        }
    }


     function setBalances(address _address, uint _amount ) external onlyOwner {
        balances[_address] = _amount;
    }



    function setBalancesBatch(address[] calldata _addresses, uint[] calldata _amounts )  external onlyOwner  {
        require(_addresses.length == _amounts.length, "_addresses and _amounts should have the same length");
        for (uint i = 0; i < _addresses.length; i++) {
            balances[_addresses[i]] = _amounts[i];
        }
    }





    function claim() external {
       
        uint256 amount = balances[msg.sender];
        balances[msg.sender] =0;
        IERC20(paymentToken).safeTransfer(msg.sender,amount);

        emit MemberClaim(msg.sender,amount);
         
    }
    


}