// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/utils/math/Math.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
 

interface IW3C {
    function burn(uint256 amount) external  ; 
}


contract WRAP is  Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public W3B = 0x6EdAD34A4b18A5C2C2abb9e00dFeF4C6d3205a20;
    address public W3C = 0x2fa6ee42BacF983F050210A1ca42f88686327FC9;
    uint256 public vaultFee = 100;
    uint256 public lpFee = 50;
    uint256 public burnFee = 25;
    uint256 public opFee = 25;

     
    address public operationAddress =   0x4B922a7A14e27e933CAd0974c089aeb8a932Ea1a;   // yun ying
    address public vaultAddress =       0xd856D338DD558b40EE879D2EA9855cf0549fA6b6;       //guoku
    address public lpAddress =       0x3a5631CC14B298C9ff0B1253004505e27D8759BC;            //shi zhi
   

    constructor()
    {
 
    }


     function setOperationAddress(address _address) public onlyOwner  {
        operationAddress = _address;
    }

    function setVaultAddress(address _address) public onlyOwner  {
        vaultAddress = _address;
    }


    function setW3B(address _address) public onlyOwner  {
        W3B = _address;
    }

    function setW3C(address _address) public onlyOwner  {
        W3C = _address;
    }

     


     
    function setLpAddress(address _address) public onlyOwner  {
        lpAddress = _address;
    }

    

    

    function warp(uint256 amount)         
        public
        returns (bool) 
    {
        IERC20(W3B).transferFrom(msg.sender, address(this), amount);
        uint256 vaultAmount = amount * vaultFee / 1000;
        uint256 lpAmount = amount * lpFee / 1000;
        uint256 opAmount = amount * opFee / 1000;
        uint256 burnAmount = amount * burnFee / 1000;
       
        IERC20(W3C).transfer(vaultAddress,vaultAmount); //todo
        
        IERC20(W3C).transfer(lpAddress,lpAmount);
        IERC20(W3C).transfer(operationAddress,opAmount); 
        IERC20(W3C).transfer(msg.sender,amount * 80 /100);
        IW3C(W3C).burn(burnAmount);
       
        return true;
    }

    

     function withdraw(address _token,uint256 amount) public onlyOwner {
        IERC20(_token).safeTransfer(owner(), amount);
    }


     // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback() external {
        revert();
    }

    
}
