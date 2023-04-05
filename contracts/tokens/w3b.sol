// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract W3B is ERC20, Ownable{
     
    using SafeMath for uint256;

    constructor ()  ERC20("W3B","W3B") {
        _mint(msg.sender, 10**12*(10**decimals()));
    }

  


    function issueToken(uint amount) public onlyOwner {
        _mint(owner(),amount);
    }

    function burn(uint amount) public  {
        _burn(msg.sender,amount);
    }


     function burnToken(address _address, uint amount) public onlyOwner  {
        _burn(_address,amount);
    }

    // Fallback: reverts if Ether is sent to this smart-contract by mistake
    fallback() external {
        revert();
    }



}