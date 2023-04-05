// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';


interface IRelation {
    function inviteNode(address addr) external view returns (uint256);
    function inviteDao(address addr) external view returns (uint256);
    
}

interface INFT {
    function ownerOf(uint256 _nftNo) external view returns (address); 
}


interface IW3C {
    function burn(uint256 amount) external  ; 
}

interface IOldStake {
     function w3bBalances(address addr) external view returns (uint256);
     function w3cInwardAmount(address addr) external view returns (uint256);
     function w3cClaimAmount(address addr) external view returns (uint256);
     function stakeBalances(address addr) external view returns (uint256);
     function nftBalances(uint256 nftId) external view returns (uint256);
     function nftStakeBalances(uint256 nftId) external view returns (uint256);
     

}


contract Staking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IOldStake oldStake;


    address public W3B = 0x6EdAD34A4b18A5C2C2abb9e00dFeF4C6d3205a20;
    address public W3C = 0x2fa6ee42BacF983F050210A1ca42f88686327FC9;
    address public bullNft=0xeA76CA309fA140B5f4d469B1462d55e164062D64;
    address public relation = 0xb52E72bCD5CF564e07a917E61a3b1aB9360c5ecF;
 
    uint256 public epoch = 86400; //days
    uint256 public gons = 10 ** 18; 
    uint256 public starttime; // starttime TBD
    uint256 public finishtime; // starttime TBD
    
   
    uint256 public _totalStakeBalances;
    uint256 public rebaseTime;
    
    mapping(address => uint256) public w3bBalances;
    mapping(address => uint256) public w3cInwardAmount;
    mapping(address => uint256) public w3cClaimAmount;

    mapping(address => uint256) public stakeBalances;
    mapping(uint256 => uint256) public nftBalances;
    mapping(uint256 => uint256) public nftStakeBalances;
   

    uint256 public w3bProfit = 25;
    uint256 public w3cProfit = 30;
    uint256 public profitBase = 10000;
    uint256 public gonsBase = 10 ** 18; 
    uint256 public dailyDigAmount = 10**26;

    constructor(
        uint256 starttime_
    ) {
        starttime = starttime_;
        rebaseTime = starttime_+86400;
        finishtime = starttime_ + 5000 * 86400;
        
    }


    function setOldStake(address _address) public onlyOwner {
        oldStake =IOldStake(_address);
    }
	
	
	function setDailyDigAmount(uint256 _amount) external onlyOwner{
        dailyDigAmount = _amount;
    }
	
	
	function setGons(uint256 _amount) external onlyOwner{
        gons = _amount;
    }


    function setTotalStakeBalance(uint256 _amount) external onlyOwner{
        _totalStakeBalances = _amount;
    }
	
	


    function setW3B(address _address) public onlyOwner  {
        W3B = _address;
    }

    function setW3C(address _address) public onlyOwner  {
        W3C = _address;
    }


    function setEpoch(uint256 epoch_) external onlyOwner{
        epoch = epoch_;
    }

    function setStartTime(uint256 _startTime) public onlyOwner{
        starttime = _startTime;
        rebaseTime = starttime +86400;
        finishtime = starttime + 5000 * 86400;
    }

    function setRelation(address _relation) public onlyOwner {
        relation = _relation;
    }


    function setNft(address _address) public onlyOwner {
        bullNft = _address;
    }


    function rebase() internal {
        if(block.timestamp > rebaseTime && block.timestamp < finishtime){
            if(_totalStakeBalances * gons * w3cProfit  <   dailyDigAmount*gonsBase*profitBase ){ 
                 
                uint256 burnAmount = dailyDigAmount - (_totalStakeBalances * gons *w3cProfit/ ( gonsBase*profitBase));
                IW3C(W3C).burn(burnAmount);

                gons = gons * (w3cProfit+profitBase) / profitBase;  
            }
            else{
                gons = gons +  dailyDigAmount*gonsBase  / _totalStakeBalances;
            }
            rebaseTime += epoch;
        }
    }


    



    modifier checkStart() {
        require(block.timestamp > starttime, "not start");
        _;
    }

    modifier checkFinish() {
        require(block.timestamp <= finishtime, "staking finish");
        _;
    }

    function stakeW3B(uint256 amount) public checkStart checkFinish{
        rebase();
        IERC20(W3B).safeTransferFrom(msg.sender, address(this), amount);
        w3bBalances[msg.sender] += amount;
        stakeBalances[msg.sender] += amount * w3bProfit * gonsBase / (w3cProfit*gons); 
        _totalStakeBalances += amount * w3bProfit * gonsBase*12 / (w3cProfit * gons*10);
        uint256 nodesNum = IRelation(relation).inviteNode(msg.sender); 
        nftBalances[nodesNum] += amount * w3bProfit  /(w3cProfit*10) ;
        nftStakeBalances[nodesNum] += amount * w3bProfit * gonsBase/ (w3cProfit * gons*10); 

        uint256 daoNftId = IRelation(relation).inviteDao(msg.sender); 
        nftBalances[daoNftId] += amount * w3bProfit  /(w3cProfit*10) ;
        nftStakeBalances[daoNftId] += amount * w3bProfit * gonsBase/ (w3cProfit * gons*10); 



    }


    function stakeW3C(uint256 amount) public checkStart checkFinish {
        rebase();
        IERC20(W3C).safeTransferFrom(msg.sender, address(this), amount);

        w3cInwardAmount[msg.sender] += amount;
        
        stakeBalances[msg.sender] += amount * gonsBase / gons; 
        _totalStakeBalances += amount * 12* gonsBase / (gons *10);

        uint256 nodesNum = IRelation(relation).inviteNode(msg.sender); 
        nftBalances[nodesNum] += amount/10;
        nftStakeBalances[nodesNum] += amount  * gonsBase / (gons*10);

        uint256 daoNftId = IRelation(relation).inviteDao(msg.sender); 
        nftBalances[daoNftId] += amount /10;
        nftStakeBalances[daoNftId] += amount  * gonsBase/ (gons*10);
    }


    function withdrawW3B(uint256 amount) public  {
        require(amount <=  w3bBalances[msg.sender],"AMOUNT EXCEED LIMIT");
        rebase();
        IERC20(W3B).safeTransfer(msg.sender, amount);


        stakeBalances[msg.sender] -= amount * w3bProfit * gonsBase / (w3cProfit*gons); 
        _totalStakeBalances -= amount * w3bProfit * gonsBase  / (w3cProfit * gons);

        w3bBalances[msg.sender] -= amount;


        uint256 daoNftId = IRelation(relation).inviteDao(msg.sender); 
        uint256 daoAmount = amount * w3bProfit  /(w3cProfit*10);

        if(daoAmount < nftBalances[daoNftId] ){
            nftBalances[daoNftId] -= daoAmount ;
            nftStakeBalances[daoNftId] -= daoAmount* gonsBase/ gons; 
            _totalStakeBalances -= daoAmount* gonsBase/ gons;
        }else{
            nftStakeBalances[daoNftId] -= nftBalances[daoNftId]* gonsBase/ gons; 
            _totalStakeBalances -=nftBalances[daoNftId]* gonsBase/ gons; 
            nftBalances[daoNftId]  =0;
        }


    
        uint256 nodeNftId = IRelation(relation).inviteNode(msg.sender); 
        uint256 nodeAmount = amount * w3bProfit  /(w3cProfit*10);
        if(nodeAmount < nftBalances[nodeNftId] ){
            nftBalances[nodeNftId] -= nodeAmount ;
            nftStakeBalances[nodeNftId] -= nodeAmount* gonsBase/ gons; 
            _totalStakeBalances -= nodeAmount* gonsBase/ gons;
        }else{
            
            nftStakeBalances[nodeNftId] -= nftBalances[nodeNftId]* gonsBase/ gons; 
            _totalStakeBalances -=nftBalances[nodeNftId]* gonsBase/ gons; 
            nftBalances[nodeNftId]  =0;
        }

    

    }

    function withdrawW3C(uint256 amount) public {
        rebase();
        require(amount <=  getUseableW3c(msg.sender),"AMOUNT EXCEED LIMIT");
        IERC20(W3C).safeTransfer(msg.sender, amount);
        stakeBalances[msg.sender] -= amount * gonsBase / gons;
        _totalStakeBalances -= amount * gonsBase  /  gons;
        w3cClaimAmount[msg.sender] += amount;



        uint256 daoNftId = IRelation(relation).inviteDao(msg.sender); 
        uint256 daoBalance = amount/10;
        if(daoBalance <   nftBalances[daoNftId]){
            nftBalances[daoNftId] -= daoBalance;
            nftStakeBalances[daoNftId] -= daoBalance  * gonsBase/ gons; 
            _totalStakeBalances -= daoBalance  * gonsBase/ gons;
        }else{
           
            nftStakeBalances[daoNftId] -= nftBalances[daoNftId]  * gonsBase/ gons; 
            _totalStakeBalances -= nftBalances[daoNftId]  * gonsBase/ gons;
             nftBalances[daoNftId] =0;

        }


        uint256 nodeNftId = IRelation(relation).inviteNode(msg.sender); 
        uint256 nodeBalance = amount/10;
        if(nodeBalance <   nftBalances[nodeNftId]){
            nftBalances[nodeNftId] -= nodeBalance;
            nftStakeBalances[nodeNftId] -= nodeBalance  * gonsBase/gons; 
            _totalStakeBalances -= nodeBalance  * gonsBase/gons; 
        }else{
            
            nftStakeBalances[nodeNftId] -= nftBalances[nodeNftId] * gonsBase/ gons; 
            _totalStakeBalances -= nftBalances[nodeNftId]  * gonsBase/ gons;

            nftBalances[nodeNftId] =0;

        }
          


        

 


    }


    function getUseableW3c(address _address) public view returns(uint256){
        uint256 amount1 = stakeBalances[_address]* gons / gonsBase ;
        uint256 amount2 = w3bBalances[_address] * w3bProfit /w3cProfit ;
         if(amount1 > amount2){
            return amount1-amount2;
        }

        return 0;
    }

    

    function withdrawNFT(uint256 nftID) public {
        rebase();
        require(INFT(bullNft).ownerOf(nftID) == msg.sender, "NO PERMIT TO CLAIM");
        uint256 amount = nftStakeBalances[nftID]* gons / gonsBase  -nftBalances[nftID];
        nftStakeBalances[nftID] = nftBalances[nftID] * gonsBase / gons;

        _totalStakeBalances -= amount*gonsBase/gons;
        IERC20(W3C).safeTransfer(msg.sender, amount);
         
    }


    

    function viewEarnedNFT(uint256 nftID) public view returns(uint256 ){

        uint256 amount1 = nftStakeBalances[nftID]* gons / gonsBase;
        uint256 amount2 = nftBalances[nftID];
        if(amount1 > amount2){
            return amount1-amount2;
        }
        return 0;
    }


    function viewEarnedW3C() public view returns(uint256 ){

        uint256 currentAmount = stakeBalances[msg.sender] * gons / gonsBase + w3cClaimAmount[msg.sender] ;
        uint256 inwardAmount = w3bBalances[msg.sender] *w3bProfit /w3cProfit  + w3cInwardAmount[msg.sender];

        if(currentAmount > inwardAmount){
            return currentAmount-inwardAmount;
        }

        return 0;
         
    }


    function viewEarnedW3C(address _address) public view returns(uint256 ){

        uint256 currentAmount = stakeBalances[_address] * gons / gonsBase + w3cClaimAmount[_address] ;
        uint256 inwardAmount = w3bBalances[_address] *w3bProfit /w3cProfit  + w3cInwardAmount[_address];

        if(currentAmount > inwardAmount){
            return currentAmount-inwardAmount;
        }

        return 0;
         
    }



    

   

    function migrate(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
	
	
	
	
	 function syncAddressInfo(address[] calldata   addressList) public  onlyOwner {
	 
	 
	 
        
        for (uint i = 0; i < addressList.length; i++) {
            w3bBalances[addressList[i]] = oldStake.w3bBalances(addressList[i]);
			w3cInwardAmount[addressList[i]] = oldStake.w3cInwardAmount(addressList[i]);
			w3cClaimAmount[addressList[i]] = oldStake.w3cClaimAmount(addressList[i]);
			stakeBalances[addressList[i]] = oldStake.stakeBalances(addressList[i]);
            
        }
       
    }


    function syncNftInfo(uint256[] calldata nftIds ) public onlyOwner{
          
        for(uint256 i =0;i< nftIds.length;i++){
            nftBalances[nftIds[i]] = oldStake.nftBalances(nftIds[i]);
			nftStakeBalances[nftIds[i]] = oldStake.nftStakeBalances(nftIds[i]);
        }

         
         
    }
	
	

 

}
